require 'clutterbuck-core'
require 'oj'
require 'rack'
require 'rack/utils'
require 'rack/request'
require 'uri'

module Clutterbuck; end

module Clutterbuck::Request
	# Give an instance of `Rack::Request` generated from the environment
	# of this request.
	#
	# @return [Rack::Request]
	#
	def request
		@request ||= Rack::Request.new(env)
	end

	# Generate an absolute URL for the path given, relative to the root of
	# this application.
	#
	# @param path [String] the path to append to the base URL of the app.
	#
	# @return [String]
	#
	def url(path)
		base_url.tap do |url|
			url.path = url.path[0..-2] if url.path[-1] == "/"
			url.path += (path[0] == "/" ? "" : "/") + path
		end.to_s
	end

	# Return the base URL of the app.
	#
	# @return [URI]
	#
	def base_url
		URI("#{request.scheme}:/").tap do |uri|
			uri.host   = request.host
			uri.path   = request.script_name

			if uri.default_port != request.port
				uri.port = request.port
			end
		end
	end

	# Return the query parameters for this request.
	#
	# @note The query parameters are *only* those specified in the query
	#   string part of the URL; they explicitly do *not* include any data
	#   sent in the request body.  The contents of the request body are
	#   available separately, via the {#body} method.
	#
	# @note This method parses the variable names as a "flat" namespace.  As an
	#   example, if the query string included `foo[bar]=baz`, then this method
	#   will return a hash of `{"foo[bar]" => "baz"}`.  If you want the
	#   query parameters to be "nested", you want {#nested_query_params}.
	#
	# @return [Hash<String, String>]
	#
	def query_params
		@query_params ||= begin
			Rack::Utils.parse_query(request.query_string)
		end
	end

	alias_method :qp, :query_params

	# Return the query parameters for this request as a nested hash.
	#
	# This is useful in those situations where you want to get a bit "structured"
	# with your query parameters.  When a query parameter name contains square
	# brackets (`[` and `]`), things get a bit tricky.
	#
	# If there is something inside the square brackets (such as `[blah]`),
	# then a hash will be created as the value of the part of the name before
	# the brackets, and the contents of the square brackets will become the
	# "key" in that new sub-hash, and the value of the query parameter will
	# be the value in that subhash.
	#
	# If the square brackets are empty (ie `[]`), then an *array* will be
	# created as the value of the part of the name before the brackets, and
	# the value of the query parameter will be appended to the array.
	#
	# All this is recursive too; this can end up with you getting very
	# complicated nested data structures for your query params, which is
	# rarely good thing, from a security perspective.  But if you want to
	# shoot yourself in the foot, it's here for you.
	#
	# @note The query parameters are *only* those specified in the query
	#   string part of the URL; they explicitly do *not* include any data
	#   sent in the request body.  The contents of the request body are
	#   available separately, via the {#body} method.
	#
	# @note If you want the query parameters to be "flat", without any hashes
	#   as values for the top-level elements, you want {#query_params}.
	#
	# @return [Hash{String => String, Hash}]
	#
	def nested_query_params
		@nested_query_params ||= begin
			Rack::Utils.parse_nested_query(request.query_string)
		end
	end

	alias_method :nqp, :nested_query_params

	# Parse and return the data sent in the body of the request.
	#
	# This method is the "catch-all" means of accessing the request body.
	# Since request bodies can come in all sorts of different flavours,
	# there are several different "modes" of accessing the body.  These
	# vary the content types that will be accepted, as well as the type
	# that is returned.
	#
	# @param mode [Symbol] select what sort of body you're expecting.
	#   Valid values are:
	#
	#   * `:hash` -- return some sort of hash containing request parameters.
	#     JSON documents containing an object at the top level, as well as
	#     HTML form submissions, are accepted in this mode.
	#
	#   * `:json` -- Enforce that the request body must be JSON.  Any valid
	#     JSON document will be returned, parsed into Ruby-native types -- so
	#     you could, in theory, end up with any of a `Hash`, `Array`,
	#     `Integer`, `Float`, `true`, `false`, or `nil` (yep,
	#     [RFC7159](http://tools.ietf.org/html/rfc7159) lets any of those
	#     things be a top-level document).
	#
	#   * `:raw` -- The entire request body will be returned as one giant
	#     string.  You're on your own when it comes to parsing the thing.
	#
	# @return [Object] depending on the mode, lots of different things can
	#   come back.
	#
	# @raise [Clutterbuck::BadRequestError] something bad happened:
	#
	#   * For `mode == :hash`, Parsing failed.
	#
	#   * For `mode == :json`, no request body was given, or the JSON parser
	#     failed.
	#
	#   * For `mode == :raw`, No body was provided.
	#
	# @raise [Clutterbuck::UnsupportedMediaTypeError] if `mode == :json` and
	#   something other than JSON was provided, or if `mode == :hash` and a
	#   content type we don't know how to turn into a hash was provided.
	#
	def body(mode=:hash)
		case mode
		when :hash
			hash_body
		when :json
			json_body
		when :raw
			raw_body
		else
			raise ArgumentError,
			      "Unknown body mode: #{mode.inspect}"
		end
	end

	private

	def hash_body
		@hash_body ||= begin
			if request.media_type == "application/json"
				unless json_body.is_a?(Hash)
					raise Clutterbuck::BadRequestError,
					      "Expected a JSON document"
				end
				json_body
			elsif request.form_data?
				if request.media_type == "multipart/form-data"
					Rack::Multipart.parse_multipart(env)
				else
					Rack::Utils.parse_nested_query(request_body)
				end
			else
				raise Clutterbuck::UnsupportedMediaTypeError,
				      request.media_type
			end
		end
	end

	def json_body
		@json_body ||= begin
			if request.media_type != "application/json"
				raise Clutterbuck::UnsupportedMediaTypeError,
				      request.media_type
			end

			begin
				Oj.load(request_body)
			rescue Oj::ParseError => e
				raise Clutterbuck::BadRequestError,
						"Could not parse request body: #{e.message}"
			end
		end
	end

	def raw_body
		if request_body.nil? or request_body.empty?
			raise Clutterbuck::BadRequestError,
			      "Empty request body"
		end
		
		request_body
	end

	def request_body
		if request.body
			@request_body ||= begin
				request.body.read
			ensure
				request.body.rewind
			end
		end
	end
end
