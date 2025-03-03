# !/opt/puppetlabs/puppet/bin/ruby
# puts 'running as ruby'

## Implemented own versions: require_relative './helpers.rb'

module VP
  require 'puppet_litmus'
  PuppetLitmus.configure!

  class Target
    include PuppetLitmus

    attr_reader :uri

    def initialize(uri)
      @uri = uri
    end

    def bolt_config
      inventory_hash = LitmusHelpers.inventory_hash_from_inventory_file
      LitmusHelpers.config_from_node(inventory_hash, @uri)
    end

    # Make sure that ENV['TARGET_HOST'] is set to uri
    # before each PuppetLitmus method call. This makes it
    # so if we have an array of targets, say 'agents', then
    # code like agents.each { |agent| agent.bolt_upload_file(...) }
    # will work as expected. Otherwise if we do this in, say, the
    # constructor, then the code will only work for the agent that
    # most recently set the TARGET_HOST variable.
    PuppetLitmus.instance_methods.each do |name|
      m = PuppetLitmus.instance_method(name)
      define_method(name) do |*args, &block|
        ENV['TARGET_HOST'] = uri
        m.bind(self).call(*args, &block)
      end
    end
  end

  # class TargetNotFoundError < StandardError; end
  module TargetHelpers
    def master
      target('master', 'acceptance:provision_vms', 'master')
    end
    module_function :master

    def servicenow_instance
      target('ServiceNow instance', 'acceptance:setup_servicenow_instance', 'servicenow_instance')
    end
    module_function :servicenow_instance

    def servicenow_host
      target('ServiceNow host', 'valentepuppet:setup_servicenow_host', 'servicenow_host')
    end
    module_function :servicenow_host

    def target(name, setup_task, role)
      @targets ||= {}

      unless @targets[name]
        # Find the target
        inventory_hash = LitmusHelpers.inventory_hash_from_inventory_file '/Users/valente/tmp/m/a.yaml'
        targets = LitmusHelpers.find_targets(inventory_hash, nil)
        target_uri = targets.find do |target|
          vars = LitmusHelpers.vars_from_node(inventory_hash, target) || {}
          roles = vars['roles'] || []
          roles.include?(role)
        end
        unless target_uri
          raise TargetNotFoundError, "none of the targets in 'inventory.yaml' have the '#{role}' role set. Did you forget to run 'rake #{setup_task}'?"
        end
        @targets[name] = Target.new(target_uri)
      end

      @targets[name]
    end
    module_function :target
  end

  module LitmusHelpers
    extend PuppetLitmus
  end
end

