# servicenow_cmdb_integration

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with servicenow_cmdb_integration](#setup)
    * [What servicenow_cmdb_integration affects](#what-servicenow_cmdb_integration-affects)
    * [Beginning with servicenow_cmdb_integration](#beginning-with-servicenow_cmdb_integration)
3. [Development - Guide for contributing to the module](#development)

## Description

This module integrates ServiceNow's CMDB with Puppet Enterprise. Specifically, it lets you

* Access a node's CMDB record as trusted external data via the `trusted.external.servicenow` hash.

* Classify nodes in the CMDB by using it to store the node's Puppet environment and classes. Puppet will automatically fetch and apply this classification in the node's subsequent runs.

## Setup

### What servicenow_cmdb_integration affects

* Installs a `servicenow.rb` script into a created `/etc/puppetlabs/puppet/trusted-external-commands` directory.

* Creates a `servicenow_cmdb.yaml` configuration file in `/etc/puppetlabs/puppet` that is needed by the `servicenow.rb` script.

* Updates `puppet.conf`'s `trusted_external_command` setting to point to the `servicenow.rb` script.

* Restarts puppetserver (`pe-puppetserver` service) so that the `puppet.conf` changes can take effect

If you'd like to also classify nodes in ServiceNow's CMDB, then the module:

* Requires adding a rule that matches on a ServiceNow-specified Puppet environment to all of your environment groups

* Requires adding a new `servicenow_cmdb_integration::getvar` Hiera backend to all of your environment `hiera.yaml` files

* Requires updating all of your environments' `site.pp` files to include a `servicenow_cmdb_integration::classification` class

### Beginning with servicenow_cmdb_integration

**Note:** If you're interested in both the ServiceNow CMDB external data and node classification features of this module, then you can just read the [classification](#ServiceNow-node-classification) section since that depends on the CMDB external data feature.

#### ServiceNow CMDB as trusted external data
Apply the `servicenow_cmdb_integration` class on all of your compilers. This looks something like:

```
class { 'servicenow_cmdb_integration':
  instance => '<fqdn_of_snow_instance>',
  user     => '<user>',
  password => '<password>',
}
```

> For customers using PE 2019.7+, we recommend adding this class to the `PE Master` node group. If HA is installed, then it should also be added to the `PE HA Replica` group.

This class installs the `servicenow.rb` script. The script fetches the node's CMDB record from the `cmdb_ci` table and stores it in the `trusted.external.servicenow` variable. This variable is a hash of `<field> => <value>` where `<field>` is a field in the `cmdb_ci` table and `<value>` is the field's value. If the field's a reference field then `<value>` is that field's display value.

**Note:** Puppet invokes the `servicenow.rb` script via the calling-convention `servicenow.rb <certname>`. The script fetches the node's CMDB record by querying the record whose `fqdn` field matches `<certname>`. If you're storing node certnames in a separate CMDB field, then you can set the `certname_field` parameter to that CMDB field's _column name_.

**Note to readers from the classification section:** If you're already storing the node's environment and classes in your own CMDB fields, then make sure to specify those fields' column names in the `environment_field` and `classes_field` parameters, respectively. Otherwise, these default to `u_puppet_environment` and `u_puppet_classes`, respectively.

#### ServiceNow node classification

This section talks about the setup required to classify nodes in ServiceNow's CMDB. Specifically, it walks through how to store the node's Puppet environment and classes in the CMDB and make Puppet aware of that information.

Here's what you have to do.

1\. Add the following custom fields to the `cmdb_ci` table in your ServiceNow instance:

<center>


| Field Name | Column Label | Column Name | Type |
| --- | --- | --- | --- |
| Puppet Environment | Puppet Environment | u\_puppet\_environment | String (Full UTF-8) |
| Puppet Classes | Puppet Classes | u\_puppet\_classes | String (Full UTF-8) |


</center>

Here, `Puppet Classes` is a JSON encoding of a `Hash[String, Hash[String, Any]]` type (informally, a `Hash[ClassName, Parameters]` object). For example, `"{\"foo_class\":{\"foo_param\":\"foo_value\"}}"` is a valid value for `Puppet Classes`. However, `{"foo_class":{"foo_param":"foo_value"}}` is not.

2\. In your control-repo, create a commit that:

* Adds the following to the `Puppetfile`:

	```
   mod 'puppetlabs/servicenow_cmdb_integration'
	```

* Adds the following Hiera backend to the `hiera.yaml` file:

	```
	- name: "ServiceNow Hiera data"
	  data_hash: servicenow_cmdb_integration::getvar
	  options:
	    var: trusted.external.servicenow.hiera_data
	```

	> This step's necessary for the integration to properly read the class parameters stored in `Puppet Classes`.

* Adds a `include servicenow_cmdb_integration::classification` line to the `site.pp` file at topscope. You can do this at the bottom of the `site.pp` file as shown:

	```
	# site.pp
	...
	include servicenow_cmdb_integration::classification
	```
	
	> The `classification` class includes all the classes specified in `trusted.external.servicenow.puppet_classes`. If that variable's not defined for the given node, then the class noops.

Once you've created the commit, **deploy it to all of your relevant enviroments**. Otherwise, classification will not work.

3\. For all relevant environments, add a rule of the form `['=', ['trusted', 'external', 'servicenow', 'puppet_environment'], '<enviroment>']` to their corresponding environment group. You can use the PE console to do this or the `servicenow_cmdb_integration::add_environment_rule` task. If you're using the PE console, then the rule should look something like:

`trusted.external.servicenow.puppet_environment` `=` `<environment>`

If you're using the task, then the task invocation should look something like:

```
puppet task run servicenow_cmdb_integration::add_environment_rule --params '{"group_names": <array_of_environment_group_names>}' --nodes <fqdn_of_node_containing_classifier_service>
```

> This step's necessary for the integration to set the node's environment to `Puppet Environment`.

4\. Setup the trusted external command by following the instructions in the [trusted external data](#ServiceNow-CMDB-as-trusted-external-data) section.


## Development

To run the unit tests:

```
bundle install
bundle exec rake spec
```
