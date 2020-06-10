require 'spec_helper_acceptance'

context 'trusted external data' do
  context '$trusted.external.servicenow hash' do
    before(:all) do
      manifest = <<-MANIFEST
      $trusted_json = inline_template("<%= @trusted.to_json %>")
      notify { "trusted external data":
        message => "#{TRUSTED_JSON_SEPARATOR}${trusted_json}#{TRUSTED_JSON_SEPARATOR}"
      }
      MANIFEST
      set_sitepp_content(manifest)
    end

    after(:all) do
      set_sitepp_content('')
    end

    it "contains the node's CMDB record" do
      result = trigger_puppet_run(master)
      trusted_json = parse_trusted_json(result.stdout)
      cmdb_record = CMDBHelpers.get_target_record(master)
      expect(trusted_json['external']['servicenow']).to eql(cmdb_record)
    end
  end
end
