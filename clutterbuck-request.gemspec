require 'git-version-bump' rescue nil

Gem::Specification.new do |s|
	s.name = "clutterbuck-request"

	s.version = GVB.version rescue "0.0.0.1.NOGVB"
	s.date    = GVB.date    rescue Time.now.strftime("%Y-%m-%d")

	s.platform = Gem::Platform::RUBY

	s.summary  = "Provide per-request helpers to Clutterbuck apps"

	s.authors  = ["Matt Palmer"]
	s.email    = ["theshed+clutterbuck@hezmatt.org"]
	s.homepage = "http://theshed.hezmatt.org/clutterbuck"

	s.files = `git ls-files -z`.split("\0").reject { |f| f =~ /^(G|spec|Rakefile)/ }

	s.required_ruby_version = ">= 1.9.3"

	s.add_runtime_dependency "clutterbuck-core", "~> 0.0"
	s.add_runtime_dependency "oj", "~> 2.0"
	s.add_runtime_dependency "rack", "~> 2.0"

	s.add_development_dependency 'bundler'
	s.add_development_dependency 'github-release'
	s.add_development_dependency 'git-version-bump'
	s.add_development_dependency 'guard-spork'
	s.add_development_dependency 'guard-rspec'
	s.add_development_dependency 'rake', '~> 10.4', '>= 10.4.2'
	# Needed for guard
	s.add_development_dependency 'rb-inotify', '~> 0.9'
	s.add_development_dependency 'redcarpet'
	s.add_development_dependency 'rspec'
	s.add_development_dependency 'yard'
end