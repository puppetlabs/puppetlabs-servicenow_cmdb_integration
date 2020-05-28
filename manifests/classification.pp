# @summary Adds ServiceNow classification to the node
#
# This class adds ServiceNow classification to the node. Specifically, it includes
# the classes specified in $trusted['external']['servicenow']['puppet_classes'] via
# an include statement. Note that class parameters will be retrieved from Hiera via
# the hiera backend that's shipped with the module.
#
# If $trusted['external']['servicenow']['puppet_classes'] doesn't exist, then this
# class noops. Informally, this means that the class noops on non-ServiceNow nodes.
#
# @example
#   include servicenow_cmdb_integration::classification
class servicenow_cmdb_integration::classification {
  $snow_classes = getvar('trusted.external.servicenow.puppet_classes')
  unless $snow_classes == undef {
    assert_type(Hash[String, Hash[String, Any]], $snow_classes) |$expected, $actual| {
      fail("trusted.external.servicenow.puppet_classes should be \'${expected}\' (Hash[ClassName, Parameters]), not \'${actual}\''")
    }
    unless lookup('servicenow_cmdb_integration_data_backend_present', 'default_value' => false) {
      fail("The servicenow_cmdb_integration::getvar Hiera backend isn't setup to read class parameters from ServiceNow")
    }
    $snow_classes.each |String $class, Hash $_| {
      unless defined($class) {
        fail("ServiceNow specified an undefined class ${class}")
      }
      include $class
    }
  }
}
