# no_param.pp
class no_param {}
class single_param(String $param = 'default') {}
class multiple_params(String $param_one = 'default', String $param_two = 'default') {}

include servicenow_cmdb_integration::classification

# See this function's use below to understand why we need it
function assert_known_var(String $var) {
  $value = getvar($var)
  if $value == undef {
    fail("expected the variable '${var}' to be known but it isn't. Is its class included in the manifest?")
  }
  $value
}

$classification_hash = {
  'environment' => $environment,
  'classes'     => {
    'no_param'        => {},
    'single_param'    => {
      # If 'single_param::param' is unknown, then that means the 'single_param'
      # class wasn't properly included so something's up with classification.
      # Unfortunately, Puppet logs a warning for unknown variables; it does not
      # fail the run. Thus, we pass the variable through assert_known_var so that
      # the run fails if the variable's unknown.
      'param' => assert_known_var('single_param::param'),
    },
    'multiple_params' => {
      'param_one' => assert_known_var('multiple_params::param_one'),
      'param_two' => assert_known_var('multiple_params::param_two'),
    }
  }
}
$classification_json = inline_template('<%= @classification_hash.to_json %>')
notify { 'classification info':
  message =>  "<JSON>${classification_json}<JSON>",
}
