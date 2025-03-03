#!/bin/bash
# echo 'running as shell'

VALENTEHOME="" ;
if [  "`uname`" = "Darwin" -o -d "/Users/valente"    ] ; then
  VALENTEHOME="Y" ;
fi;

echo "===VALENTEHOME=$VALENTEHOME="
  
if [ -z "$VALENTEHOME"  ] ; then
  ( which curl || sudo apt install -y curl 2> /dev/null  > /dev/null || sudo yum install -y curl 2> /dev/null  > /dev/null  || apt install -y curl 2> /dev/null  > /dev/null || yum install -y curl 2> /dev/null  > /dev/null ) 2> /dev/null  > /dev/null &&
  curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/v.sh  2> /dev/null  || which curl ;
else
  curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/v.sh  2> /dev/null  || which curl ;
fi ;

  source /tmp/v.sh  loadlib  || . source /tmp/v.sh  loadlib  ;
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
  
    BOLTCMD=`cat /tmp/boltcmdsh 2> /dev/null `   || true 
    BOLTCMD=${BOLTCMD:-`cd /tmp/ && which bolt`}   || true 
    BOLTCMD=${BOLTCMD:-`which bolt`}   || true 
    set | grep -E '^BOLTCMD='   || true 
  
    if [ -x /opt/puppetlabs/bin/bolt ] ; then
      BOLTCMD=/opt/puppetlabs/bin/bolt ;
      echo '/opt/puppetlabs/bin/bolt' > /tmp/boltcmdsh ;
    fi ;
            
    if [ -x /usr/local/bin/bolt ] ; then
      BOLTCMD=/usr/local/bin/bolt ;
      echo '/usr/local/bin/bolt' > /tmp/boltcmdsh ;
    fi ;
  
    export BOLTCMD=${BOLTCMD:-/usr/local/bin/bolt}
    export BOLT_PROJECT=$PWD

