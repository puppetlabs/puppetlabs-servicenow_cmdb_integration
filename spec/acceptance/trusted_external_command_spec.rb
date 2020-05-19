require 'spec_helper_acceptance'

context 'servicenow_integration::trusted_external_command' do
  context 'apply the class' do
    let(:default_manifest) {<<-HERE
      class {'servicenow_integration::trusted_external_command':
          instance => 'dev1',
          user     => 'devuser',
          password => 'devpass',
      }
      HERE
    }

    it 'applies the class without error' do
      sudo_idempotent_apply(default_manifest)
    end
  end
end
