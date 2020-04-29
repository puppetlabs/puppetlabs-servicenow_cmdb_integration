# @summary Creates the "ServiceNow Classification" node group
#
# This class creates the "ServiceNow Classification" node group. The group will be
# a child of the "All Nodes" group, and will include the servicenow_integration::classification
# class. The group matches all Puppet nodes, but noops on non-ServiceNow nodes since
# the servicenow_integration::classification class noops on those nodes.
#
# @example
#   include servicenow_integration::classification_group
class servicenow_integration::classification_group {
  node_group { 'ServiceNow Classification':
    ensure  => 'present',
    parent  => 'All Nodes',
    classes => {'servicenow_integration::classification' => {}},
    # Ideally, we'd like a rule that lets us match on nodes where
    # trusted['external']['servicenow']['puppet_classes'] exists.
    # Unfortunately, the classifier doesn't give you a way of specifying
    # that kind of rule so we will just match all nodes instead. Note that
    # this is safe to do because the classification class noops on
    # non-ServiceNow nodes.
    rule    => ['~', 'name', '.*']
  }
}
