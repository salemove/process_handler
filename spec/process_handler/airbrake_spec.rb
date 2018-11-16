require 'spec_helper'
require 'salemove/process_handler/notifier_factory'
require 'securerandom'

describe 'Airbrake configuration' do
  let(:environment) { 'SOME_ENVIRONMENT' }
  let(:config) { airbrake_config.merge(type: 'airbrake') }
  let(:airbrake_config) { base_params }
  let(:base_params) do
    {
      environment: environment,
      host: 'localhost',
      project_id: '123456',
      project_key: 'abc123',
      ignore_environments: ['dev'],
      # Airbrake module raises an error when same notifier configured multiple times
      # Provide a random notifier name for each test case
      notifier_name: SecureRandom.hex
    }
  end
  let(:airbrake) do
    ProcessHandler::NotifierFactory.get_notifier('Process name', config)
  end

  context 'when all params set' do
    it 'does not raise an error' do
      expect { airbrake }.not_to raise_error
    end
  end

  context 'when project_id is not a number' do
    let(:airbrake_config) { base_params.merge(project_id: 'abc') }

    it 'raises error' do
      expect { airbrake }.to raise_error
    end
  end

  context 'when ignore_environments missing' do
    before { base_params.delete(:ignore_environments) }

    it 'does not raise an error' do
      expect { airbrake }.not_to raise_error
    end
  end

  shared_examples_for 'raises error if config param missing' do |key|
    context "when #{key} missing" do
      before { base_params.delete(key) }

      it 'raises error' do
        expect { airbrake }.to raise_error
      end
    end
  end

  it_behaves_like 'raises error if config param missing', :environment
  it_behaves_like 'raises error if config param missing', :host
  it_behaves_like 'raises error if config param missing', :project_id
  it_behaves_like 'raises error if config param missing', :project_key
end
