Puppet::Functions.create_function(:'servicenow_integration::getvar') do
  dispatch :getvar do
    param 'Struct[{var=>String[1],topscope_vars_only=>Optional[Boolean]}]', :options
    param 'Puppet::LookupContext', :context
  end

  # Much of this code was inspired by getvar's implementation, which you can
  # find at https://github.com/puppetlabs/puppet/blob/6.15.0/lib/puppet/functions/getvar.rb
  def getvar(options, context)
    var = options['var']
    topscope_vars_only = true
    if options.key?('topscope_vars_only')
      topscope_vars_only = options['topscope_vars_only']
    end

    # Parse the var. This code is copied from getvar's implementation for
    # consistency.
    unless (matches = var.match(%r{^((::)?(\w+::)*\w+)(.*)\z}))
      raise ArgumentError, "the var '#{var}' does not start with a valid variable name"
    end
    # rem_sequence => remaining_sequence. This will be passed into 'get'
    rem_sequence = matches[4]
    if rem_sequence[0] == '.'
      rem_sequence = rem_sequence[1..-1]
    else
      unless rem_sequence.empty?
        raise ArgumentError, "first character after var name in var must be a '.' - got #{rem_sequence[0]}"
      end
    end
    var_name = matches[1]

    if topscope_vars_only && var_name.include?('::')
      # topscope_vars_only is true but var_name is not a topscope variable
      msg = <<-MESSAGE
attempting to consult non-topscope variable "#{var_name}". This is
prohibited by the topscope_vars_only=true option, which dictates that variables
consulted must be in topscope. If you would like to consult "#{var_name}" anyway, you
must set topscope_vars_only=false under the options key in this backend's Hiera
config
      MESSAGE
      raise ArgumentError, msg
    end

    # Get the value specified in the var. Note that 'catch(:undefined_variable)' is
    # the idiomatic way of catching undefined variables.
    catch(:undefined_variable) do
      var_value = closure_scope.lookupvar(var_name)
      # The default value '{}' is there in case rem_sequence doesn't
      # exist in var_value
      final_value = call_function('get', var_value, rem_sequence, {})
      unless final_value.is_a?(Hash)
        msg = "[servicenow_integration::getvar] '#{var}'' resolves to a non-Hash value so returning an empty Hash instead"
        context.explain { msg }
        final_value = {}
      end
      return final_value
    end

    # Variable doesn't exist so return an empty hash
    {}
  end
end
