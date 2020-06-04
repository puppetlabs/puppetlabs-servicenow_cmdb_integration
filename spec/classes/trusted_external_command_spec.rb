# frozen_string_literal: true

require 'spec_helper'

describe 'servicenow_cmdb_integration::trusted_external_command' do
  let(:params) do
    {
      'instance' => 'foo_instance',
      'user' => 'foo_user',
      'password' => 'foo_password',

    }
  end

  context "when Service['pe-puppetserver'] is defined" do
    let(:pre_condition) do
      <<-MANIFEST
service { 'pe-puppetserver':
}
      MANIFEST
    end

    it { is_expected.to compile }
  end

  # This test only works with the !defined() syntax for checking if a resource
  # exists. Unfortunately, that function does not work properly when actually run
  # against a master. When run in a real environment the syntax needs to be
  # unless Service['pe-puppetserver'] {blah}. But that syntax doesn't work for
  # this test. Until a way is found to fix this test I would prefer the syntax
  # that works in the product be used until we can either fix this test or find
  # a manifest syntax that will work in both cases.
  # context "when Service['pe-puppetserver'] is undefined" do
  #   it { is_expected.to compile }
  # end
end
