# frozen_string_literal: true

require 'puppet_litmus/rake_tasks' if Bundler.rubygems.find_name('puppet_litmus').any?
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-syntax/tasks/puppet-syntax'
require 'puppet_blacksmith/rake_tasks' if Bundler.rubygems.find_name('puppet-blacksmith').any?
require 'github_changelog_generator/task' if Bundler.rubygems.find_name('github_changelog_generator').any?
require 'puppet-strings/tasks' if Bundler.rubygems.find_name('puppet-strings').any?

def changelog_user
  return unless Rake.application.top_level_tasks.include? "changelog"
  returnVal = nil || JSON.load(File.read('metadata.json'))['author']
  raise "unable to find the changelog_user in .sync.yml, or the author in metadata.json" if returnVal.nil?
  puts "GitHubChangelogGenerator user:#{returnVal}"
  returnVal
end

def changelog_project
  return unless Rake.application.top_level_tasks.include? "changelog"

  returnVal = nil
  returnVal ||= begin
    metadata_source = JSON.load(File.read('metadata.json'))['source']
    metadata_source_match = metadata_source && metadata_source.match(%r{.*\/([^\/]*?)(?:\.git)?\Z})

    metadata_source_match && metadata_source_match[1]
  end

  raise "unable to find the changelog_project in .sync.yml or calculate it from the source in metadata.json" if returnVal.nil?

  puts "GitHubChangelogGenerator project:#{returnVal}"
  returnVal
end

def changelog_future_release
  return unless Rake.application.top_level_tasks.include? "changelog"
  returnVal = "v%s" % JSON.load(File.read('metadata.json'))['version']
  raise "unable to find the future_release (version) in metadata.json" if returnVal.nil?
  puts "GitHubChangelogGenerator future_release:#{returnVal}"
  returnVal
end

PuppetLint.configuration.send('disable_relative')

if Bundler.rubygems.find_name('github_changelog_generator').any?
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    raise "Set CHANGELOG_GITHUB_TOKEN environment variable eg 'export CHANGELOG_GITHUB_TOKEN=valid_token_here'" if Rake.application.top_level_tasks.include? "changelog" and ENV['CHANGELOG_GITHUB_TOKEN'].nil?
    config.user = "#{changelog_user}"
    config.project = "#{changelog_project}"
    config.future_release = "#{changelog_future_release}"
    config.exclude_labels = ['maintenance']
    config.header = "# Change log\n\nAll notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org)."
    config.add_pr_wo_labels = true
    config.issues = false
    config.merge_prefix = "### UNCATEGORIZED PRS; GO LABEL THEM"
    config.configure_sections = {
      "Changed" => {
        "prefix" => "### Changed",
        "labels" => ["backwards-incompatible"],
      },
      "Added" => {
        "prefix" => "### Added",
        "labels" => ["feature", "enhancement"],
      },
      "Fixed" => {
        "prefix" => "### Fixed",
        "labels" => ["bugfix"],
      },
    }
  end
else
  desc 'Generate a Changelog from GitHub'
  task :changelog do
    raise <<EOM
The changelog tasks depends on unreleased features of the github_changelog_generator gem.
Please manually add it to your .sync.yml for now, and run `pdk update`:
---
Gemfile:
  optional:
    ':development':
      - gem: 'github_changelog_generator'
        git: 'https://github.com/skywinder/github-changelog-generator'
        ref: '20ee04ba1234e9e83eb2ffb5056e23d641c7a018'
        condition: "Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.2.2')"
EOM
  end
end

# ACCEPTANCE TEST RAKE TASKS + HELPERS

