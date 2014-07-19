# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rawchat/version'

Gem::Specification.new do |spec|
  spec.name          = "rawchat"
  spec.version       = Rawchat::VERSION
  spec.authors       = ["dramforever"]
  spec.email         = ["dramforever@live.com"]
  spec.summary       = %q{Rawchat is just chat}
  spec.description   = <<END
Rawchat is a chatting system that supports auth, private message and channels.

It has a generic backend that just provides ruby methods to operate the server and
has a TCP backend and a WebSocket backend.
END
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.3.2"
  spec.add_development_dependency "pry", "~> 0.10.0"
  spec.add_development_dependency "pry-remote", "~> 0.1.8"

  spec.add_dependency "yajl-ruby", "~> 1.2.1"
  spec.add_dependency "eventmachine", "~> 1.0.3"
end