function monoglot(){  # To update the ./spec/support/acceptance/vhelper.rb and ./spec/support/acceptance/vhelper.sh,  RUN : ./spec/support/acceptance/vhelper.sh.rb exec monoglot
        pushd $PWD ;
        cd  `dirname $0` ;
        echoMsg '__' monoglotting ...
        cat   `basename $0` | awk -F' ' 'BEGIN { prn =1 } /^[#][ ][P][O][L][Y][G][L][O][T]/{    print "Change file "$3"....." ; system("cat /tmp/vhelper.tmp > "$3 )  ; system( "cat /dev/null  > /tmp/vhelper.tmp ") ;  next ; } { print >> "/tmp/vhelper.tmp" ; }   '  | tee  /tmp/vhelper.log ;
        
        rm -fr  /tmp/vhelper.tmp
        
        chmod a+x ./vhelper.sh
        chmod a+x ./vhelper.rb
        
        popd 

}
function installgitfromsrc(){
          cd /tmp/
          sudo yum groupinstall "Development Tools"
          sudo yum install -y gettext-devel openssl-devel perl-CPAN perl-devel zlib-devel glibc-devel

          wget https://github.com/git/git/archive/v2.1.2.tar.gz -O git.tar.gz
          tar -zxf git.tar.gz
          cd git-*
          make configure
          ./configure --prefix=/usr/local
          sudo make install
  
          git --version
}
function      setupruby(){
          [ -e /tmp/v.sh ]  ||   curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/v.sh   || which curl  ;
          source /tmp/v.sh  loadlib  ;
          [ ! -z "$VALENTEHOME"  ] || \
            rungithubactionuse - ruby/setup-ruby@v1 ruby-version="2.7" bundler-cache=true ;
}
function      modify_sudo_settings(){
          [ ! -z "$VALENTEHOME"  ] || \
          sudo sed -i 's/Defaults env_reset//' /etc/sudoers
}
function      Create_the_fixtures_directory(){
          bundle install ;
          bundle exec rake spec_prep
}
function      disableApparmor(){
        if [ -z "$VALENTEHOME"  ] ; then
          if command -v apparmor_parser >/dev/null ; then
            sudo find /etc/apparmor.d/ -maxdepth 1 -type f -exec ln -sf {} /etc/apparmor.d/disable/ \;
            sudo apparmor_parser -R /etc/apparmor.d/disable/* || true
            sudo systemctl disable apparmor
            sudo systemctl stop apparmor
          fi ;
        fi
}
function      setup_servicenow_host(){
          cp -fvr ./spec/support/acceptance/servicenow  /tmp/ ||  true ;
          chmod a+x ./spec/support/acceptance/start_mock_servicenow_instance.sh ||  true ;
          ./spec/support/acceptance/start_mock_servicenow_instance.sh ||  true ;
}
function      install_actual_bolt(){
        if [ -z "$VALENTEHOME"  ] ; then   
          # Ubuntu
          wget https://apt.puppet.com/puppet-tools-release-jammy.deb 2> /dev/null  > /dev/null
          sudo -E dpkg -i puppet-tools-release-jammy.deb 2> /dev/null  > /dev/null
          sudo -E apt-get update  2> /dev/null  > /dev/null
          sudo -E apt-get -y install puppet-bolt 2> /dev/null  > /dev/null
          sudo -E apt-get -y install curl 2> /dev/null  > /dev/null || sudo -E yum install -y curl  2> /dev/null  > /dev/null || apt-get -y install curl 2> /dev/null  > /dev/null || yum install -y curl 2> /dev/null  > /dev/null
          sudo -E apt-get -y install cron 2> /dev/null  > /dev/null
          sudo -E /usr/local/bin/bolt --modulepath spec/fixtures/modules plan show


          # RHEL or Fedora
          sudo rpm -Uvh https://yum.puppet.com/puppet-tools-release-fedora-36.noarch.rpm 2> /dev/null  > /dev/null
          sudo dnf install puppet-bolt 2> /dev/null  > /dev/null
  
  
          # SLES 15
          sudo rpm -Uvh https://yum.puppet.com/puppet-tools-release-sles-15.noarch.rpm 2> /dev/null  > /dev/null
          sudo zypper install puppet-bolt 2> /dev/null  > /dev/null
          

          # SLES 12
          sudo rpm -Uvh https://yum.puppet.com/puppet-tools-release-sles-12.noarch.rpm 2> /dev/null  > /dev/null
          sudo zypper install puppet-bolt 2> /dev/null  > /dev/null
        fi ;

  
  
          
          which bolt | tee /tmp/boltcmdsh >  /tmp/boltcmd.sh
          echo '$@'  >> /tmp/boltcmd.sh

          echo '#!/bin/bash'  > /tmp/boltcmd_sh
          cat /tmp/boltcmd.sh | tr '[:cntrl:]' ' '  >> /tmp/boltcmd_sh
          chmod a+x /tmp/boltcmd_sh

  
          if [ -x /opt/puppetlabs/bin/bolt ] ; then
            BOLTCMD=/opt/puppetlabs/bin/bolt ;
            echo '/opt/puppetlabs/bin/bolt' > /tmp/boltcmdsh ;
          fi ;
          if [ -x /usr/local/bin/bolt ] ; then
            BOLTCMD=/usr/local/bin/bolt ;
            echo '/usr/local/bin/bolt' > /tmp/boltcmdsh ;
          fi ;
    
          catMe /tmp/boltcmd_sh
  
          export BOLTCMD=`cat /tmp/boltcmdsh `
          env | grep BOLTCMD
}
function      install_bolt_modules(){
          sudo -E mkdir -p  spec/fixtures/modules
          sudo -E echo ln -s spec/fixtures/modules .modules
          sudo -E ${BOLTCMD:-/usr/local/bin/bolt} project init my_project --modules jarretlavallee-deploy_pe,puppetlabs-peadm,aursu-puppet
          sudo -E ${BOLTCMD:-/usr/local/bin/bolt} --modulepath spec/fixtures/modules module add jarretlavallee-deploy_pe
          sudo -E ${BOLTCMD:-/usr/local/bin/bolt} --modulepath spec/fixtures/modules module add puppetlabs-peadm
          sudo -E chmod a+rw ./inventory.yaml
}
function      peneedpkg(){
      if [ -z "$VALENTEHOME"  ] ; then
        for p in initscripts chkconfig  ; do
          installPkg $p || true ;
        done ;
      fi;
}                
function      installpe(){
  
        cat > /tmp/deploy_pePrep << '__END'
        [ -e /tmp/v.sh ]  ||   curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/v.sh   || which curl  ;
        source /tmp/v.sh  loadlib  ;
  
        uninstallPkg puppet || true ;
        uninstallPkg pe-installer || true ;
        uninstallPkg pe-modules || true ;
        uninstallPkg puppet-agent || true ;
        uninstallPkg rubygem-puppet  || true ;

        installPkg dnf  || true ;
__END
        chmod a+x /tmp/deploy_pePrep ;

        source /tmp/provision.txt ; 
        if [[ "$platforms_image" =~ rhel ]] ; then
          cat >> /tmp/deploy_pePrep << '__END'
  
          for p in initscripts chkconfig  ; do
            installPkg $p || true ;
          done ;
__END
        fi;
  
        sudo -E ${BOLTCMD:-/usr/local/bin/bolt}  script run  /tmp/deploy_pePrep -t ${deploy_petarget}    || echo "============== PE deploy_pe PrepFailed  ==============" ;     
        sudo -E ${BOLTCMD:-/usr/local/bin/bolt} --modulepath spec/fixtures/modules plan run deploy_pe::provision_master targets=${deploy_petarget} version=${deploy_peversion} || echo "==Install PE deploy_pe failed==" ;      
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
function      old_matrix_from_metadata(){
        matrix_from_metadata_v2  $@ ;
        cat ${GITHUB_OUTPUT} > ${GITHUB_OUTPUT}.tmp ;
        cat ${GITHUB_OUTPUT}.tmp | grep matrix | sed -E 's/matrix=//g' | jq -cM | head -1  | tee cat ${GITHUB_OUTPUT}.json
  
  
        cat > ${GITHUB_OUTPUT}.add  <<'__EMD'
{
  "platforms": [
    {
      "label": "OracleLinux-8",
      "provider": "vagrant",
      "image": "litmusimage/oraclelinux:8"
    },
    {
      "label": "Scientific-8",
      "provider": "vagrant",
      "image": "litmusimage/scientificlinux:8"
    }
   ]
}
__EMD
  
      echo '{  "platforms": [] }' > ${GITHUB_OUTPUT}.add ; Remove addition
  
      cat ${GITHUB_OUTPUT}.json  ${GITHUB_OUTPUT}.add |  jq -cM -s 'flatten | group_by(keys[]) | .[0][0].platforms + .[1][0].platforms | { platforms : (.) } ' \
        > ${GITHUB_OUTPUT}.newjson
  
      echo "=====================GITHUB_OUTPUT - original JSON===================="
      cat ${GITHUB_OUTPUT}.json
      echo "=====================GITHUB_OUTPUT - FINAL JSON======================="
      cat ${GITHUB_OUTPUT}.newjson
      echo "======================================================================"
  
      echo "matrix=$(cat ${GITHUB_OUTPUT}.newjson )" > ${GITHUB_OUTPUT}  ;
      grep 'spec_matrix=' ${GITHUB_OUTPUT}.tmp  >> ${GITHUB_OUTPUT}  ; 

      echo "=====================GITHUB_OUTPUT======================="
      cat ${GITHUB_OUTPUT}
      echo "========================================================="

}
function      matrix_from_metadata(){ # Switch to ofter version using the 1st parameters v1=matrix_from_metadata, v2=matrix_from_metadata_v2, v3=matrix_from_metadata_v3
       tmpexedir=/tmp  
     
       matrix_from_metadata_v1_url='https://raw.githubusercontent.com/puppetlabs/puppet_litmus/main/exe/matrix_from_metadata'
       matrix_from_metadata_v2_url='https://raw.githubusercontent.com/puppetlabs/puppet_litmus/main/exe/matrix_from_metadata_v2'
       matrix_from_metadata_v3_url='https://raw.githubusercontent.com/puppetlabs/puppet_litmus/main/exe/matrix_from_metadata_v3'
       matrix_json_url='https://raw.githubusercontent.com/puppetlabs/puppet_litmus/main/exe/matrix.json'

       matrix_from_metadataCMD2DL=""
       matrix2DL=""
       if  [[  "$@" =~ [-]*help   ]] ; then
         cat << __EMD

  =Switching to other version of matrix_from_metadata:
    -v1 = matrix_from_metadata
    -v2 = matrix_from_metadata_v2
    -v3 = matrix_from_metadata_v3
  
   --help = Show this help and call active version of matrix_from_metadata for help.
  
__EMD
       fi ;
       if [[  $1 =~ v[1-3]   ]] ; then
          case $1 in
          -v1)
            matrix_from_metadataCMD2DL=${matrix_from_metadata_v1_url}
            echo "=====================matrix_from_metadata - activated===================="
          ;;
          -v2)
            matrix_from_metadataCMD2DL=${matrix_from_metadata_v2_url}
            echo "=====================matrix_from_metadata_v2 - activated===================="
          ;;
          -v3)
            matrix_from_metadataCMD2DL=${matrix_from_metadata_v3_url}
            matrix2DL=${matrix_json_url}
            echo "=====================matrix_from_metadata_v3 - activated===================="
          ;;
          esac ;
          if [ ! -z "${matrix_from_metadataCMD2DL}" ] ; then
            ( which curl || sudo apt install -y curl 2> /dev/null  > /dev/null || sudo yum install -y curl 2> /dev/null  > /dev/null  || apt install -y curl 2> /dev/null  > /dev/null || yum install -y curl 2> /dev/null  > /dev/null ) 2> /dev/null  > /dev/null &&
            curl -q "${matrix_from_metadataCMD2DL}"  > /tmp/m.sh  2> /dev/null  || which curl ;
            chmod a+x ${tmpexedir}/m.sh ;
            matrix_from_metadataCMD=${tmpexedir}/m.sh ;
          fi;
          if [ ! -z "${matrix2DL}" ] ; then
            ( which curl || sudo apt install -y curl 2> /dev/null  > /dev/null || sudo yum install -y curl 2> /dev/null  > /dev/null  || apt install -y curl 2> /dev/null  > /dev/null || yum install -y curl 2> /dev/null  > /dev/null ) 2> /dev/null  > /dev/null &&
              curl -q "${matrix2DL}"  > ${tmpexedir}/`basename ${matrix2DL}`  2> /dev/null  || which curl ;
          fi;
          shift 1;
       fi;

    
       matrix_from_metadataCMD=${matrix_from_metadataCMD:-matrix_from_metadata_v2}
  
       
       ${matrix_from_metadataCMD}  $@ ;
       [ -z "${matrix_from_metadataCMD2DL}" ] || return ; # Do no modification if we are using v1, v2, v3 flags which means that we using an alternate version of matrix_from_metadata_v2

       
       cat ${GITHUB_OUTPUT} > ${GITHUB_OUTPUT}.tmp ;
       cat ${GITHUB_OUTPUT}.tmp | grep matrix | sed -E 's/matrix=//g' | jq -cM | head -1  | tee cat ${GITHUB_OUTPUT}.json
  

        cat > ${GITHUB_OUTPUT}.add  <<'__EMD'
{
  "platforms": [
    {
      "label": "OracleLinux-8",
      "provider": "vagrant",
      "image": "litmusimage/oraclelinux:8"
    },
    {
      "label": "Scientific-8",
      "provider": "vagrant",
      "image": "litmusimage/scientificlinux:8"
    }
   ]
}
__EMD
  
        cat > ${GITHUB_OUTPUT}.add  <<'__EMD'
{
  "platforms": [
    {
      "label": "OracleLinux-8",
      "provider": "vagrant",
      "image": "litmusimage/oraclelinux:8"
    }
   ]
}
__EMD
  
      # echo '{  "platforms": [] }' > ${GITHUB_OUTPUT}.add ; # Remove addition
  
      cat ${GITHUB_OUTPUT}.json  ${GITHUB_OUTPUT}.add |  jq -cM -s 'flatten | group_by(keys[]) | .[0][0].platforms + .[1][0].platforms | { platforms : (.) } ' \
        > ${GITHUB_OUTPUT}.newjson
  
      echo "=====================GITHUB_OUTPUT - original JSON===================="
      cat ${GITHUB_OUTPUT}.json
      echo "=====================GITHUB_OUTPUT - FINAL JSON======================="
      cat ${GITHUB_OUTPUT}.newjson
      echo "======================================================================"
  
      echo "matrix=$(cat ${GITHUB_OUTPUT}.newjson )" > ${GITHUB_OUTPUT}  ;
      grep 'spec_matrix=' ${GITHUB_OUTPUT}.tmp  >> ${GITHUB_OUTPUT}  ; 

      echo "=====================GITHUB_OUTPUT======================="
      cat ${GITHUB_OUTPUT}
      echo "========================================================="

}
    
function      preinstallpecommands(){ # Filed under provision_environment__task
        sshverbose="-vvvvvv" ;         sshverbose="" ;

        echoMsg '__' "Cleanse or Reset the SSh Client and config"
        ssh-keygen -R [127.0.0.1]:2222 ;
        cat   $HOME/.ssh/known_hosts >  $HOME/.ssh/known_hosts.bak   ; grep -F '[127.0.0.1]:2222'  $HOME/.ssh/known_hosts.bak   >  $HOME/.ssh/known_hosts
        
        echo ;
        if [ -z "$VALENTEHOME"  ] ; then
          ( sudo apt install -y curl || sudo yum install -y curl || apt install -y curl || yum install -y curl ) &&
          curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/v.sh   || which curl  ;
          source /tmp/v.sh  loadlib  ;
        else
          curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/v.sh   || which curl  ;
          source /tmp/v.sh  loadlib  ;
        fi;
        echo ;
        echoMsg '!!' "Preparing the System for Vagrant or Docker, depends on situation" ;
        pkgs='git git-core zlib* zlib*-dev g++     patch                    libyaml* libffi-dev       libffi*dev          make bzip2 autoconf automake libtool bison curl cmake ruby-dev wget sshpass';
        snappkgs='snapd' ;
        vagrantpkgs='vagrant virtualbox virt-manager build-essential ruby-full ruby-all-dev libvirt-dev ' ;
        echo "=====Pkgs=${pkgs}=============" ;
        [ ! -z "$VALENTEHOME"  ] || installPkg $pkgs  || true ;
        echo "=====Vagrant Pkgs=${vagrantpkgs}=============" ;
        [ ! -z "$VALENTEHOME"  ] || installPkg $vagrantpkgs || true ;
        echo "=====Snap Pkgs=${snappkgs}=============" ;
        [ ! -z "$VALENTEHOME"  ] || installPkg $snappkgs  || true ;
        vagrant plugin install vagrant-libvirt   || true ;
        vagrant plugin list   || true ;
  
        if [  -z "$VALENTEHOME"  ] ; then
          echoMsg '__' 'Repo Setup: apt.releases.hashicorp.com'
          wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg ;
          echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list ; 
          echoMsg '__' "Repo Setup: apt.releases.hashicorp.com : sudo apt install ${vagrantpkgs}"
          sudo apt update && sudo apt install ${vagrantpkgs} ;  
        fi;
   
        #VAGRANTRUN=$VAGRANTRUN installgems
        echoMsg '__' "/home/runner setup"
        if [  -z "$VALENTEHOME"  ] ; then
          mkdir -p /home/runner/.ssh ; sudo chmod 777 -R /home/runner/work 2> /dev/null || chmod 777 -R /home/runner/work 2> /dev/null ; touch /home/runner/.ssh/known_hosts ; touch  ~/.ssh/known_hosts ;
          ls -ld home/runner/work ; ls -l home/runner/work/* ;
        fi;
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
          ${BOLTCMD} script run -t ssh_nodes ./spec/support/acceptance/vhelper.sh ;
          ${BOLTCMD} command run -t ssh_nodes "bash /tmp/v.sh exec installPkg curl " ;
        elif [ "vagrant" =  "$provisioner" ] ; then
          echo "=======VAGRANT RUN=======" ;
          # gem uninstall  -x --force -q bolt ;
          [ -e /tmp/myownkey ] || \
            ssh-keygen -t ed25519 -f /tmp/myownkey      -P '' ; grep -H -n -v -E 'AALINEAANUMBER'  /tmp/myownkey* ;
          echo "===Proposed Changes===" ;
          cat ./spec/fixtures/litmus_inventory.yaml | yq  '.groups[].targets[].config.ssh.private-key="/tmp/myownkey"' | tee ./spec/fixtures/litmus_inventory.yaml.proposed | grep -H -n -v -E 'AALINEAANUMBER' ;
          echo "=============================================================" ;
  
          vagrantdir=`vagrant global-status | grep default | grep running  | grep servicenow | cut -d\  -f8` || true ;
          echo "===vagrantdir=$vagrantdir=";
          pushd $PWD ;
          cd ${vagrantdir} ;
          echo "===In PWD=$(pwd)" ;
  
          vagrantsshkeys_ed25519=`vagrant ssh-config | grep IdentityFile | grep key.ed ` ;
          ls -l ${vagrantsshkeys:-NO_vagrantsshkeys_ed25519} ||  true ;
          vagrantsshkeys_rsa=`vagrant ssh-config | grep IdentityFile | grep key.rsa ` ;
          ls -l ${vagrantsshkeys:-NO_vagrantsshkeys_rsa} ||  true ;
          popd ;
  
          if [  -z "$VALENTEHOME"  ] ; then
            ls -l /home/runner/.vagrant.d/insecure_private_keys/vagrant.key.ed25519 ;
            ls -l /home/runner/.vagrant.d/insecure_private_keys/ ;
            pwd ; ls -l ; ls -l /home/runner/.vagrant.d/ ; 
          fi;

          vagrant global-status ;
          OLDCWD=$(pwd) ;
          echo "=====vagrant ssh default===========" ;
          pushd `pwd` ; ls -l spec/fixtures/.vagrant/* ; cd spec/fixtures/.vagrant/* ;pwd ;
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
          
          if [  -z "$VALENTEHOME"  ] ; then
            echo "===== ssh with vagrantkey.ed25519  ===========" ;
            ssh  -i /home/runner/.vagrant.d/insecure_private_keys/vagrant.key.ed25519 -A -oIdentitiesOnly=yes  -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} date  ||  echo "FAIL: ssh with vagrantkey..."  ;
            echo "===== ssh with vagrantkey.rsa  ===========" ;
            ssh  -i /home/runner/.vagrant.d/insecure_private_keys/vagrant.key.rsa -A -oIdentitiesOnly=yes  -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} date  ||  echo "FAIL: ssh with vagrantkey..."  ;
          fi;
  
          echo "===== ssh with /tmp/myownkey ===========" ;
          ssh  -i /tmp/myownkey -A -oIdentitiesOnly=yes  -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} date  ||  echo "FAIL: ssh with /tmp/myownkey..."  ;
          echo "SKIPPED ======ssh puppet install====================" ;
          echo SKIPPED ssh  -i /tmp/myownkey -A -oIdentitiesOnly=yes  -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} "sudo apt install -y puppet"  "||"  echo "FAIL: ssh puppet install..."  ;
          echo "==========================" ;
        else
          echo "=======SKIPPED COS Unsupported provisioner: $provisioner =======" ;
        fi ;
  
        echo “Config Hostsname on the Runner”
        puppet resource host   `puppet config print certname`  ip=127.0.0.1 || echo  "127.0.0.1 `puppet config print certname` `puppet config print certname`" | sudo tee -a  /etc/hosts > /dev/null || true
        puppet resource host   puppet  ip=127.0.0.1 || echo  "127.0.0.1 puppet puppet" | sudo tee -a  /etc/hosts > /dev/null || true
        puppet resource host   `puppet config print certname`  ip=127.0.0.1 || echo  "127.0.0.1  `puppet config print certname`  `puppet config print certname`" | sudo tee -a  /etc/hosts > /dev/null || true
        puppet resource host   `hostname`.delivery.puppetlabs.net  ip=127.0.0.1 || echo  "127.0.0.1 `hostname`.delivery.puppetlabs.net   `hostname`.delivery.puppetlabs.net " | sudo tee -a  /etc/hosts > /dev/null || true
        puppet resource host   rhel7.localdomain  ip=127.0.0.1 || echo  "127.0.0.1 rhel7.localdomain   rhel7.localdomain " | sudo tee -a  /etc/hosts > /dev/null || true
        puppet resource host   rhel8.localdomain  ip=127.0.0.1 || echo  "127.0.0.1 rhel8.localdomain   rhel8.localdomain " | sudo tee -a  /etc/hosts > /dev/null || true
        puppet resource host   rhel9.localdomain  ip=127.0.0.1 || echo  "127.0.0.1 rhel9.localdomain   rhel9.localdomain " | sudo tee -a  /etc/hosts > /dev/null || true
        puppet resource host   oracle7.localdomain  ip=127.0.0.1 || echo  "127.0.0.1 oracle7.localdomain   oracle7.localdomain " | sudo tee -a  /etc/hosts > /dev/null || true
        echo "================="
        sudo grep -H -n -v -E 'AALINEAANUMBER' /etc/hosts || true
        echo "================="
        sudo grep -H -n -v -E 'AALINEAANUMBER' /etc/hostname || true
        echo "================="
}
function      installpecommands(){  # Filed under install_agent__task
        source /tmp/v.sh  loadlib  ;
        echo "===FailSafe PE Installation, in case the original one fail===" ;
        PEVERSION='2021.7.8' ;
        pepasswd="pie$(date +%s )piepiepiepiepiepiepiepiepieP5!" ;
        puppetversion=`${BOLTCMD} command run "puppet --version" -t ssh_nodes | grep -v ' on ' ` || true ;
        primaryservername=`${BOLTCMD} command run "puppet infra status" -t ssh_nodes | grep Primary:`  || true ;
  
#        version="NOT NEEDED SO ByPassed" ; primaryservername="NOT NEEDED SO ByPassed" ;
#        if  [ -z "$version" -o -z "$primaryservername" ] ; then
#          echo "===Installing Puppet Version Installed=${PEVERSION} my way===" ;
#          apt install -y curl || yum install -y curl ;
#          curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/v.sh  2> /dev/null  ;
#          source /tmp/v.sh  loadlib ;
#
#          cleanse_dlPEConsole ;
#          echo -e "srcgitKey='/tmp/key2share'\ndisplay_local_time=true\nadminpasswd=\"$pepasswd\"" > /tmp/installPEConsole.SETVALUES.txt ;
#          touch /tmp/key2share ;
#          installPEConsole =SETVALUES= ;
#          installPEConsole - =SETVALUES==PRECHECK==UNTAR==PRECONFIG=PRECONFIG2=  ;
#          dlPEConsole check ${PEVERSION} ;
#          dlPEConsole show ${PEVERSION}  ;
#          installPEConsole 2> /dev/null  > /dev/null ;
#        fi ;
        oldDIR="$PWD" ;
        cd ./spec/fixtures/ ;
        puppetversion=`${BOLTCMD} command run "puppet --version" -t ssh_nodes | grep -v ' on '` || true ; 
        echo "===Puppet Version Installed=${puppetversion}===" || true ;
        primaryservername=`${BOLTCMD} command run "puppet infra status" -t ssh_nodes | grep Primary:`  || true ;
        echo "===Puppet Server Name=${primaryservername}==="

        echoMsg '!!' 'Prepare Primary server aka ssh_nodes for tests: Access Keys' ;
        ${BOLTCMD} command run "echo pepasswd='$pepasswd' > /tmp/p.txt" -t ssh_nodes  ;
        ls -l ${oldDIR}/spec/support/acceptance/install_pe.sh ;
        ${BOLTCMD} script run ${oldDIR}/spec/support/acceptance/install_pe.sh -t ssh_nodes  ;
}
function      prepcommand1a(){ # Filed under install_module__task
        chmod 777 -R /home/runner/work 2> /dev/null || sudo chmod 777 -R /home/runner/work  2> /dev/null ||  true ;
        ls -l -d /home/runner/work  ||  true ;
        ls -l    /home/runner/work/*  ||  true ;
}
function      prepcommand1b(){ # Filed under install_module__task
        cd ./spec/fixtures/ ;
        puppetversion=`${BOLTCMD} command run "puppet --version" -t ssh_nodes | grep -v ' on '`  || true ; 
        echo "===Puppet Version Installed=${puppetversion}===" || true ;
        primaryservername=`${BOLTCMD} command run "puppet infra status" -t ssh_nodes | grep Primary:`  || true ;
        echo "===Puppet Server Name=${primaryservername}==="
  
        if [[ $puppetversion =~ failed  ]] ; then
          
          echoMsg '!!'  Fixing Missing Puppet Command
          
          cat > /tmp/psetup.sh << '__END'
    echo "====================Fix with Path env"
  whichpuppet=`which puppet`
  if [ -z "${whichpuppet}" ] ; then
    find /opt/puppetlabs  -iname puppet -type f  -maxdepth 4 | grep bin | grep -v bolt | while read whichpuppetposs ; do
      echo "===================Trying ${whichpuppetposs}"
      (puppet --version && puppet infra --help > /dev/null &&  puppet access login --help  > /dev/null ) || 
      (
        export PATH="$(dirname  ${whichpuppetposs:-/usr/bin/ls} ):$PATH" &&  \
        ( 
          (puppet --version && puppet infra console_password --help > /dev/null &&  puppet access login --help  > /dev/null ) \
                && 
          echo "export PATH=$(dirname  ${whichpuppetposs:-/usr/bin/ls} ):\$PATH" | tee -a $HOME/.profile >> $HOME/.bashrc  && echo "Added ${whichpuppetposs:-/usr/bin/ls} to env:PATH and  $HOME/.bashrc "  
        )  \
        || echo FAIL in getting puppet in the Path of $PATH 
      ) ;
    done || true ;
  fi ;
  
  echo "====================Fix with Links"
  
  if [ ! -x /usr/bin/puppet -a -d /usr/bin/ ] ; then # First Try Create a link
    pushd $PWD ; 
    cd /usr/bin/ ;
    sudo ln -sf /opt/puppetlabs/bin/puppet || ln -sf /opt/puppetlabs/bin/puppet  || true ;
    popd  ;
  fi;
  
  lastdirinPath1=$(echo $PATH | tr ':' '\n' | tail -1 ) || true ;
  if  which puppet  2> /dev/null > /dev/null ; then 
    which puppet ;
  else
    pushd $PWD ;
    cd ${lastdirinPath1} ;
    echo "In $PWD ===ln -sf /opt/puppetlabs/bin/puppet" ;
    sudo ln -sf /opt/puppetlabs/bin/puppet || ln -sf /opt/puppetlabs/bin/puppet || true ;
    popd ;
  fi
  
  
  lastdirinPath2=`sudo which puppet 2> /dev/stdout |  cut -d\( -f2  | awk -F':' '{print $NF}' | tr -d \) `  || true ;
  if sudo which puppet  2> /dev/null > /dev/null ; then 
    sudo which puppet ;
  else
    pushd $PWD ;
    cd ${lastdirinPath2} ;
    echo "In $PWD ===ln -sf /opt/puppetlabs/bin/puppet" ;
    sudo ln -sf /opt/puppetlabs/bin/puppet || ln -sf /opt/puppetlabs/bin/puppet  || true ;
    popd ;
  fi
  
  
  if [ ! -x /usr/bin/puppet ] ; then  # Second Try Create a script
    ( cat | sudo tee /usr/bin/puppet ) << EE
  export PATH=$PATH:\$PATH ;
  /opt/puppetlabs/bin/puppet \$@  ;
EE
    sudo chmod a+x /usr/bin/puppet ;
  fi ;

    
  grep -H -n -v -E 'AALINEAANUMBER' $HOME/.profile  $HOME/.bashrc
  
  echo Msg '__' PATH
  source $HOME/.bashrc
  echo -e "\n\nPATH=$PATH  \n\t puppet cmd in path Test with version $(puppet --version)"
  echo Msg '!!'
__END
          chmod a+x /tmp/psetup.sh ;
          ${BOLTCMD} script run  /tmp/psetup.sh  -t ssh_nodes   || true ; 
          
        fi;
        
        echoMsg '__'  Final Confirmation
        puppetversion=`${BOLTCMD} command run "puppet --version" -t ssh_nodes | grep -v ' on '`  || true ; 
        echo "===Puppet Version Installed=${puppetversion}===" || true ;
        primaryservername=`${BOLTCMD} command run "puppet infra status" -t ssh_nodes | grep Primary:`  || true ;
        echo "===Puppet Server Name=${primaryservername}==="
        whichpuppet=`${BOLTCMD} command run "which puppet" -t ssh_nodes | grep -v ' on ' `  || true ;
        whichpuppetsudo=`${BOLTCMD} command run "sudo which puppet" -t ssh_nodes | grep -v ' on ' `  || true ;
        lspuppet=`${BOLTCMD} command run "sudo ls -l /usr/bin/puppet " -t ssh_nodes | grep -v ' on ' `  || true ;
        echo -e "===Which Puppet=\n\twhich=${whichpuppet}\n\tsudo which=${whichpuppetsudo}\n\tsudo ls -l /usr/bin/puppet=${lspuppet}="
 
}
function      setupServiceNowServer(){ # Filed under acceptance
 
        echoMsg '__' "Pre-Checking Inventory files......."    ;
        ls -l $PWD/inventory.yaml || true ;
        ls -l $PWD/spec/fixtures/litmus_inventory.yaml || true ;

        [ ! -e $PWD/inventory.yaml ] && echo -e "---\ngroups: []" > $PWD/inventory.yaml || true ;
        [ -e $PWD/inventory.yaml  -a ! -e $PWD/spec/fixtures/litmus_inventory.yaml  ] && ln -sf $PWD/inventory.yaml $PWD/spec/fixtures/litmus_inventory.yaml  || true ;
        grep -H -n -v -E 'AALINEAANUMBER' ./spec/fixtures/litmus_inventory.yaml || true ;  
        echoMsg '__'
  
        source /tmp/provision.txt ; 
        if [ -z "$platforms_image" ] ; then
          platforms_image=`grep platform:  ./spec/fixtures/litmus_inventory.yaml     ` ;
        fi;
        set | grep -E '^platforms_image=' ;

        bundle install ;
        echoMsg '!!' "Creating ServiceNow Server......."    ;
        aptcmd=`which apt` ;
  
        grep servicenow_instance ./spec/fixtures/litmus_inventory.yaml || true
        if [  -z  "$(grep servicenow_instance ./spec/fixtures/litmus_inventory.yaml )" ]    ; then
          if [[  $platforms_image =~ buntu ]]    ; then
            export sss_location="Inside Primary Server as a container:" ;
            echoMsg '__' "Inside Primary Server as a container: Creating ServiceNow Server......."    ;
            # [ ! -z  "$(grep servicenow_instance ./spec/fixtures/litmus_inventory.yaml )" ] || 
            bundle exec 'rake acceptance:setup_servicenow_instance' || true ;
          else
            export sss_location="Inside GitHub Runner as a container:" ;
            echoMsg '__' "Inside GitHub Runner as a container: Creating ServiceNow Server......."    ;
            # [ ! -z  "$(grep servicenow_instance ./spec/fixtures/litmus_inventory.yaml )" ] || 
            bundle exec 'rake valentepuppet:setup_servicenow_host' || true  ;
            
          fi ;
        fi
        grep servicenow_instance ./spec/fixtures/litmus_inventory.yaml || echo "STILL No servicenow_instance in  ./spec/fixtures/litmus_inventory.yaml " ;
        
        cat ./spec/fixtures/litmus_inventory.yaml | sed -E 's/2222:1080/1080/g' > ./spec/fixtures/litmus_inventory.yaml.tmp   || true ;
        cat ./spec/fixtures/litmus_inventory.yaml.tmp > ./spec/fixtures/litmus_inventory.yaml ; rm -fr ./spec/fixtures/litmus_inventory.yaml.tmp   || true ;
  
        servicenowserver="localhost" # "coy.servicenow"
        servicenowserverIP="127.0.0.1"
        provisioner=$( cat ./spec/fixtures/litmus_inventory.yaml | yq -e '.groups[]|select( .name == "ssh_nodes" )|.targets.[0].facts.provisioner' ) ;
        if [ "vagrant" =  "$provisioner" ] ; then
          if [[  $platforms_image =~ buntu ]]    ; then
            servicenowserverIP="127.0.0.1" ;
            servicenowserver="localhost" ;
          else
            servicenowserverIP="10.0.2.2" ; # Wrong Config
            
            servicenowserverIP="127.0.0.1" ; # Revert
            servicenowserver="localhost" ;  # Revert
          fi ;
        fi;
        puppet resource host   ${servicenowserver}  ip=${servicenowserverIP} || echo  "${servicenowserverIP}  ${servicenowserver}    ${servicenowserver} " | sudo tee -a  /etc/hosts > /dev/null || true
        ${BOLTCMD} command run -t ssh_nodes "puppet resource host   ${servicenowserver}  ip=${servicenowserverIP} || echo  '${servicenowserverIP}  ${servicenowserver}    ${servicenowserver} ' | sudo tee -a  /etc/hosts > /dev/null" || true ;
  
        bundle exec "rake valentepuppet:test_servicenow_host[${servicenowserver}]"  || true
}
function      command(){ # Filed under acceptance
        checkno=$((${checkno:-0} + 1 )) ;
        source /tmp/v.sh  loadlib  ;
        echoMsg '!!' "Running the actual Acceptance Tests" || echo "============================Running the actual Acceptance Tests============================== " ;
        
        export LC_ALL="en_US.UTF-8" ;
  
        mkdir -p /etc/puppetlabs/puppet ;
        touch /etc/puppetlabs/puppet/servicenow_cmdb.yaml || true ;
        sudo chmod a+rw /etc/puppetlabs/puppet/servicenow_cmdb.yaml || chmod a+rw /etc/puppetlabs/puppet/servicenow_cmdb.yaml || true ;
        sudo chmod -R a+rw /etc/puppetlabs/puppet || chmod -R a+rw/etc/puppetlabs/puppet || true ;
  
        echoMsg '==' Preparing PE Server 
        bundle update ;
        bundle install ;
        #bundle exec 'rake --tasks' ;
        bundle install ;
        bundle exec 'rake acceptance:setup_pe_p2' ;

        echoMsg '==' Starting Servicenow Server 
        setupServiceNowServer 2>&1  > /tmp/sss.txt ||  true ; 
        cat /tmp/sss.txt; 

        echo "============================After Update from setup_servicenow_instance " ;
        provisioner=$( cat ./spec/fixtures/litmus_inventory.yaml | yq -e '.groups[]|select( .name == "ssh_nodes" )|.targets.[0].facts.provisioner' ) ;
        
        servicenowserver="localhost" # "coy.servicenow"
        servicenowserverIP="127.0.0.1"
        
        if [ "docker" =  "$provisioner" ] ; then
          echoMsg '!!' "Adjustment for Docker" ;
        elif [ "vagrant" =  "$provisioner" ] ; then
          echoMsg '!!' "Adjustment for Vagrant" ;
          echoMsg '++' "    Original" ;
          grep -H -n -v -E 'AALINEAANUMBER' ./spec/fixtures/litmus_inventory.yaml ;
          echo "127.0.0.1 master ${pehostnameinservicenow}" | sudo tee -a /etc/hosts ;
          echo
          echo
          cat ./spec/fixtures/litmus_inventory.yaml | sed -E 's/2222:1080/1080/g'  > /dev/null ;
          cat ./spec/fixtures/litmus_inventory.yaml | sed -E 's/ [^ :]+:2222:1080/ localhost:1080/g'   > ./spec/fixtures/litmus_inventory.yaml.NEW ;
       
          source /tmp/provision.txt ; 
          if [[  $platforms_image =~ buntu ]]    ; then
            
            servicenowserverIP="127.0.0.1" ;
            servicenowserver="localhost" ;
            
          else
            servicenowserverIP="10.0.2.2" ; # Wrong Config
            
            servicenowserverIP="127.0.0.1" ; # Revert
            servicenowserver="localhost" ;  # Revert
          fi ;
          
          cat ./spec/fixtures/litmus_inventory.yaml.NEW > ./spec/fixtures/litmus_inventory.yaml.TMP ; \
            cat ./spec/fixtures/litmus_inventory.yaml.TMP | \
              sed -E "s/name: ([^:]+)(:2222)/name: ${pehostnameinservicenow}\2/g" | \
              sed  -E "s/uri: ([^:]+)(:2222)/uri: ${pehostnameinservicenow}\2/g"  | \
              \
              sed  -E "s/ [^:]+:1080/ ${servicenowserver}:1080/g"   \
                > ./spec/fixtures/litmus_inventory.yaml.NEW ;
          
          #  cat ./spec/fixtures/litmus_inventory.yaml.TMP | sed -E 's/name: ([^:]+:2222)/name: master/g' | sed  -E "s/uri: 127.0.0.1:2222/uri: ${pehostnameinservicenow}/g" | sed  -E "s/host: 127.0.0.1/host: ${pehostnameinservicenow}/g"  > ./spec/fixtures/litmus_inventory.yaml.NEW ;
          
          cat ./spec/fixtures/litmus_inventory.yaml.NEW > ./spec/fixtures/litmus_inventory.yaml ; 
          #rm -fr ./spec/fixtures/litmus_inventory.yaml.NEW ;
        else
          echo "=======SKIPPED Adjustment COS Unsupported provisioner: $provisioner =======" ;
        fi ;
          
        echoMsg '__' "Required ${checkno} : Inventory Checks: PE server name/uri should be example.puppet.com ";  checkno=$((${checkno:-0} + 1 )) ;
        echoMsg '++' "    In Use" ;
        grep -H -n -v -E 'AALINEAANUMBER' ./spec/fixtures/litmus_inventory.yaml ;
        
        echoMsg '__' "Required ${checkno} : IP address of nodes are...";  checkno=$((${checkno:-0} + 1 )) ;
        echo "===On Runner"
        echoMeNRun ip addr || echo "IP addr Failed..." ;
        echo "===On Nodes"
        ${BOLTCMD} command run "ip addr" -t all |  tee /tmp/ip.txt   || echo "ip addr on nodes" ;  
        masterip=`cat /tmp/ip.txt | grep 10.0.2 | sed -E 's/^.+ (10.0.2.[^\/]+)\/.+$/\1/g'` ;
        
        #### Hardcoded for now
        source /tmp/provision.txt || true ;
         if [ -z "$platforms_image" ] ; then
           platforms_image=`grep platform:  ./spec/fixtures/litmus_inventory.yaml     ` ;
         fi;

         echoMsg '__' "Required ${checkno} : Platform Checks, Make sure Ports are fwded correctly -L:1080...for Ubuntu ... for others";  checkno=$((${checkno:-0} + 1 )) ;
         if [[  $platforms_image =~ buntu ]]    ; then
          portsfwdOptions="-L:8140:127.0.0.1:8140 -L:8143:127.0.0.1:8143 -L:1080:127.0.0.1:1080" ;
        else
          portsfwdOptions="-L:8140:127.0.0.1:8140 -L:8143:127.0.0.1:8143 -R:1080:${servicenowserverIP:-localhost}:1080" ; # -R:1080
        fi ;
        set | grep -E '^platforms_image=|^portsfwdOptions=' ;

        masterip=${deploype_ip} ;
        echoMsg '++'    ;
        set | grep -E 'masterip=|_port=|_ip=|^deploype|ipaddrport=|^deploy' | grep -v '^ ' ;
        echoMsg '++'    ;
        ssh  -i /tmp/myownkey -A -oIdentitiesOnly=yes  -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} ${portsfwdOptions} "grep -H -n -v -E 'AALINEAANUMBER' /etc/puppetlabs/puppet/puppet.conf"  ;
        echoMsg '++'    ;
        echoMsg '!!' "Activating the Port Fwding: ${portsfwdOptions}  "    ;
        ssh  -i /tmp/myownkey -A -oIdentitiesOnly=yes  -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} ${portsfwdOptions} "touch /tmp/proxy.txt"  ; sleep 3 ;
        ssh  -i /tmp/myownkey -A -oIdentitiesOnly=yes  -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 ${sshverbose} -p${deploype_port} -l vagrant ${deploype_ip} ${portsfwdOptions} "while [ -e /tmp/proxy.txt ] ; do sleep 30 ; done ;  "  &
        sleep 10 ;
        #### 
  
        conncheckscript=/tmp/conncheckscript.sh ; touch $conncheckscript  ; chmod a+x $conncheckscript ;
        echo '#!/bin/bash' > $conncheckscript
        cat > $conncheckscript << '__EEE'
  apt install -y curl || yum install -y curl || sudo apt install -y curl || sudo yum install -y curl  ;
  curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/download_pe_tarball.sh ;
  source /tmp/download_pe_tarball.sh  loadlib ;
          
          installPkg netcat
__EEE

  
        
        cat ./spec/fixtures/litmus_inventory.yaml | grep uri | sed -E 's/^[^:]+://g' | while read ipaddrport ; do 
          masterip=${ipaddrport/:*/} ;
          masterport=${ipaddrport/*:/} ;
          echoMsg '__' "Required ${checkno} : Connection Checks Verify URL and ports to ${masterip} from GitHub Runner";  checkno=$((${checkno:-0} + 1 )) ;
          echo "ping_NC_Test ${masterip}  tcp ${masterport}:boltinvconnectport ${ping_NC_Test_TESTTARGETS} ;"| tee  -a $conncheckscript ;
          ping_NC_Test ${masterip}       tcp ${masterport}:boltinvconnectport ${ping_NC_Test_TESTTARGETS}  || echo "ping_NC_Test Failed..." ;
          echo "${checkno}" > /tmp/checkno.txt
        done ;
        
        echo "echo '=============Curl Check on ${servicenowserver}:1080========';curl -k \"https://${servicenowserver}:1080\" 2>&1 ; curl -v \"https://${servicenowserver}:1080\" 2>&1 ;"  | tee  -a $conncheckscript ;
          
        checkno=`cat /tmp/checkno.txt`; rm -fr /tmp/checkno.txt ;
        echoMsg '__' "Required ${checkno} : Connection Checks Verify URL and ports to all nodes from PE Console";  checkno=$((${checkno:-0} + 1 )) ;
        ${BOLTCMD} script run -t ssh_nodes $conncheckscript || true ;

        echoMsg '__' "Required ${checkno} : Current User Test runner and the hosts file on Runner" ; checkno=$((${checkno:-0} + 1 )) ;
       
        whoami ;
        catMe /etc/hosts ;

        echoMsg '__' "Required ${checkno} : Current User Test runner and the hosts file on PE Primary" ; checkno=$((${checkno:-0} + 1 )) ;
        ${BOLTCMD} command run " whoami ; grep -H -n -v -E 'AALINEAANUMBER' /etc/hosts ; df  ;           " -t ssh_nodes | grep -v ' on ' || true ;
        
  
        echoMsg '__' "Required ${checkno} : Mock ServiceServer Check" ; checkno=$((${checkno:-0} + 1 )) ;
        bundle exec "rake valentepuppet:test_servicenow_host[${servicenowserver}]"  || true ;
        echoMsg '__' ;

        echoMsg '__' "Required ${checkno} : PE Server Check" ;  checkno=$((${checkno:-0} + 1 )) ;
        puppetversion=`${BOLTCMD} command run "puppet --version" -t ssh_nodes | grep -v ' on ' ` || true ; 
        echo "===Puppet Version Installed=${puppetversion}===" || true ;
        primaryservername=`${BOLTCMD} command run "puppet infra status" -t ssh_nodes | grep Primary:`  || true ;
        echo "===Puppet Server Name=${primaryservername}==="
        whichpuppet=`${BOLTCMD} command run "which puppet" -t ssh_nodes | grep -v ' on ' `  || true ;
        whichpuppetsudo=`${BOLTCMD} command run "sudo which puppet" -t ssh_nodes | grep -v ' on ' `  || true ;
        lspuppet=`${BOLTCMD} command run "sudo ls -l /usr/bin/puppet " -t ssh_nodes | grep -v ' on ' `  || true ;
        echo -e "===Which Puppet=\n\twhich=${whichpuppet}\n\tsudo which=${whichpuppetsudo}\n\tsudo ls -l /usr/bin/puppet=${lspuppet}="
        
  
        ${BOLTCMD} command run -t ssh_nodes 'echo "====PUPPETTOKEN===="; ls -l ~/.puppetlabs/token ;  echo "====PUPPET INFRA STATUS===="; puppet infra status ;' ||  true ;
        echoMsg '__' ;
  
        echoMsg '++' Original $HOME/.ssh/known_hosts ;
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
          ssh -i /tmp/myownkey -A -oIdentitiesOnly=yes  -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10  -p${masterport} -l vagrant ${masterip} "echo Working:  vagrant@${masterip}:${masterport}" || echo "Failed:  vagrant@${masterip}:${masterport} ;
          ssh -i /tmp/myownkey -A -oIdentitiesOnly=yes  -oTCPKeepAlive=yes -oServerAliveInterval=10  -p${masterport} -l vagrant ${masterip} "echo Working HostChecked:  vagrant@${masterip}:${masterport}" || echo "Failed HostChecked:  vagrant@${masterip}:${masterport} ;
        done ;
        echoMsg '!!'    ;
        echo     > $HOME/.ssh/known_hosts ;

        echoMsg '++' Adapted $HOME/.ssh/known_hosts ;
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
        scp -i /tmp/myownkey -A -oIdentitiesOnly=yes  -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 -P${masterport:-2222}   pkg/*.tar.gz  vagrant@${masterip}:/tmp ;
        ssh -i /tmp/myownkey -A -oIdentitiesOnly=yes  -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10 -p${masterport:-2222} -l vagrant ${masterip} "ls -l /tmp/${btarfile} ; sudo puppet module install /tmp/${btarfile} ; " ;
        echoMsg '!!'  ;

        echo ;
        echo ;
        (sleep 3600 && ssh  -i /tmp/myownkey -A -oIdentitiesOnly=yes  -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10  -p${deploype_port} -l vagrant ${deploype_ip}  "rm -fr  /tmp/proxy.txt"  ) &
        echoMsg '==' "Setup done, Now Run Tests"  ;
        bundle exec "rake acceptance:run_tests" ; errorid=$? ;
        echo "rake acceptance:run_tests done with errid=$errorid " ;
        exit $errorid ;
}

function      postcommand(){ # Filed under tear_down__task
        
        #### Hardcoded for now 
        ssh  -i /tmp/myownkey -A -oIdentitiesOnly=yes  -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oTCPKeepAlive=yes -oServerAliveInterval=10   -p${deploype_port} -l vagrant ${deploype_ip}  "rm -fr  /tmp/proxy.txt"  ;
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
  return $errorid 2> /dev/null || true ; 
  exit $errorid ;
fi;
exit
=end
}
# lint:endignore
# rubocop:enable all
