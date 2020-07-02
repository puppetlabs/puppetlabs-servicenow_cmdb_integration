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

### Unit tests
To run the unit tests:

```
bundle install
bundle exec rake spec
```

### Acceptance tests
The acceptance tests use puppet-litmus in a multi-node fashion. The nodes consist of a 'master' node representing the PE master (and agent), and a 'ServiceNow' node representing the ServiceNow instance. All nodes are stored in a generated `inventory.yaml` file (relative to the project root) so that they can be used with Bolt.

To setup the test infrastructure, use `bundle exec rake acceptance:setup`. This will:

* **Provision the master VM**
* **Setup PE on the VM**
* **Setup the mock ServiceNow instance.** This is just a Docker container on the master VM that mimics the relevant ServiceNow endpoints. Its code is contained in `spec/support/acceptance/servicenow`.

Each setup step is its own task; `acceptance:setup`'s implementation consists of calling these tasks. Also, all setup tasks are idempotent. That means its safe to run them (and hence `acceptance:setup`) multiple times.

**Note:** You can run the tests on a real ServiceNow instance. To do so, just invoke `bundle exec rake acceptance:setup_servicenow_instance[<fqdn>,<user>,<password>]`. This will update the `inventory.yaml` file with the actual ServiceNow instance credentials.

To run the tests after setup, you can do `bundle exec rspec spec/acceptance`. To teardown the infrastructure, do `bundle exec rake acceptance:tear_down`.

Below is an example acceptance test workflow:

```
bundle exec rake acceptance:setup
bundle exec rspec spec/acceptance
bundle exec rake acceptance:tear_down
```

#### Debugging the acceptance tests
Since the high-level setup is separate from the tests, you should be able to re-run a failed test multiple times via `bundle exec rspec spec/acceptance/path/to/test.rb`.

**Note:** Sometimes, the modules in `spec/fixtures/modules` could be out-of-sync. If you see a weird error related to one of those modules, try running `bundle exec rake spec_prep` to make sure they're updated.

The file `spec/support/acceptance/helpers.rb` contains some useful helpers that can ease debugging. Below is an example of how you can use these helpers.