namespace :acceptance do
  require 'puppet_litmus/rake_tasks'
  require_relative './spec/support/acceptance/helpers'
  include TargetHelpers

  desc 'Start the PE container environment'
  task :start_containers do
    unless system('docker-compose -f ./spec/support/docker/pe_master/docker-compose.yml -p acceptance up --build -d')
      raise 'docker-compose failed to start PE.'
    end

    puts 'Wait for all docker containers to finish starting.'

    loop do
      healthy = true
      state = `docker ps --no-trunc -a --format '{{ json . }}'`
      state.split("\n").each do |instance|
        data = JSON.parse(instance)
        healthy = false unless data['Status'].include?('(healthy)')
      end

      break if healthy
    end

    puts 'Copy inventory to project root'
    FileUtils.cp('./spec/support/docker/inventory.yaml','./inventory.yaml')
    puts 'Copy eyaml support files'
    master.run_shell('rm -rf /etc/eyaml')
    master.bolt_upload_file('spec/support/common/hiera-eyaml', '/etc/eyaml')
    puts 'setup RBAC token'
    token_command = <<-HERE
      /bin/bash -c 'echo \'pupperware\' | puppet access login --lifetime 1y \
      --username admin \
      --service-url https://pe-console-services:4433/rbac-api \
      --ca-cert /opt/puppetlabs/server/data/puppetserver/certs/certs/ca.pem'
    HERE
    require 'pry'; binding.pry;
    master.run_shell(token_command)
  end

  desc 'Sets up the ServiceNow instance'
  task :setup_servicenow_instance, [:instance, :user, :password] do |_, args|
    instance, user, password = args[:instance], args[:user], args[:password]
    if instance.nil?
      # Start the mock ServiceNow instance. If an instance has already been started,
      # then the script will remove the old instance before replacing it with the new
      # one.
      puts("Starting the mock ServiceNow instance at the master (#{master.uri})")
      master.bolt_upload_file('./spec/support/docker/servicenow', '/tmp/servicenow')
      master.bolt_run_script('spec/support/acceptance/start_mock_servicenow_instance.sh')
      instance, user, password = "#{master.uri}:1080", 'mock_user', 'mock_password'
    else
      # User provided their own ServiceNow instance so make sure that they've also
      # included the instance's credentials
      raise 'The ServiceNow username must be provided' if user.nil?
      raise 'The ServiceNow password must be provided' if password.nil?
    end
   # Update the inventory file
    puts('Updating the inventory.yaml file with the ServiceNow instance credentials')
    inventory_hash = LitmusHelpers.inventory_hash_from_inventory_file
    servicenow_group = inventory_hash['groups'].find { |g| g['name'] =~ %r{servicenow} }
    unless servicenow_group
      servicenow_group = { 'name' => 'servicenow_nodes' }
      inventory_hash['groups'].push(servicenow_group)
    end
    servicenow_group['targets'] = [{
      'uri' => instance,
      'config' => {
        'transport' => 'remote',
        'remote' => {
          'user' => user,
          'password' => password,
        }
      },
      'vars' => {
        'roles' => ['servicenow_instance'],
      }
    }]
    write_to_inventory_file(inventory_hash, 'inventory.yaml')
  end

  desc 'Installs the module on the master'
  task :install_module do
    Rake::Task['litmus:install_module'].invoke(master.uri)
  end

  desc 'Set up the test infrastructure'
  task :setup, [:runner_platform] do
    tasks = [
      :start_containers,
      :install_module,
    ]

    tasks.each do |task|
      task = "acceptance:#{task}"
      puts("Invoking #{task}")
      Rake::Task[task].invoke
      puts("")
    end
  end

  desc 'Runs the tests'
  task :run_tests do
    puts("Running the tests ...\n")
    unless system('bundle exec rspec ./spec/acceptance --format documentation')
      # system returned false which means rspec failed. So exit 1 here
      exit 1
    end
  end

  desc 'Teardown the setup'
  task :tear_down do
    puts("Tearing down the test infrastructure ...\n")
    unless system('docker-compose -f ./spec/support/docker/pe_master/docker-compose.yml -p acceptance down --volumes')
      raise 'docker-compose failed to tear down compose environment.'
    end
    FileUtils.rm_f('inventory.yaml')
  end

  desc 'Task for CI'
  task :ci_run_tests do
    begin
      Rake::Task['acceptance:setup'].invoke
      Rake::Task['acceptance:run_tests'].invoke 
    # ensure
    #   Rake::Task['acceptance:tear_down'].invoke
    end
  end
end
