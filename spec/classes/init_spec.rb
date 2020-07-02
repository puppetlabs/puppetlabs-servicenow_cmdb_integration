# frozen_string_literal: true

require 'spec_helper'

describe 'servicenow_cmdb_integration' do
  let(:pre_condition) do
    <<-MANIFEST
    service { 'pe-puppetserver':
    }
    MANIFEST
  end

  context 'with a user and password' do
    let(:params) do
      {
        'instance' => 'foo_instance',
        'user' => 'foo_user',
        'password' => 'foo_password',
      }
    end

    it { is_expected.to compile.with_all_deps }
  end

  context 'with an oauth_token' do
    let(:params) do
      {
        'instance' => 'foo_instance',
        'oauth_token' => 'foo_oauth_token',
      }
    end

    it { is_expected.to compile }
  end

  context 'with all credentials' do
    let(:params) do
      {
        'instance' => 'foo_instance',
        'user' => 'foo_user',
        'password' => 'foo_password',
        'oauth_token' => 'foo_oauth_token',
      }
    end

    it { is_expected.to compile.and_raise_error(%r{ please specify either user/password or oauth_token not both. }) }
  end

  context 'without any credentials' do
    let(:params) do
      {
        'instance' => 'foo_instance',
      }
    end

    it { is_expected.to compile.and_raise_error(%r{ please specify either user/password or oauth_token }) }
  end

  context 'with only a user' do
    let(:params) do
      {
        'instance' => 'foo_instance',
        'user' => 'foo_user',
      }
    end

    it { is_expected.to compile.and_raise_error(%r{ missing password }) }
  end

  context 'with only a password' do
    let(:params) do
      {
        'instance' => 'foo_instance',
        'password' => 'foo_password',
      }
    end

    it { is_expected.to compile.and_raise_error(%r{ missing user }) }
  end
end
