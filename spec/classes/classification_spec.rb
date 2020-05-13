# frozen_string_literal: true

require 'spec_helper'

describe 'servicenow_integration::classification' do
  context 'when servicenow.puppet_classes is not specified' do
    it { is_expected.to compile }
  end

  context 'when servicenow.puppet_classes is specified' do
    let(:puppet_classes) do
      {}
    end
    let(:hiera_data) do
      { servicenow_integration_data_backend_present: true }
    end
    let(:trusted_external_data) do
      {
        servicenow: {
          puppet_classes: puppet_classes,
          hiera_data: hiera_data,
        },
      }
    end

    context 'Hiera backend is not setup' do
      let(:hiera_data) { nil }

      it { is_expected.to raise_error(%r{getvar.*Hiera}) }
    end

    context 'invalid type' do
      let(:puppet_classes) { 'invalid_type' }

      it { is_expected.to raise_error(%r{puppet_classes.*Hash\[String.*Hash\[ClassName.*\].*String}) }
    end

    context 'contains a nonexistent class' do
      let(:puppet_classes) do
        { 'nonexistent_class' => {} }
      end

      it { is_expected.to raise_error(%r{undefined.*nonexistent_class}) }
    end

    context 'contains a valid list of classes' do
      let(:pre_condition) do
        <<-CLASSES
        class a {}
        class b(
          String $param
        ) {
          notify { "${param}":
          }
        }
        CLASSES
      end
      let(:puppet_classes) do
        {
          'a' => {},
          'b' => {},
        }
      end
      let(:hiera_data) do
        super().merge('b::param' => 'from_hiera')
      end

      it { is_expected.to compile }
      it { is_expected.to contain_class('a') }
      it do
        is_expected.to contain_class('b')
        is_expected.to contain_notify('from_hiera')
      end
    end
  end
end
