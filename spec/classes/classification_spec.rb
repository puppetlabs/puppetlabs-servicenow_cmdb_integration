# frozen_string_literal: true

require 'spec_helper'

describe 'servicenow_integration::classification' do
  context 'when servicenow.puppet_classes is not specified' do
    it { is_expected.to compile }
  end

  context 'when servicenow.puppet_classes is specified' do
    context 'invalid type' do
      let(:trusted_external_data) do
        {
          servicenow: {
            puppet_classes: 'invalid_type',
          },
        }
      end

      it { is_expected.to raise_error(%r{puppet_classes.*Hash\[String.*Hash\[ClassName.*\].*String}) }
    end

    context 'contains a nonexistent class' do
      let(:trusted_external_data) do
        {
          servicenow: {
            puppet_classes: {
              'nonexistent_class' => {},
            },
          },
        }
      end

      it { is_expected.to raise_error(%r{undefined.*nonexistent_class}) }
    end

    context 'contains a valid list of classes' do
      let(:pre_condition) do
        <<-CLASSES
        class a {}
        class b {}
        CLASSES
      end
      let(:trusted_external_data) do
        {
          servicenow: {
            puppet_classes: {
              'a' => {},
              'b' => {},
            },
          },
        }
      end

      it { is_expected.to compile }
      it { is_expected.to contain_class('a') }
      it { is_expected.to contain_class('b') }
    end
  end
end
