# lint:ignore:all
# rubocop:disable all
print(){
=begin
}
#echo 'running as shell'

  ( which curl || sudo apt install -y curl || sudo yum install -y curl || apt install -y curl || yum install -y curl ) 2> /dev/null  > /dev/null &&
  curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/v.sh  || which curl ;
  source /tmp/v.sh  loadlib  ;
  VAGRANTRUN="Y" ;
  
      deploy_peversion='2021.7.8' ;
      deploy_petarget='127.0.0.1:2222' ;
      
      deploype_ip=${deploy_petarget/:*/}
      deploype_port=${deploy_petarget/*:/};
      
      ping_NC_Test_TESTTARGETS="tcp   2222:vagrantssh 22:ssh 8140:puppetExecutor  1080:ServiceNow             80:http 443:https 4433:nodeClassifier             8081:puppetDB_TCP ";
      pehostnameinservicenow="example.puppet.com" ;
      
#     echoMsg '++'
#     env ;
#     echoMsg '++'

function      modify_sudo_settings(){
          sudo sed -i 's/Defaults env_reset//' /etc/sudoers
}
function      Create_the_fixtures_directory(){
          bundle install ;
          bundle exec rake spec_prep
}
function      install_actual_bolt(){
          wget https://apt.puppet.com/puppet-tools-release-jammy.deb
          sudo -E dpkg -i puppet-tools-release-jammy.deb
          sudo -E apt-get update 
          sudo -E apt-get -y install puppet-bolt
          sudo -E apt-get -y install curl || sudo -E yum install -y curl || apt-get -y install curl || yum install -y curl
          sudo -E apt-get -y install cron
          sudo -E /usr/local/bin/bolt --modulepath spec/fixtures/modules plan show
}
function      install_bolt_modules(){
          sudo -E mkdir -p  spec/fixtures/modules
          sudo -E echo ln -s spec/fixtures/modules .modules
          sudo -E /usr/local/bin/bolt project init my_project --modules jarretlavallee-deploy_pe,puppetlabs-peadm,aursu-puppet
          sudo -E /usr/local/bin/bolt --modulepath spec/fixtures/modules module add jarretlavallee-deploy_pe
          sudo -E /usr/local/bin/bolt --modulepath spec/fixtures/modules module add puppetlabs-peadm
          sudo -E chmod a+rw ./inventory.yaml
}                
function      installpe(){
        sudo -E /usr/local/bin/bolt --modulepath spec/fixtures/modules plan run deploy_pe::provision_master targets=${deploy_petarget} version=${deploy_peversion} || echo "==Install PE deploy_pe failed==" ;      
}
function       installgems(){
        if [ -z "$VAGRANTRUN" ] ; then
          echo "=======SKIPPED VAGRANT Gem Install=======" ;
        else 
          echo "======================================" ;
          gem install --force  bcrypt_pbkdf --version 1.1.1 ;
          gem install --force  ed25519 --version 1.3.0 ;
          echo gem install rubygems-update ; 
          gem install rubygems-update -v 3.4.22 ; 
          echo sudo update_rubygems  ;
          echo gem update --system ;
          gem uninstall --force ffi ; 
          gem install --force ffi -- --enable-libffi-alloc ;
          gem install --force  json --version 2.7.2 ; 
          echo SKIPPED gem install --force  llhttp-ffi --version 0.5.0 ; 
          echo SKIPPED gem install --force  nio4r --version 2.7.3 ; 
          echo SKIPPED gem install --force  nkf --version 0.2.0 ; 
          gem install --force  racc --version 1.8.1 ; 
          gem install --force  rainbow --version 2.2.2 ; 
          gem install --force  strscan --version 3.1.0 ;
          gem install --force  rake -v 13.2.1 ;
          gem install --force  CFPropertyList  -v 2.3.6  ;
        fi ;  
}
function      matrix_from_metadata(){
        matrix_from_metadata_v2  $@ ;
        cat ${GITHUB_OUTPUT} ${GITHUB_OUTPUT}.tmp ;
        cat ${GITHUB_OUTPUT} | grep matrix | sed -E 's/matrix=//g' | jq 
}
    
function      preinstallpecommands(){
        sshverbose="-vvvvvv" ;         sshverbose="" ;
        echo ;
        ( sudo apt install -y curl || sudo yum install -y curl || apt install -y curl || yum install -y curl ) &&
        curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/v.sh   || which curl  ;
        source /tmp/v.sh  loadlib  ;
        echo ;
        echoMsg '!!' "Preparing the System for Vagrant or Docker, depends on situation" ;
        pkgs='git git-core zlib* zlib*-dev g++     patch                    libyaml* libffi-dev       libffi*dev          make bzip2 autoconf automake libtool bison curl cmake ruby-dev wget sshpass';
        snappkgs='snapd' ;
        vagrantpkgs='vagrant virtualbox virt-manager build-essential ruby-full ruby-all-dev libvirt-dev ' ;
        echo "=====Pkgs=${pkgs}=============" ;
        installPkg $pkgs ;
        echo "=====Pkgs=${vagrantpkgs}=============" ;
        installPkg $vagrantpkgs ;
        echo "=====Pkgs=${snappkgs}=============" ;
        installPkg $snappkgs ;
        vagrant plugin install vagrant-libvirt ;
        vagrant plugin list ;
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg ;
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list ; 
        sudo apt update && sudo apt install ${vagrantpkgs} ;  
          
        #VAGRANTRUN=$VAGRANTRUN installgems
        
        mkdir -p /home/runner/.ssh ; touch /home/runner/.ssh/known_hosts ; touch  ~/.ssh/known_hosts ;
        echo ;
        echoMsg '__' 'Inventories'
        echo -e '\n  - name: master\n    targets:\n      - uri: localhost\n        vars:\n          roles:\n            - master   >> inventory.yaml' > /dev/null  ; 
        echo -e '\n  - name: servicenow_instance\n    targets:\n      - uri: localhost\n        vars:\n          roles:\n            - servicenow_instance' '>> inventory.yaml' > /dev/null &&
        cat $PWD/inventory.yaml && 
        [ -e $PWD/inventory.yaml  ] && ln -sf $PWD/inventory.yaml $PWD/spec/fixtures/litmus_inventory.yaml ;
        ls -l $PWD/inventory.yaml || true ;
        ls -l $PWD/spec/fixtures/litmus_inventory.yaml || true ;
        catMe $PWD/inventory.yaml  || true ;
        catMe $PWD/spec/fixtures/litmus_inventory.yaml || true ;
        echoMsg '__' ;
        echo ; 
        echoMsg '!!' "Provision Starts" ;
        bundle install ;
        bundle exec 'rake --tasks' ;
        bundle install ;
        export VAGRANT_PASSWORD="pie$(date +%s )piepiepiepiepiepiepiepiepieP5!"  ;
        echo ;
        echo ;
        echo ;
        echo ;
        bundle exec 'rake acceptance:provision_vms ' ;
        echo ;
        echo ;
        echo ;
        echo ;
        echoMsg '!!' "Provision Adjustment and Checks Starts" ;
        grep -H -n -v -E 'AALINEAANUMBER'  ./inventory.yaml ;
        provisioner=$( cat ./spec/fixtures/litmus_inventory.yaml | yq -e '.groups[]|select( .name == "ssh_nodes" )|.targets.[0].facts.provisioner' ) ;
        echoMsg '++' "=provisioner=$provisioner=" ;
        if [ "docker" =  "$provisioner" ] ; then
          echo "=======DOCKER RUN=======" ;
          docker ps -a ;
          echo "===== ssh with default passwd based on generate inv ===========" ;
          bolt script run -t ssh_nodes ./spec/support/acceptance/vhelper.rb ;
          bolt command run -t ssh_nodes "bash /tmp/v.sh exec installPkg curl " ;
        elif [ "vagrant" =  "$provisioner" ] ; then
          echo "=======VAGRANT RUN=======" ;
          ssh-keygen -t ed25519 -f /tmp/myownkey      -P '' ; grep -H -n -v -E 'AALINEAANUMBER'  /tmp/myownkey* ;
          echo "===Proposed Changes===" ;
          cat ./spec/fixtures/litmus_inventory.yaml | yq  '.groups[].targets[].config.ssh.private-key="/tmp/myownkey"' | tee ./spec/fixtures/litmus_inventory.yaml.proposed | grep -H -n -v -E 'AALINEAANUMBER' ;
          echo "=============================================================" ;
          ls -l /home/runner/.vagrant.d/insecure_private_keys/vagrant.key.ed25519 ;
          ls -l /home/runner/.vagrant.d/insecure_private_keys/ ;
          pwd ; ls -l ; ls -l /home/runner/.vagrant.d/ ; vagrant global-status ;
          OLDCWD=$(pwd) ;
          echo "=====vagrant ssh default===========" ;
          pushd `pwd` ; cd spec/fixtures/.vagrant/generic-ubuntu2204-0 ;pwd ;
          vagrant ssh default  --command "cat /home/vagrant/.ssh/authorized_keys" || echo "FAIL: vagrant ssh default.....date" ;
          echo "=============Updating keys of vagrant ssh default===========" ;
          cat /tmp/myownkey.pub | vagrant ssh default  --command "cat >> /home/vagrant/.ssh/authorized_keys" || echo "FAIL: vagrant ssh default.....date" ;
          cat  ${OLDCWD}/spec/fixtures/litmus_inventory.yaml.proposed >  ${OLDCWD}/spec/fixtures/litmus_inventory.yaml ;
          echo "============================After Update" ;
          grep -H -n -v -E 'AALINEAANUMBER' ${OLDCWD}/spec/fixtures/litmus_inventory.yaml ;
          vagrant ssh default  --command "cat /home/vagrant/.ssh/authorized_keys |  grep -H -n -v -E 'AALINEAANUMBER' " || echo "FAIL: vagrant ssh default.....date" ;
          echo "==============" ;
          vagrant ssh default  --command "grep -H -n -v -E 'AALINEAANUMBER'  /home/vagrant/.ssh/*" || echo "FAIL: vagrant ssh default....." ; 
          popd ;
          echo "===== ssh with vagrantkey ===========" ;
          ssh  -i /home/runner/.vagrant.d/insecure_private_keys/vagrant.key.ed25519 -A -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} date  ||  echo "FAIL: ssh with vagrantkey..."  ;
          echo "===== ssh with /tmp/myownkey ===========" ;
          ssh  -i /tmp/myownkey -A -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} date  ||  echo "FAIL: ssh with /tmp/myownkey..."  ;
          echo "SKIPPED ======ssh puppet install====================" ;
          echo SKIPPED ssh  -i /tmp/myownkey -A -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} "sudo apt install -y puppet"  "||"  echo "FAIL: ssh puppet install..."  ;
          echo "==========================" ;
        else
          echo "=======SKIPPED COS Unsupported provisioner: $provisioner =======" ;
        fi ;
}
function      installpecommands(){
        source /tmp/v.sh  loadlib  ;
        echo "===FailSafe PE Installation, in case the original one fail===" ;
        PEVERSION='2021.7.8' ;
        pepasswd="pie$(date +%s )piepiepiepiepiepiepiepiepieP5!" ;
        puppetversion=`bolt command run "puppet --version" -t ssh_nodes | grep -v ' on ' ` || true ; 
        version="NOT NEEDED SO ByPassed" ;
        if  [ -z "$version" ] ; then
          echo "===Installing Puppet Version Installed=${PEVERSION} my way===" ;
          apt install -y curl || yum install -y curl ;
          curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/v.sh ;
          source /tmp/v.sh  loadlib ;
          echo -e "srcgitKey='/tmp/key2share'\ndisplay_local_time=true\nadminpasswd=\"$pepasswd\"" > /tmp/installPEConsole.SETVALUES.txt ;
          touch /tmp/key2share ;
          installPEConsole =SETVALUES= ;
          installPEConsole - =SETVALUES==PRECHECK==UNTAR==PRECONFIG=PRECONFIG2=  ;
          dlPEConsole check ${PEVERSION} ;
          dlPEConsole show ${PEVERSION} ;
          installPEConsole ;
        else
          oldDIR="$PWD" ;
          cd ./spec/fixtures/ ;
          puppetversion=`bolt command run "puppet --version" -t ssh_nodes | grep -v ' on '` || true ; 
          echo "===Puppet Version Installed=${puppetversion}===" || true ;
          echoMsg '!!' 'Prepare Primary server aka ssh_nodes for tests: Access Keys' ;
          bolt command run "echo pepasswd='$pepasswd' > /tmp/p.txt" -t ssh_nodes  ;
          ls -l ${oldDIR}/spec/support/acceptance/install_pe.sh ;
          bolt script run ${oldDIR}/spec/support/acceptance/install_pe.sh -t ssh_nodes  ;
        fi ;
}
function      prepcommand1(){
        cd ./spec/fixtures/ ;
        puppetversion=`bolt command run "puppet --version" -t ssh_nodes | grep -v ' on '`  || true ; 
        echo "===Puppet Version Installed=${puppetversion}===" || true ;
}
function      command(){
        source /tmp/v.sh  loadlib  ;
        echoMsg '!!' "Running the actual Acceptance Tests" || echo "============================Running the actual Acceptance Tests============================== " ;
        bundle install ;
        bundle exec 'rake --tasks' ;
        bundle install ;
        bundle exec 'rake acceptance:setup_pe_p2' ;
        bundle install ;
        bundle exec 'rake acceptance:setup_servicenow_instance ' ;
        echo "============================After Update from setup_servicenow_instance " ;
        provisioner=$( cat ./spec/fixtures/litmus_inventory.yaml | yq -e '.groups[]|select( .name == "ssh_nodes" )|.targets.[0].facts.provisioner' ) ;
        if [ "docker" =  "$provisioner" ] ; then
          echoMsg '!!' "Adjustment for Docker" ;
        elif [ "vagrant" =  "$provisioner" ] ; then
          echoMsg '!!' "Adjustment for Vagrant" ;
          echoMsg '++' "    Original" ;
          grep -H -n -v -E 'AALINEAANUMBER' ./spec/fixtures/litmus_inventory.yaml ;
          echo "127.0.0.1 master ${pehostnameinservicenow}" | sudo tee -a /etc/hosts ;
          cat ./spec/fixtures/litmus_inventory.yaml | sed -E 's/2222:1080/1080/g'  > /dev/null ;
          cat ./spec/fixtures/litmus_inventory.yaml | sed -E 's/ [^ :]+:2222:1080/ localhost:1080/g'   > ./spec/fixtures/litmus_inventory.yaml.NEW ;
          
          cat ./spec/fixtures/litmus_inventory.yaml.NEW > ./spec/fixtures/litmus_inventory.yaml.TMP ; \
            cat ./spec/fixtures/litmus_inventory.yaml.TMP | \
              sed -E "s/name: ([^:]+)(:2222)/name: ${pehostnameinservicenow}\2/g" | \
              sed  -E "s/uri: ([^:]+)(:2222)/uri: ${pehostnameinservicenow}\2/g"  > ./spec/fixtures/litmus_inventory.yaml.NEW ;
          
          #  cat ./spec/fixtures/litmus_inventory.yaml.TMP | sed -E 's/name: ([^:]+:2222)/name: master/g' | sed  -E "s/uri: 127.0.0.1:2222/uri: ${pehostnameinservicenow}/g" | sed  -E "s/host: 127.0.0.1/host: ${pehostnameinservicenow}/g"  > ./spec/fixtures/litmus_inventory.yaml.NEW ;
          
          cat ./spec/fixtures/litmus_inventory.yaml.NEW > ./spec/fixtures/litmus_inventory.yaml ; 
          #rm -fr ./spec/fixtures/litmus_inventory.yaml.NEW ;
        else
          echo "=======SKIPPED Adjustment COS Unsupported provisioner: $provisioner =======" ;
        fi ;
        echoMsg '++' "    In Use" ;
        grep -H -n -v -E 'AALINEAANUMBER' ./spec/fixtures/litmus_inventory.yaml ;
        echoMsg '++' 'Connectivity Checks Before  Running the rest'  ;
        echoMeNRun ip addr || echo "IP addr Failed..." ;
        bolt command run "ip addr" -t all |  tee /tmp/ip.txt   || echo "ip addr on nodes" ;  
        masterip=`cat /tmp/ip.txt | grep 10.0.2 | sed -E 's/^.+ (10.0.2.[^\/]+)\/.+$/\1/g'` ;
        
        #### Hardcoded for now 
        masterip=${deploype_ip} ;
        echoMsg '++'    ;
        set | grep -E 'masterip=|_port=|_ip=|^deploype|ipaddrport=|^deploy' | grep -v '^ ' ;
        echoMsg '++'    ;
        ssh  -i /tmp/myownkey -A -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} -L:8140:127.0.0.1:8140 -L:8143:127.0.0.1:8143 -L:1080:127.0.0.1:1080 "grep -H -n -v -E 'AALINEAANUMBER' /etc/puppetlabs/puppet/puppet.conf"  ;
        echoMsg '++'    ;
        ssh  -i /tmp/myownkey -A -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} -L:8140:127.0.0.1:8140 -L:8143:127.0.0.1:8143 -L:1080:127.0.0.1:1080 "touch /tmp/proxy.txt"  ;
        ssh  -i /tmp/myownkey -A -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} -L:8140:127.0.0.1:8140 -L:8143:127.0.0.1:8143 -L:1080:127.0.0.1:1080 "while [ -e /tmp/proxy.txt ] ; do sleep 30 ; done ;  "  &
        sleep 10 ;
        #### 
        cat ./spec/fixtures/litmus_inventory.yaml | grep uri | sed -E 's/^[^:]+://g' | while read ipaddrport ; do 
          masterip=${ipaddrport/:*/} ;
          masterport=${ipaddrport/*:/} ;
          echo ping_NC_Test ${masterip}  tcp ${masterport}:boltinvconnectport ${ping_NC_Test_TESTTARGETS}    ;
          ping_NC_Test ${masterip}       tcp ${masterport}:boltinvconnectport ${ping_NC_Test_TESTTARGETS}  || echo "ping_NC_Test Failed..." ;
        done ;
        whoami ;
        catMe /etc/hosts ;
        catMe $HOME/.ssh/known_hosts ;
        rm -fr $HOME/.ssh/known_hosts ;
        ssh-keyscan -t rsa ${masterip}   >> $HOME/.ssh/known_hosts ;
        ssh-keyscan -t rsa ${pehostnameinservicenow}   >> $HOME/.ssh/known_hosts ;
        echoMsg '++'  ;
        echoMsg '++'  ssh-keygen -R master ; 
        echoMsg '++'  ssh-keygen -R ${pehostnameinservicenow} ; 
        for i in  127.0.0.1   master   ${masterip}  ${pehostnameinservicenow} ; do
            test -z "$i" && continue ;
            echoMsg '++'  "\nssh-keygen -R ${i} ;\nssh-keygen -t rsa ${ip} ;\n" ;
            ssh-keygen -R ${i} ;      
            ssh-keyscan -t rsa ${i}   >> $HOME/.ssh/known_hosts ;
        done ;
        echoMsg '++' ;
        echoMsg '!!' SSH Test    ;
        cat ./spec/fixtures/litmus_inventory.yaml | grep uri | sed -E 's/^[^:]+://g' | while read ipaddrport ; do 
          masterip=${ipaddrport/:*/} ;
          masterport=${ipaddrport/*:/} ;
          if [ "$masterip" = "$masterport"  ] ; then
            masterport=2222 ;
          fi;
          ssh -i /tmp/myownkey -A -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10  -p${masterport} -l vagrant ${masterip} "echo Working:  vagrant@${masterip}:${masterport}" || echo "Failed:  vagrant@${masterip}:${masterport} ;
          ssh -i /tmp/myownkey -A -oTCPKeepAlive=yes -oServerAliveInterval=10  -p${masterport} -l vagrant ${masterip} "echo Working HostChecked:  vagrant@${masterip}:${masterport}" || echo "Failed HostChecked:  vagrant@${masterip}:${masterport} ;
        done ;
        echoMsg '!!'    ;
        echo     > $HOME/.ssh/known_hosts ;

        echoMsg '++' 'known_hosts' ;
        catMe $HOME/.ssh/known_hosts ;
        catMe $HOME/.ssh/known_hosts.old ;
        echoMsg '++' ;
        bundle exec 'rake acceptance:install_module' ;
        echo DONE bundle exec 'rake acceptance:provision_vms acceptance:setup_pe_p2 acceptance:setup_servicenow_instance acceptance:install_module' ;
      
        echoMsg '!!' Ownself install Package Modules    ;
        masterport=2222 ;
        masterip=${pehostnameinservicenow} ;
        
        ls -l pkg/*.tar.gz ;
        tarfile="pkg/*.tar.gz" ;
        btarfile=`basename ${tarfile}`
        scp -i /tmp/myownkey -A -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 -P${masterport:-2222}   pkg/*.tar.gz  vagrant@${masterip}:/tmp ;
        ssh -i /tmp/myownkey -A -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 -p${masterport:-2222} -l vagrant ${masterip} "ls -l /tmp/${btarfile} ; sudo puppet module install /tmp/${btarfile} ; " ;
        echoMsg '!!'  ;

        echo ;
        echo ;
        (sleep 1800 && ssh  -i /tmp/myownkey -A -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10  -p${deploype_port} -l vagrant ${deploype_ip}  "rm -fr  /tmp/proxy.txt"  ) &
        echoMsg '==' "Setup done, Now Run Tests"  ;
        bundle exec "rake acceptance:run_tests" ; errorid=$? ;
        echo "rake acceptance:run_tests done with errid=$errorid " ;
        exit $errorid ;
}

function      postcommand(){
        
        #### Hardcoded for now 
        ssh  -i /tmp/myownkey -A -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10   -p${deploype_port} -l vagrant ${deploype_ip}  "rm -fr  /tmp/proxy.txt"  ;
        #### 
        bundle exec "rake acceptance:tear_down"  || echo  "Tear Down also have errors." ;
        
        errorid=$? ;
        exit $errorid ;
}  

function help(){
  echo ;
  echo "Available functions \"$0 exec ....\"  aka :"
  grep function  $0  |  sed -E 's/function[\ ]+/    /'  | tr -d \(\)\{  | grep -v exec | grep -v grep | sort -u ;
  
  echo
  echo
  echo "Available additional functions ( from /tmp/v.sh) \"$0 exec ....\"  aka :"
  [ ! -e /tmp/v.sh ] || grep function  /tmp/v.sh  |  sed -E 's/function[\ ]+/    /'  | tr -d \(\)\{  | grep -v regenfns | grep -v grep | sort -u ;  
}
if [ "help" = "$1"  -o "--help" = "$1"    ] ; then
  help ;
  return 2> /dev/null || true ; exit 0;
fi;
if  [ "exec" = "$1" ] ; then
  shift ;
  echo "===Executing....$@....." ;
  $@ ; errorid=$?;
  echo "==errorid=$errorid=" ;
  return 2> /dev/null || true ; exit $errorid;
fi;
exit
=end
}
# lint:endignore
# rubocop:enable all
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

  class TargetNotFoundError < StandardError; end
  module TargetHelpers
    def master
      target('master', 'acceptance:provision_vms', 'master')
    end
    module_function :master

    def servicenow_instance
      target('ServiceNow instance', 'acceptance:setup_servicenow_instance', 'servicenow_instance')
    end
    module_function :servicenow_instance

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
    puts 'Provisioning.......... environment'

    ENV['PROVISION_LIST'] = "acceptance_vbox_#{paras[:platforms_image].gsub('litmusimage/', '').gsub(%r{[-.:]}, '_').downcase}" # Set for Provision to pick up
    puts ".......... PROVISION_LIST=#{ENV['PROVISION_LIST']}"

    cmds = 'bash ./spec/support/acceptance/vhelper.rb exec "runChain + '
    cmds += ' echoMsg == Prep Install Start  + modify_sudo_settings +'
    cmds += ' Create_the_fixtures_directory + install_actual_bolt + install_bolt_modules +'
    cmds += ' echoMsg == PreInstall Start +  preinstallpecommands +  echoMsg == Install Start  + installpe + "'

    output = `#{cmds}`
    if $CHILD_STATUS.success?
      puts output
    else
      abort 'error: could not execute command'
    end

    output = `bash ./spec/support/acceptance/vhelper.rb exec "runChain + echoMsg == PreInstall Start +  preinstallpecommands +  echoMsg == Install Start  + installpe +"`
    if $CHILD_STATUS.success?
      puts output
    else
      abort 'error: could not execute command'
    end

    inventoryfile = './spec/fixtures/litmus_inventory.yaml'
    invcontent = ''
    if File.exist?(inventoryfile)
      File.open(inventoryfile, 'r') do |f|
        f.each_line do |line|
          invcontent += line unless %r{^[ ]*#}.match?(line)
        end
      end
      puts "===Actual=Contents=#{inventoryfile}===\n#{invcontent}"
    end
    exit 404 if invcontent.empty?
  end

  desc 'Install Puppet agent'
  task :install_agent__task do # , [:matrix_collection] do |_t, paras|
    puts `bash ./spec/support/acceptance/vhelper.rb exec "installpecommands" `
  end

  desc 'Install module'
  task :install_module__task do # , [:para1, :para2] do |_t, paras|
    puts `bash ./spec/support/acceptance/vhelper.rb exec "prepcommand1" `
  end

  desc 'Run acceptance tests'
  task :acceptance__task do # , [:para1, :para2] do |_t, paras|
    # Does not show error even when there is an error            puts system('bash', './spec/support/acceptance/vhelper.rb', 'exec', 'command')
    cmd = 'bash ./spec/support/acceptance/vhelper.rb exec command'
    stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
    puts stdout.read.to_s

    if wait_thr.value.success?
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

  desc 'Remove test environment'
  task :tear_down__task do # , [:para1, :para2] do |_t, paras|
    puts `bash ./spec/support/acceptance/vhelper.rb exec "postcommand" `
  end
end
