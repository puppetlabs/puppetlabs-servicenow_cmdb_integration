# @summary Adds ServiceNow classification to the node
#
# This class adds ServiceNow classification to the node. Specifically, it includes
# the classes specified in $trusted['external']['servicenow']['puppet_classes'] via
# an include statement. Note that class parameters will be retrieved from Hiera via
# the hiera backend that's shipped with the module.
#
# @example
#   include servicenow_integration::classification
class servicenow_integration::classification {
  $snow_classes = getvar('trusted.external.servicenow.puppet_classes', {})
  assert_type(Hash[String, Hash[String, Any]], $snow_classes) |$expected, $actual| {
    fail("trusted.external.servicenow.puppet_classes should be \'${expected}\' (Hash[ClassName, Parameters]), not \'${actual}\''")
  }
  $snow_classes.each |String $class, Hash $_| {
    unless defined($class) {
      fail("ServiceNow specified an undefined class ${class}")
    }
    include $class
  }
}
