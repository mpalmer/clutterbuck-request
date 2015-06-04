require_relative './spec_helper'
require 'clutterbuck-request'

class ExampleApp
	include Clutterbuck::Request

	def initialize(env)
		@env = env
	end

	attr_reader :env
end

describe Clutterbuck::Request do
	let(:app) { ExampleApp.new(env) }
	
	context "#url" do
		context "with basic HTTP env" do
			let(:env) do
				{
					"rack.url_scheme" => "http",
					"SERVER_NAME"     => "example.com",
					"SERVER_PORT"     => "80",
					"SCRIPT_NAME"     => "/something"
				}
			end
			
			it "returns the right URL" do
				expect(app.url("/funny")).to eq("http://example.com/something/funny")
			end
		end

		context "with basic HTTP env, relative path" do
			let(:env) do
				{
					"rack.url_scheme" => "http",
					"SERVER_NAME"     => "example.com",
					"SERVER_PORT"     => "80",
					"SCRIPT_NAME"     => "/something"
				}
			end
			
			it "returns the right URL" do
				expect(app.url("funny")).to eq("http://example.com/something/funny")
			end
		end

		context "with basic HTTP env, non-standard port" do
			let(:env) do
				{
					"rack.url_scheme" => "http",
					"SERVER_NAME"     => "example.com",
					"SERVER_PORT"     => "42",
					"SCRIPT_NAME"     => "/something"
				}
			end
			
			it "returns the right URL" do
				expect(app.url("/funny")).to eq("http://example.com:42/something/funny")
			end
		end

		context "with basic HTTP env, trailing-slash SCRIPT_NAME" do
			let(:env) do
				{
					"rack.url_scheme" => "http",
					"SERVER_NAME"     => "example.com",
					"SERVER_PORT"     => "80",
					"SCRIPT_NAME"     => "/something/"
				}
			end
			
			it "returns the right URL" do
				expect(app.url("/funny")).to eq("http://example.com/something/funny")
			end
		end

		context "with basic HTTPS env" do
			let(:env) do
				{
					"rack.url_scheme" => "https",
					"SERVER_NAME"     => "example.com",
					"SERVER_PORT"     => "443",
					"SCRIPT_NAME"     => "/something"
				}
			end
			
			it "returns the right URL" do
				expect(app.url("/funny")).to eq("https://example.com/something/funny")
			end
		end
	end

	context "#query_params" do
		let(:query_params) { app.query_params }

		context "basic query string" do
			let(:env) { { "QUERY_STRING" => "foo=bar&baz=wombat" } }
			
			it "has the right number of elements" do
				expect(query_params.length).to eq(2)
			end
			
			it "has the right value for foo" do
				expect(query_params["foo"]).to eq("bar")
			end
			
			it "has the right value for baz" do
				expect(query_params["baz"]).to eq("wombat")
			end
		end

		context "nested query string" do
			let(:env) { { "QUERY_STRING" => "foo[bar]=baz" } }
			
			it "has the right number of elements" do
				expect(query_params.length).to eq(1)
			end
			
			it "has the right value for foo[bar]" do
				expect(query_params["foo[bar]"]).to eq("baz")
			end
		end

		context "array query string" do
			let(:env) { { "QUERY_STRING" => "foo[]=baz" } }
			
			it "has the right number of elements" do
				expect(query_params.length).to eq(1)
			end
			
			it "has the right value for foo[]" do
				expect(query_params["foo[]"]).to eq("baz")
			end
		end
	end

	context "#nested_query_params" do
		let(:query_params) { app.nested_query_params }

		context "basic query string" do
			let(:env) { { "QUERY_STRING" => "foo=bar&baz=wombat" } }
			
			it "has the right number of elements" do
				expect(query_params.length).to eq(2)
			end
			
			it "has the right value for foo" do
				expect(query_params["foo"]).to eq("bar")
			end
			
			it "has the right value for baz" do
				expect(query_params["baz"]).to eq("wombat")
			end
		end

		context "nested query string" do
			let(:env) { { "QUERY_STRING" => "foo[bar]=baz" } }
			
			it "has the right number of elements" do
				expect(query_params.length).to eq(1)
			end
			
			it "has the right value for foo" do
				expect(query_params["foo"]).to eq("bar" => "baz")
			end
		end

		context "array query string" do
			let(:env) { { "QUERY_STRING" => "foo[]=baz" } }
			
			it "has the right number of elements" do
				expect(query_params.length).to eq(1)
			end
			
			it "has the right value for foo[]" do
				expect(query_params["foo"]).to eq(["baz"])
			end
		end
	end

	context "#body" do
		context "with valid JSON hash request body" do
			let(:env) do
				{
				  "CONTENT_TYPE" => "application/json",
				  "rack.input"   => StringIO.new(%({"foo":"bar","baz":42}))
				}
			end
			
			it "goes OK through :hash mode" do
				expect(app.body(:hash)).to eq("foo" => "bar", "baz" => 42)
			end

			it "goes OK through :json mode" do
				expect(app.body(:json)).to eq("foo" => "bar", "baz" => 42)
			end

			it "goes OK through :raw mode" do
				expect(app.body(:raw)).to eq(%({"foo":"bar","baz":42}))
			end
		end

		context "with invalid JSON request body" do
			let(:env) do
				{
				  "CONTENT_TYPE" => "application/json",
				  "rack.input"   => StringIO.new(%("foo":"bar","baz":42))
				}
			end
			
			it "barfs in :hash mode" do
				expect { app.body(:hash) }.to raise_error(Clutterbuck::BadRequestError)
			end

			it "barfs in :json mode" do
				expect { app.body(:json) }.to raise_error(Clutterbuck::BadRequestError)
			end

			it "goes OK through :raw mode" do
				expect(app.body(:raw)).to eq(%("foo":"bar","baz":42))
			end
		end

		context "with valid JSON array request body" do
			let(:env) do
				{
				  "CONTENT_TYPE" => "application/json",
				  "rack.input"   => StringIO.new(%(["foo","bar","baz",42]))
				}
			end
			
			it "errors out in :hash mode" do
				expect { app.body(:hash) }.
				  to raise_error(Clutterbuck::BadRequestError)
			end

			it "goes OK through :json mode" do
				expect(app.body(:json)).to eq(["foo", "bar", "baz", 42])
			end

			it "goes OK through :raw mode" do
				expect(app.body(:raw)).to eq(%(["foo","bar","baz",42]))
			end
		end

		context "with valid JSON null request body" do
			let(:env) do
				{
				  "CONTENT_TYPE" => "application/json",
				  "rack.input"   => StringIO.new("null")
				}
			end
			
			it "errors out in :hash mode" do
				expect { app.body(:hash) }.
				  to raise_error(Clutterbuck::BadRequestError)
			end

			it "goes OK through :json mode" do
				expect(app.body(:json)).to eq(nil)
			end

			it "goes OK through :raw mode" do
				expect(app.body(:raw)).to eq("null")
			end
		end

		context "with valid x-www-form-urlencoded request body" do
			let(:env) do
				{
				  "CONTENT_TYPE" => "application/x-www-form-urlencoded",
				  "rack.input"   => StringIO.new("foo[bar]=baz&wombat=42")
				}
			end
			
			it "goes OK through :hash mode" do
				expect(app.body(:hash)).
				  to eq("foo" => { "bar" => "baz" }, "wombat" => "42")
			end

			it "errors out in :json mode" do
				expect { app.body(:json) }.
				  to raise_error(Clutterbuck::UnsupportedMediaTypeError)
			end

			it "goes OK through :raw mode" do
				expect(app.body(:raw)).to eq("foo[bar]=baz&wombat=42")
			end
		end

		context "with Content-Typeless request body" do
			let(:env) do
				{
				  "REQUEST_METHOD" => "POST",
				  "rack.input"     => StringIO.new("foo[bar]=baz&wombat=42")
				}
			end
			
			it "goes OK through :hash mode" do
				expect(app.body(:hash)).
				  to eq("foo" => { "bar" => "baz" }, "wombat" => "42")
			end

			it "errors out in :json mode" do
				expect { app.body(:json) }.
				  to raise_error(Clutterbuck::UnsupportedMediaTypeError)
			end

			it "goes OK through :raw mode" do
				expect(app.body(:raw)).to eq("foo[bar]=baz&wombat=42")
			end
		end

		context "with image request body" do
			let(:env) do
				{
				  "CONTENT_TYPE" => "image/png",
				  "rack.input"   => StringIO.new("PNGPNGPNGPNG")
				}
			end
			
			it "errors out in :hash mode" do
				expect { app.body(:hash) }.
				  to raise_error(Clutterbuck::UnsupportedMediaTypeError)
			end

			it "errors out in :json mode" do
				expect { app.body(:json) }.
				  to raise_error(Clutterbuck::UnsupportedMediaTypeError)
			end

			it "goes OK through :raw mode" do
				expect(app.body(:raw)).to eq("PNGPNGPNGPNG")
			end
		end
	end
end
