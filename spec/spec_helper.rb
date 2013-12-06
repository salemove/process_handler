require 'rspec'
require 'salemove/process_handler'

include Salemove

RSpec.configure do
  def fixture_path(name)
    File.join(File.dirname(__FILE__), "fixtures", name)
  end
end
