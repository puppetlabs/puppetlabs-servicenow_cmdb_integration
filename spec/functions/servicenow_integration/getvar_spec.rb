require 'spec_helper'

describe 'servicenow_integration::getvar' do
  let(:context) do
    Puppet::Pops::Lookup::Context.new({}, {})
  end

  before(:each) do
    allow(context).to receive(:explain)
  end

  context 'var does not start with a variable name' do
    # The regex that does this validation was copy-pasted from getvar
    # so we don't need very thorough testing for this
    let(:options) do
      { 'var' => '!' }
    end

    it { is_expected.to run.with_params(options, context).and_raise_error(ArgumentError, %r{!.*var.*name}) }
  end

  context 'topscope_vars_only is true, var contains a non-topscope variable' do
    it do
      options = {
        'topscope_vars_only' => true,
        'var'                => 'my_class::var',
      }
      is_expected.to run.with_params(options, context).and_raise_error(ArgumentError, %r{my_class::var.*topscope.*=false}m)
    end
  end

  [true, false].each do |topscope_vars_only|
    scope_type = topscope_vars_only ? 'topscope' : 'non-topscope'
    var_name = topscope_vars_only ? 'var' : 'my_class::var'

    context "var contains a #{scope_type} variable" do
      let(:options) do
        {
          'var'                => var_name,
          'topscope_vars_only' => topscope_vars_only,
        }
      end

      context 'that is nonexistent' do
        it do
          expect(context).to receive(:explain).exactly(0).times
          is_expected.to run.with_params(options, context).and_return({})
        end
      end

      context 'that is a non-Hash value' do
        it do
          expect(scope).to receive(:lookupvar).with(var_name).and_return(5)
          expect(context).to receive(:explain)
          is_expected.to run.with_params(options, context).and_return({})
        end
      end

      context 'that is a Hash value' do
        it do
          val = { 'foo' => 'bar' }
          expect(scope).to receive(:lookupvar).with(var_name).and_return(val)
          is_expected.to run.with_params(options, context).and_return(val)
        end
      end

      context "but no '.' after the variable" do
        it do
          opts = options.merge('var' => "#{var_name}!")
          is_expected.to run.with_params(opts, context).and_raise_error(ArgumentError, %r{first.*\.})
        end
      end

      context 'that is the start of a nested var' do
        let(:options) { super().merge('var' => "#{var_name}.foo") }

        # Note that our backend calls 'get' to handle the remaining part of the
        # nested var. The tests here are just a sanity check to ensure that
        # we give it the right parameters.

        context 'that is nonexistent' do
          it do
            allow(scope).to receive(:lookupvar).with(var_name).and_return('bar' => { 'qux' => 10 })
            expect(context).to receive(:explain).exactly(0).times
            is_expected.to run.with_params(options, context).and_return({})
          end
        end

        context 'that is existent' do
          it do
            opts = options.merge('var' => "#{var_name}.foo")
            allow(scope).to receive(:lookupvar).with(var_name).and_return('foo' => { 'bar' => 10 })
            is_expected.to run.with_params(opts, context).and_return('bar' => 10)
          end
        end
      end

      unless topscope_vars_only
        # We're testing non-topscope variables, so we'll need to also test that
        # our backend raises an error if topscope_vars_only is true
        context 'topscope_vars_only is true' do
          let(:options) { super().merge('topscope_vars_only' => true) }

          it do
            is_expected.to run.with_params(options, context).and_raise_error(ArgumentError, %r{#{var_name}.*topscope.*=false}m)
          end
        end
      end
    end
  end
end
