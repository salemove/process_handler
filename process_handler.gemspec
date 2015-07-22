# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'salemove/process_handler/version'

Gem::Specification.new do |spec|
  spec.name          = 'process_handler'
  spec.version       = Salemove::ProcessHandler::VERSION
  spec.authors       = ['Indrek Juhkam']
  spec.email         = ['indrek@salemove.com']
  spec.description   = %q{This gem helps to monitor and manage processes}
  spec.summary       = %q{}
  spec.homepage      = ''
  spec.license       = 'Private'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'airbrake'
  spec.add_dependency 'sucker_punch', '~> 1.1' # for async airbrake notifications
  spec.add_dependency 'growl'
end