namespace :valentepuppet do
  require 'puppet_litmus/rake_tasks'
  require 'English'
  require 'open3'
  # require_relative './helpers'

  include VP::TargetHelpers

  desc 'Testing of Parameters'
  task :parametertests, [:para1, :para2] do |_t, paras|
    # master = VP::Target.new('AAAAAA')
    a = master.uri
    puts "Hello...#{paras[:para1]}...#{paras[:para2]}...#{a}"

    master.run_shell('date')
    master.run_shell('hostname')
    master.run_shell('uptime')
  end

  desc 'PlaceHolder for Skipping'
  task :skipme, [:para1, :para2] do |_t, paras|
    puts "Skipping...with.para1:#{paras[:para1]}...para2:#{paras[:para2]}......"
  end

  # Task For the Standard Breakdown of the Acceptance Test Stages.
  desc 'Provision environment'
  task :provision_environment__task, [:platformprovider, :platforms_image, :docker_runopts] do |_t, paras|
    puts "INPUTS...#{paras}"
    puts 'Provisioning.......... environment'

    begin
      ENV['PROVISION_LIST'] = "acceptance_vbox_#{paras[:platforms_image].gsub('litmusimage/', '').gsub(%r{[-.:]}, '_').downcase}" # Set for Provision to pick up
    rescue
      ENV['PROVISION_LIST'] = "acceptance_vbox_#{paras[:platforms_image]}" # Set for Provision to pick up
    end

    puts ".......... PROVISION_LIST=#{ENV['PROVISION_LIST']}"
    puts "..........................#{paras[:platforms_image]}===>===#{ENV['PROVISION_LIST']}"
    puts "..........................#{paras[:platformprovider]}===>===vagrant"

    ################# Setup Part1

    cmds = 'bash ./spec/support/acceptance/vhelper.sh exec "runChain + '
    cmds += ' runlogged /tmp/provision.txt +'
    cmds += " runlogged /tmp/provision.txt  echo platforms_image='#{paras[:platforms_image]}'   +"
    cmds += " runlogged /tmp/provision.txt  echo platformprovider='#{paras[:platformprovider]}'   +"
    cmds += ' catMe /tmp/provision.txt  +'
    cmds += ' echoMsg == Prep Install Checks   + installPkg git + chkPkg git curl bash puppet-bolt  +'
    cmds += ' echoMsg == Prep Install Start  + modify_sudo_settings +'
    cmds += ' Create_the_fixtures_directory + echoMsg == Installation of Binary Bolt + install_actual_bolt + echoMsg == Installation of Bolt Modules + install_bolt_modules +'
    cmds += '" 2>&1'
    puts "Part 1 Executing #{cmds}".gsub('+', "+\n").gsub(%r{password: .+}, 'password: [redacted]')
    output = `#{cmds}`
    if $CHILD_STATUS.success?
      puts output.gsub('\n', "\n").gsub(%r{password: .+}, 'password: [redacted]')
    else
      puts 'SKIPPED abort error: could not execute command for stage 1'
    end

    ################# Setup Part2
    puts " \n \n \n \n \n"
    cmds = 'bash ./spec/support/acceptance/vhelper.sh exec "runChain + '
    cmds += ' echoMsg == PreInstall Checks  + chkPkg git curl bash puppet-bolt  +'
    cmds += ' echoMsg == PreInstall Start +  preinstallpecommands + '
    cmds += '" 2>&1'
    puts "Part 2 Executing #{cmds}".gsub('+', "+\n").gsub(%r{password: .+}, 'password: [redacted]')
    output = `#{cmds}`
    if $CHILD_STATUS.success?
      puts output.gsub('\n', "\n").gsub(%r{password: .+}, 'password: [redacted]')
    else
      puts 'SKIPPED abort error: could not execute command for stage 2'
    end

    ################# Setup Part3
    puts " \n \n \n \n \n"
    cmds = 'bash ./spec/support/acceptance/vhelper.sh exec "runChain + '
    cmds += ' echoMsg == Install Start  + installpe + '
    cmds += '" 2>&1'
    puts "Part 3 Executing #{cmds}".gsub('+', "+\n").gsub(%r{password: .+}, 'password: [redacted]')
    output = `#{cmds}`
    if $CHILD_STATUS.success?
      puts output.gsub('\n', "\n").gsub(%r{password: .+}, 'password: [redacted]')
    else
      puts 'SKIPPED abort error: could not execute command for stage 3'
    end

    puts "\n\n\n\n\n"
    puts '==========Installation Done: installpe done. =========================='
    inventoryfile = './spec/fixtures/litmus_inventory.yaml'
    invcontent = ''
    if File.exist?(inventoryfile)
      File.open(inventoryfile, 'r') do |f|
        f.each_line do |line|
          invcontent += line unless %r{^[ ]*#}.match?(line)
        end
      end
      puts "===Actual=Contents=#{inventoryfile}===\n#{invcontent}".gsub(%r{password: .+}, 'password: [redacted]')
    end
    exit 404 if invcontent.empty?
  end

  desc 'Install Puppet agent'
  task :install_agent__task, [:matrix_collection] do |_t, paras|
    puts "INPUTS...#{paras}"
    puts `bash ./spec/support/acceptance/vhelper.sh exec "installpecommands" 2>&1 |  grep -v '.... .......... ....' `.gsub('\n', "\n")
  end

  desc 'Install module'
  task :install_module__task do # , [:para1, :para2] do |_t, paras|
    # puts `bash ./spec/support/acceptance/vhelper.sh exec "prepcommand1" `.gsub('\n', "\n").gsub(%r{password: .+}, 'password: [redacted]')

    ################# Setup Part1a
    puts " \n \n \n \n \n"
    cmds = 'bash ./spec/support/acceptance/vhelper.sh exec "runChain + '
    cmds += ' echoMsg == prepcommand1a  + prepcommand1a + '
    cmds += '" 2>&1'
    puts "Executing #{cmds}".gsub('+', "+\n").gsub(%r{password: .+}, 'password: [redacted]')
    output = `#{cmds}`
    if $CHILD_STATUS.success?
      puts output.gsub('\n', "\n").gsub(%r{password: .+}, 'password: [redacted]')
    else
      puts 'SKIPPED abort error: could not execute command for stage 1a'
    end

    ################# Setup Part1b
    puts " \n \n \n \n \n"
    cmds = 'bash ./spec/support/acceptance/vhelper.sh exec "runChain + '
    cmds += ' echoMsg == prepcommand1b  + prepcommand1b + '
    cmds += '" 2>&1'
    puts "Executing #{cmds}".gsub('+', "+\n").gsub(%r{password: .+}, 'password: [redacted]')
    output = `#{cmds}`
    if $CHILD_STATUS.success?
      puts output.gsub('\n', "\n").gsub(%r{password: .+}, 'password: [redacted]')
    else
      puts 'SKIPPED abort error: could not execute command for stage 1b'
    end
  end

  desc 'Run acceptance tests'
  task :acceptance__task do # , [:para1, :para2] do |_t, paras|
    #    provisiontxtfile = '/tmp/provision.txt'
    #    puts "File.read(#{provisiontxtfile})" if File.exist?(provisiontxtfile)
    #    puts File.read(provisiontxtfile) if File.exist?(provisiontxtfile)
    #
    #    if File.exist?(provisiontxtfile)
    #      if %r{bunutu}.match?(File.read(provisiontxtfile))
    #        puts 'Inside Primary Server as a container: Creating ServiceNow Server.......'
    #        Rake::Task['acceptance:setup_servicenow_instance'].invoke
    #      else
    #        puts 'Inside GitHub Runner as a container: Creating ServiceNow Server.......'
    #        Rake::Task['valentepuppet:setup_servicenow_host'].invoke
    #      end
    #    end

    #    puts 'Testing ServiceNow Server.......'
    #    Rake::Task['acceptance:test_servicenow_host'].invoke

    puts 'Acceptance Test Continues........'
    # Does not show error even when there is an error            puts system('bash', './spec/support/acceptance/vhelper.sh', 'exec', 'command')
    cmd = 'bash ./spec/support/acceptance/vhelper.sh exec command'
    stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
    puts stdout.read.to_s.gsub('\n', "\n").gsub(%r{password: .+}, 'password: [redacted]')

    if wait_thr.value.success?
      stdin.close
      stdout.close
      stderr.close
      exit(true)
    else
      puts "Error level was: #{wait_thr.value.exitstatus}\n#{stderr.read}".gsub('\n', "\n").gsub(%r{password: .+}, 'password: [redacted]')
      stdin.close
      stdout.close
      stderr.close
      exit wait_thr.value.exitstatus
    end
  end

  desc 'Remove test environment'
  task :tear_down__task do # , [:para1, :para2] do |_t, paras|
    puts `bash ./spec/support/acceptance/vhelper.sh exec "postcommand" `.gsub('\n', "\n").gsub(%r{password: .+}, 'password: [redacted]')
  end
  #
  # end of Rake Tasks
  #
  #
  #
  #
  #
  #
  #
  #
  # ### Litmus Helper
  desc 'Sets up the ServiceNow host'
  task :setup_servicenow_host do
    if File.exist?('inventory.yaml')
      # Check if a servicenow_host docker's already been setup
      begin
        uri = servicenow_instance.uri # an exception occurs here
        puts("A servicenow_instance VM at '#{uri}' has already been set up")
        next
      rescue TargetNotFoundError
        # This means that we haven't set up the servicenow_host docker
        cmd = 'bash ./spec/support/acceptance/vhelper.sh exec setup_servicenow_host ||  true  '
        stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
        puts stdout.read.to_s.gsub('\n', "\n")

        if wait_thr.value.success?
          puts('  Creating entry for servicenow_instance inventory')
          servicenow_host_uri = 'localhost'
          Rake::Task['acceptance:setup_servicenow_instance'].invoke("#{servicenow_host_uri}:1080", 'mock_user', 'mock_password', 'mock_token', 'setup_servicenow_host_docker')

          stdin.close
          stdout.close
          stderr.close
          exit(true)
        else
          puts "Error level was: #{wait_thr.value.exitstatus}\n#{stderr.read}"
          stdin.close
          stdout.close
          stderr.close
          exit wait_thr.value.exitstatus
        end
      end
    end
    servicenow_host_uri = 'localhost'
    Rake::Task['acceptance:setup_servicenow_instance'].invoke("#{servicenow_host_uri}:1080", 'mock_user', 'mock_password', 'mock_token', 'setup_servicenow_host_docker')
  end

  desc 'Prep ServiceNow host with sample Data, Upload the Whole Project to the master'
  task :prep_servicenow_host do
    master.run_shell('mkdir -p /tmp/puppetlabs-servicenow_cmdb_integration/spec/support/acceptance')
    master.bolt_upload_file('../puppetlabs-servicenow_cmdb_integration/Rakefile', '/tmp/puppetlabs-servicenow_cmdb_integration/')
    master.bolt_upload_file('../puppetlabs-servicenow_cmdb_integration/Gemfile', '/tmp/puppetlabs-servicenow_cmdb_integration/')
    master.bolt_upload_file('../puppetlabs-servicenow_cmdb_integration/inventory.yaml', '/tmp/puppetlabs-servicenow_cmdb_integration/')
    master.bolt_upload_file('../puppetlabs-servicenow_cmdb_integration/spec/support/acceptance/vhelper.rb', '/tmp/puppetlabs-servicenow_cmdb_integration/spec/support/acceptance/')
    master.bolt_upload_file('../puppetlabs-servicenow_cmdb_integration/spec/support/acceptance/vhelper.sh', '/tmp/puppetlabs-servicenow_cmdb_integration/spec/support/acceptance/')
    master.bolt_upload_file('../puppetlabs-servicenow_cmdb_integration/spec/support/acceptance/helpers.rb', '/tmp/puppetlabs-servicenow_cmdb_integration/spec/support/acceptance/')

    master.bolt_upload_file('/tmp/v.sh', '/tmp/')
    master.run_shell('chmod 777 /tmp/v.sh')

    cmd = 'bash /tmp/puppetlabs-servicenow_cmdb_integration/spec/support/acceptance/vhelper.sh exec '
    cmd += 'runChain + installPkg nodejs  +  setupruby ruby/setup-ruby@v1 ruby-version="2.7" bundler-cache=true +'
    master.run_shell(cmd)
  end

  desc 'Test ServiceNow host with sample Data'
  task :test_servicenow_host do # , [:servicenowserver] do |_t, _paras|
    cmdb_table = 'cmdb_ci'
    certname_field = 'fqdn'

    testfield = 'location'
    teststring = 'KoKo_NI_ISEKAI_DESU_616'

    fields_template = JSON.parse(File.read('spec/support/acceptance/cmdb_record_template.json'))
    fields_template['attributes'] = cmdb_table
    fields_template[testfield] = teststring
    # rubocop:disable all
    begin
      CMDBHelpers.create_target_record(servicenow_instance, fields_template, table: cmdb_table, certname_field: certname_field)
    rescue
      # This means record exist.
    end
    # rubocop:enable all
    cmdb_record = CMDBHelpers.get_target_record(servicenow_instance)
    CMDBHelpers.delete_target_record(servicenow_instance, table: cmdb_table, certname_field: certname_field)
    h1 = 'TESTING SERVICENOW SERVER'
    puts "#{h1}......cmdb_record['#{testfield}']..should.be.'#{teststring}'.........is.'#{cmdb_record[testfield]}'.(#{(cmdb_record[testfield] == teststring) ? 'same' : 'different'})"

    # master.run_shell("curl -k https://#{paras[:servicenowserver]}:1080")
  end

  desc 'Sets up the ServiceNow host with docker'
  task :setup_servicenow_host_docker do
    if File.exist?('inventory.yaml')
      # Check if a servicenow_host docker's already been setup
      begin
        uri = servicenow_host.uri # an exception occurs here
        puts("A servicenow_host VM at '#{uri}' has already been set up")
        next
      rescue TargetNotFoundError
        # This means that we haven't set up the servicenow_host docker
        provision_list = 'acceptance_docker_servicenow'
        Rake::Task['litmus:provision_list'].invoke(provision_list)

        puts("Starting the mock ServiceNow instance at the servicenow_host (#{servicenow_host.uri})")
        servicenow_host.bolt_upload_file('./spec/support/acceptance/servicenow', '/tmp/servicenow')

        ## New Code #
        servicenow_host.bolt_upload_file('./spec/support/acceptance/servicenow/Gemfile', '/tmp/servicenow')
        servicenow_host.bolt_upload_file('./spec/support/acceptance/servicenow/mock_instance.rb', '/tmp/servicenow')
        servicenow_host.bolt_upload_file('./spec/support/acceptance/start_mock_servicenow_instance.sh', '/tmp/servicenow')

        ## Old Code #
        servicenow_host.bolt_run_script('spec/support/acceptance/start_mock_servicenow_instance.sh')
      end
    end
    servicenow_host_uri = servicenow_host.uri.split(':')[0]
    Rake::Task['acceptance:setup_servicenow_instance'].invoke("#{servicenow_host_uri}:1080", 'mock_user', 'mock_password', 'mock_token', 'setup_servicenow_host_docker')
  end
end
