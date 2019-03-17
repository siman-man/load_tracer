lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'load_tracer/version'

Gem::Specification.new do |spec|
  spec.name = 'load_tracer'
  spec.version = LoadTracer::VERSION
  spec.authors = ['Shuichi Tamayose']
  spec.email = ['tmshuichi@gmail.com']

  spec.summary = %q{This gem can check the dependency files.}
  spec.description = %q{This gem can check the dependency files.}
  spec.homepage = 'https://github.com/siman-man/load_tracer'
  spec.license = 'MIT'
  spec.required_ruby_version = '> 2.6.99'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'binding_of_caller', '~> 0.8.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 12.3.2'
  spec.add_development_dependency 'rspec', '~> 3.8.0'
end