```
Eniss-MacBook-Pro:puppetlabs-servicenow_cmdb_integration enisinan$ bundle exec irb
irb(main):001:0> load 'spec/support/acceptance/helpers.rb'
=> true
irb(main):002:0> include TargetHelpers
=> Object
irb(main):003:0> # Use Limus' helpers to do stuff on the master
irb(main):004:0> master.run_shell('ls')
=> #<OpenStruct exit_code=0, exit_status=0, stdout="1\nanaconda-ks.cfg\nmanifest_20200622_22980_155zqve.pp\nmanifest_20200622_22980_19g775.pp\nmanifest_20200622_22980_1dtgel2.pp\nmanifest_20200622_22980_1mf16ty.pp\nmanifest_20200622_22980_1nsgok6.pp\nmanifest_20200623_44190_1b2h8rj.pp\nmanifest_20200623_44190_9e5vur.pp\nmanifest_20200623_44190_ks1n4g.pp\nmanifest_20200623_44190_o22v01.pp\nmanifest_20200623_44190_xlrcbb.pp\nmanifest_20200623_44434_19cjntc.pp\nmanifest_20200623_44434_1jx3doo.pp\nmanifest_20200623_44434_1smu6yu.pp\nmanifest_20200623_44434_1u3b4mx.pp\nmanifest_20200623_44434_3ly1x7.pp\nmanifest_20200623_44434_47kln0.pp\nmanifest_20200623_44434_f308bk.pp\nmanifest_20200623_44434_i2btyu.pp\nmanifest_20200623_44434_sfjv8m.pp\nmanifest_20200623_44434_unnvkv.pp\nmanifest_20200623_44434_vp776h.pp\nmanifest_20200624_49267_1a1jlju.pp\nmanifest_20200624_49267_1l00glp.pp\nmanifest_20200624_49267_908wir.pp\nmanifest_20200624_49267_jpbmno.pp\nmanifest_20200624_49267_tuqhen.pp\nmanifest_20200624_49267_w8ul17.pp\nmanifest_20200624_49573_10h19kd.pp\nmanifest_20200624_49573_1plh7h6.pp\nmanifest_20200624_49573_1r31p6c.pp\nmanifest_20200624_49573_336mn7.pp\nmanifest_20200624_49573_55rvj.pp\nmanifest_20200624_49573_gsx71m.pp\nmanifest_20200624_49724_1ckdy0w.pp\nmanifest_20200624_49724_1nzgs98.pp\nmanifest_20200624_49724_85h8t7.pp\nmanifest_20200624_49724_md3gjn.pp\nmanifest_20200624_49724_u0jgnr.pp\nmanifest_20200624_50029_1sbezi2.pp\nmanifest_20200624_50029_1ugxi7j.pp\nmanifest_20200624_50029_u4o2gi.pp\nmanifest_20200624_50141_16fqrkw.pp\nmanifest_20200624_50141_1u41mrr.pp\nmanifest_20200624_50141_1xmtwhc.pp\nmanifest_20200624_50538_153o95v.pp\nmanifest_20200624_50538_3kiocu.pp\nmanifest_20200624_50538_ufdqd9.pp\nmanifest_20200624_50608_fz1coa.pp\nmanifest_20200624_50608_ptuwhr.pp\nmanifest_20200624_50608_qvgfbv.pp\nmanifest_20200624_50675_162gic8.pp\nmanifest_20200624_50675_1daji8m.pp\nmanifest_20200624_50675_1w7zy3p.pp\nmanifest_20200624_50723_11uvwo9.pp\nmanifest_20200624_50723_13farn8.pp\nmanifest_20200624_50723_14qgcoo.pp\nmanifest_20200624_50723_1j5z19k.pp\nmanifest_20200624_50723_1pqpciy.pp\nmanifest_20200624_50723_1q21n7c.pp\nmanifest_20200624_50723_1yjzbup.pp\nmanifest_20200624_50723_31lxzw.pp\nmanifest_20200624_50723_ddmwfx.pp\nmanifest_20200624_50723_fxqijx.pp\nmanifest_20200624_50723_yqj92c.pp\noriginal-ks.cfg\npe.conf\npuppet-enterprise-2019.7.0-el-8-x86_64\npuppet-enterprise-2019.7.0-el-8-x86_64.tar\npuppetlabs-servicenow_cmdb_integration-0.1.0.tar.gz\n", stderr="">
irb(main):005:0>
irb(main):006:0> # Use the CMDB helpers to do stuff on ServiceNow's CMDB
irb(main):007:0> CMDBHelpers.get_target_record(master)
=> nil
irb(main):008:0> # Use Litmus' helpers to do stuff on the ServiceNow instance
irb(main):009:0> servicenow_instance.run_bolt_task('servicenow_tasks::get_records', { 'table' => 'cmdb_ci', 'url_params' => {'sysparm_limit' => 1}}) 
=> #<OpenStruct exit_code=0, stdout="{\"result\"=>[{\"attested_date\"=>\"\", \"skip_sync\"=>\"false\", \"operational_status\"=>\"1\", \"sys_updated_on\"=>\"2019-03-05 21:54:31\", \"attestation_score\"=>\"\", \"u_puppet_classes\"=>\"\", \"discovery_source\"=>\"\", \"first_discovered\"=>\"\", \"sys_updated_by\"=>\"admin\", \"due_in\"=>\"\", \"sys_created_on\"=>\"2019-03-05 21:54:31\", \"sys_domain\"=>{\"link\"=>\"https://dev57373.service-now.com/api/now/table/sys_user_group/global\", \"value\"=>\"global\"}, \"install_date\"=>\"\", \"gl_account\"=>\"\", \"invoice_number\"=>\"\", \"sys_created_by\"=>\"admin\", \"warranty_expiration\"=>\"\", \"asset_tag\"=>\"\", \"fqdn\"=>\"\", \"change_control\"=>\"\", \"owned_by\"=>\"\", \"checked_out\"=>\"\", \"sys_domain_path\"=>\"/\", \"u_puppet_environment\"=>\"\", \"delivery_date\"=>\"\", \"maintenance_schedule\"=>\"\", \"install_status\"=>\"1\", \"cost_center\"=>\"\", \"attested_by\"=>\"\", \"supported_by\"=>\"\", \"dns_domain\"=>\"\", \"name\"=>\"Unknown\", \"assigned\"=>\"\", \"purchase_date\"=>\"\", \"subcategory\"=>\"\", \"short_description\"=>\"This CI is referenced by all duplicate CIs that were upgraded to New York. Before upgrade, discovery_source for these CIs was set to ‘Duplicate’. After upgrade, these CIs are updated to have the new Duplicate Of attribute. However, since the master CI for these upgraded duplicate CIs is unknown, Duplicate Of references the CI ‘Unknown’.\", \"assignment_group\"=>\"\", \"managed_by\"=>\"\", \"managed_by_group\"=>\"\", \"can_print\"=>\"false\", \"last_discovered\"=>\"\", \"sys_class_name\"=>\"cmdb_ci\", \"manufacturer\"=>\"\", \"sys_id\"=>\"8fbc3c053bc07300b924874064efc4ae\", \"po_number\"=>\"\", \"checked_in\"=>\"\", \"sys_class_path\"=>\"/!!\", \"mac_address\"=>\"\", \"vendor\"=>\"\", \"company\"=>\"\", \"justification\"=>\"\", \"model_number\"=>\"\", \"department\"=>\"\", \"assigned_to\"=>\"\", \"start_date\"=>\"\", \"comments\"=>\"\", \"cost\"=>\"\", \"sys_mod_count\"=>\"0\", \"monitor\"=>\"false\", \"serial_number\"=>\"\", \"ip_address\"=>\"\", \"model_id\"=>\"\", \"duplicate_of\"=>\"\", \"sys_tags\"=>\"\", \"cost_cc\"=>\"USD\", \"order_date\"=>\"\", \"schedule\"=>\"\", \"support_group\"=>\"\", \"environment\"=>\"\", \"due\"=>\"\", \"attested\"=>\"false\", \"correlation_id\"=>\"\", \"unverified\"=>\"false\", \"attributes\"=>\"\", \"location\"=>\"\", \"asset\"=>\"\", \"category\"=>\"\", \"fault_count\"=>\"0\", \"lease_id\"=>\"\"}]}", stderr=nil, result={"result"=>[{"attested_date"=>"", "skip_sync"=>"false", "operational_status"=>"1", "sys_updated_on"=>"2019-03-05 21:54:31", "attestation_score"=>"", "u_puppet_classes"=>"", "discovery_source"=>"", "first_discovered"=>"", "sys_updated_by"=>"admin", "due_in"=>"", "sys_created_on"=>"2019-03-05 21:54:31", "sys_domain"=>{"link"=>"https://dev57373.service-now.com/api/now/table/sys_user_group/global", "value"=>"global"}, "install_date"=>"", "gl_account"=>"", "invoice_number"=>"", "sys_created_by"=>"admin", "warranty_expiration"=>"", "asset_tag"=>"", "fqdn"=>"", "change_control"=>"", "owned_by"=>"", "checked_out"=>"", "sys_domain_path"=>"/", "u_puppet_environment"=>"", "delivery_date"=>"", "maintenance_schedule"=>"", "install_status"=>"1", "cost_center"=>"", "attested_by"=>"", "supported_by"=>"", "dns_domain"=>"", "name"=>"Unknown", "assigned"=>"", "purchase_date"=>"", "subcategory"=>"", "short_description"=>"This CI is referenced by all duplicate CIs that were upgraded to New York. Before upgrade, discovery_source for these CIs was set to ‘Duplicate’. After upgrade, these CIs are updated to have the new Duplicate Of attribute. However, since the master CI for these upgraded duplicate CIs is unknown, Duplicate Of references the CI ‘Unknown’.", "assignment_group"=>"", "managed_by"=>"", "managed_by_group"=>"", "can_print"=>"false", "last_discovered"=>"", "sys_class_name"=>"cmdb_ci", "manufacturer"=>"", "sys_id"=>"8fbc3c053bc07300b924874064efc4ae", "po_number"=>"", "checked_in"=>"", "sys_class_path"=>"/!!", "mac_address"=>"", "vendor"=>"", "company"=>"", "justification"=>"", "model_number"=>"", "department"=>"", "assigned_to"=>"", "start_date"=>"", "comments"=>"", "cost"=>"", "sys_mod_count"=>"0", "monitor"=>"false", "serial_number"=>"", "ip_address"=>"", "model_id"=>"", "duplicate_of"=>"", "sys_tags"=>"", "cost_cc"=>"USD", "order_date"=>"", "schedule"=>"", "support_group"=>"", "environment"=>"", "due"=>"", "attested"=>"false", "correlation_id"=>"", "unverified"=>"false", "attributes"=>"", "location"=>"", "asset"=>"", "category"=>"", "fault_count"=>"0", "lease_id"=>""}]}>
```
