require 'spec_helper'
require 'airbrake'
require 'airbrake/notice'
require 'salemove/process_handler/notifier_factory'

describe 'Airbrake configuration' do

  let (:notice) { Airbrake::Notice.new(notice_args.merge(custom_notice_args)) }
  let (:notifier_factory_conf) { {:type => 'airbrake',:host => 'localhost',:api_key => 'abc123'} }
  let (:airbrake) { ProcessHandler::NotifierFactory.get_notifier('env', 'Process name', notifier_factory_conf) }
  # Notice needs Airbrake configuration merged with :exception for creating the exception notification
  let (:notice_args) { {:exception => Exception.new}.merge(airbrake.configuration) }
  let (:filtered) { '[FILTERED]' }

  # Uses Airbrake configuration's 'params_whitelist_filters' param for filtering
  context 'whitelist filter' do

    let (:custom_notice_args) {
      {
        :params_filters => [], # Remove blacklist to test whitelist
        :parameters => {
          'API_PORT_80_TCP_PROTO' => 'tcp',
          'HOME' => '/home/sm',
          'SECRET_PASS' => 'Parool123',
          'SOME_PROTO_KEY' => 'value',
          'PROTO_KEY' => 'abc123'
        },
        :cgi_data => {
          'HTTP_HOST' => 'localhost:3001',
          'RANDOM' => 'value',
          'HOME' => 'sweet home'
        }
      }
    }

    it 'allows parameters by regex' do
      expect(notice[:parameters]['API_PORT_80_TCP_PROTO']).to eq 'tcp'
      expect(notice[:cgi_data]['HTTP_HOST']).to eq 'localhost:3001'
    end

    it 'allows parameters by string' do
      expect(notice[:parameters]['HOME']).to eq '/home/sm'
      expect(notice[:cgi_data]['HOME']).to eq 'sweet home'
    end

    it 'filters variables not in whitelist' do
      expect(notice[:parameters]['SECRET_PASS']).to eq filtered
      expect(notice[:parameters]['SOME_PROTO_KEY']).to eq filtered
      expect(notice[:parameters]['PROTO_KEY']).to eq filtered
      expect(notice[:cgi_data]['RANDOM']).to eq filtered
    end

  end

end
