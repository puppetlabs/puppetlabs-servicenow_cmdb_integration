#!/bin/bash

pepasswd_def=pie$(date +%s )piepiepiepiepiepiepiepiepieP5!

if [ -e /tmp/p.txt ] ; then
  source /tmp/p.txt ;
fi
pepasswd=${pepasswd:-$pepasswd_def}

primaryservername=`puppet infra status | grep Primary:` ||  true ;
echo "===Puppet Server Name=${primaryservername}==="

version=`puppet --version`  ||  true ;
echo "===Puppet Version Installed=${version}==="

apt install -y curl || yum install -y curl ;
curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/download_pe_tarball.sh ;
source /tmp/download_pe_tarball.sh  loadlib ;

upgradePkg

installPkg dnf
for p in \
        initscripts chkconfig libldap curl cron crontabs gnupg  gnupg2 gnupg1 \
        ruby-devel.x86_64 ruby-bundler ruby-all-dev ruby-dev ruby-full \
        git git-core zlib* zlib*-dev g++     patch                    \
        libyaml* libffi-dev                 make bzip2 autoconf automake\
        libtool bison curl cmake curl autoconf bison build-essential \
        libssl-dev libyaml-dev libreadline6-dev zlib1g-dev \
        libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev ; do
          
          installPkg $p || true ;
done ;
  
if [ -z "$version" -o -z "$primaryservername"  ]; then
  
  PE_RELEASE=2019.8.1
  PE_RELEASE=2023.7.0
  PE_RELEASE=""
  PE_RELEASE=2021.7.8
  
#  PE_LATEST=$(curl https://artifactory.delivery.puppetlabs.net/artifactory/generic_enterprise__local/archives/releases/${PE_RELEASE}/LATEST)
  PE_FILE_NAME=puppet-enterprise-${PE_LATEST}-ubuntu-18.04-amd64
  TAR_FILE=${PE_FILE_NAME}.tar
#  DOWNLOAD_URL=https://artifactory.delivery.puppetlabs.net/artifactory/generic_enterprise__local/archives/releases/${PE_RELEASE}/${TAR_FILE}

  ## Download PE
#   curl -o ${TAR_FILE} ${DOWNLOAD_URL}
#   

  ls -l  ${TAR_FILE}
  if [[ $? -ne 0 ]];then
    export DOWNLOAD_VERSION=${PE_RELEASE}
    export tmpDir="$PWD" ;

    
    cd $tmpDir && rm -fr ./puppet*.gz  &&   pwd && \
    cat /tmp/download_pe_tarball.sh | bash -                2>&1 |  grep -v '.... .......... ....' ;
    ls -l "./puppet*.gz"
    cp -f "./puppet*.gz" ${TAR_FILE}
    echo "Done the CURL one "
  fi ;
  ls -l ${TAR_FILE} > /dev/null 2>/dev/null


  ## Another New Way to Download

  #puppet --version

  if [[ $? -ne 0 ]];then
    
    export DOWNLOAD_VERSION=${PE_RELEASE}
    export tmpDir="$PWD" ;
    
    touch $tmpDir/occkeys

    cleanse_dlPEConsole
    cd $tmpDir && rm -fr ./puppet*.gz  &&   pwd 
    dlPEConsole_SetParameters ${PE_RELEASE} && \
    dlPEConsole ${PE_RELEASE}  | tee  /tmp/aaaa.txt
    echo "================================================================================================="
    grep -E 'puppet.+gz' /tmp/aaaa.txt | sed -E 's/^.+(puppet.+gz).+$/\1/g' | head -1
    echo "================================================================================================="
    tarfilenow=`grep -E 'puppet.+gz' /tmp/aaaa.txt | sed -E 's/^.+(puppet.+gz).+$/\1/g' | head -1 | sed -E 's/^.+puppet/puppet/g' `
    sudo chmod a+rw "${tarfilenow}" ||  chmod a+rw "${tarfilenow}"
    sudo ls -l "${tarfilenow}" || ls -l "${tarfilenow}" 
    echo sudo cp -f "$tmpDir/puppet*.gz" ${TAR_FILE} || \
    echo      cp -fv "$tmpDir/${tarfilenow}" ${TAR_FILE}
    
    TAR_FILE="${tarfilenow}"
    PE_FILE_NAME=${TAR_FILE/.tar.gz/}
    echo "Done the dlPEConsole one with ${tarfilenow}"  
  fi ;
  ls -l ${TAR_FILE} > /dev/null 2>/dev/null


  if [[ $? -ne 0 ]];then
    echo “Error: wget failed to download [${DOWNLOAD_URL}]”
    exit 2
  fi

  ## Install PE
  tar xvf ${TAR_FILE}
  if [[ $? -ne 0 ]];then
    echo “Error: Failed to untar [${TAR_FILE}]”
    exit 2
  fi


  stages="=SETVALUES==PRECHECK==UNTAR==SETHOCONFVALUES==PREP="
  hostname=puppet
  #echo "127.0.0.1 puppet puppet" > /etc/hosts
  cat > $tmpDir/installPEConsole.SETVALUES.txt << ___E
display_local_time=true
adminpasswd="$pepasswd"
puppet_master_host=${hostname}    
___E
  
  touch /tmp/occkeys
  
  
  
  
  
  echo installPEConsole  ${stages}

  cd ${PE_FILE_NAME}
  echo "================="
  grep -H -n -v -E 'AALINEAANUMBER' ./conf.d/pe.conf
  echo "================="
  printf 'y' | ./puppet-enterprise-installer

  
  if [[ $? -ne 0 ]];then
    echo “Error: Failed to install Puppet Enterprise. Please check the logs and call Bryan.x ”
    exit 2
  fi
fi

  ## Finalize configuration
  
  # puppetcmd=`find /opt/puppetlabs  -iname puppet -type f  -maxdepth 4 | grep bin | grep -v bolt | head -1`
  # puppet infra --help  || echo 'export PATH='$(dirname  ${puppetcmd:-/usr/bin/ls} )':$PATH'  >> $HOME/.bashrc

  # echo "Post-Installation puppetcmd=$puppetcmd"   
  echoMsg '__' "Post-Installation"
  
  source $HOME/.bashrc
  export PATH="$(dirname  ${puppetcmd:-/usr/bin/ls} ):$PATH"
  which puppet || true

  
  
  echoMsg '!!' "Getting Path to be recognised as a command"
whichpuppet=`which puppet`
if [ -z "${whichpuppet}" ] ; then
  find /opt/puppetlabs  -iname puppet -type f  -maxdepth 4 | grep bin | grep -v bolt | while read whichpuppetposs ; do
    echo "Try ${whichpuppetposs}"
    (puppet --version && puppet infra --help > /dev/null &&  puppet access login --help  > /dev/null ) || 
    (
      export PATH="$(dirname  ${whichpuppetposs:-/usr/bin/ls} ):$PATH" &&  \
      ( 
        (puppet --version && puppet infra console_password --help > /dev/null &&  puppet access login --help  > /dev/null ) \
              && 
        echo "export PATH=$PATH" >> $HOME/.bashrc  && echo "Added ${whichpuppetposs:-/usr/bin/ls} to env:PATH and  $HOME/.bashrc "  
      )  \
      || echo FAIL in getting puppet in the Path of $PATH 
    ) ;
  done ;
fi ;

  echoMsg '__' PATH
  source $HOME/.bashrc
  echo -e "\n\nPATH=$PATH  \n\t puppet cmd in path Test with version $(puppet --version)"
  echoMsg '!!'





  which puppet || true


  echo “Config Hostsname”
  puppet resource host   `puppet config print certname`  ip=127.0.0.1 2> /dev/null || echo  "127.0.0.1 `puppet config print certname` `puppet config print certname`" >> /etc/hosts
  puppet resource host   puppet  ip=127.0.0.1 2> /dev/null || echo  "127.0.0.1 puppet puppet" >> /etc/hosts
  puppet resource host   `puppet config print certname`  ip=127.0.0.1 2> /dev/null || echo  "127.0.0.1  `puppet config print certname`  `puppet config print certname`" >> /etc/hosts
  puppet resource host   `hostname`.delivery.puppetlabs.net  ip=127.0.0.1 2> /dev/null || echo  "127.0.0.1 `hostname`.delivery.puppetlabs.net   `hostname`.delivery.puppetlabs.net " >> /etc/hosts
  puppet resource host   rhel7.localdomain  ip=127.0.0.1 2> /dev/null || echo  "127.0.0.1 rhel7.localdomain   rhel7.localdomain " >> /etc/hosts
  puppet resource host   rhel8.localdomain  ip=127.0.0.1 2> /dev/null || echo  "127.0.0.1 rhel8.localdomain   rhel8.localdomain " >> /etc/hosts
  puppet resource host   rhel9.localdomain  ip=127.0.0.1 2> /dev/null || echo  "127.0.0.1 rhel9.localdomain   rhel9.localdomain " >> /etc/hosts
  puppet resource host   oracle7.localdomain  ip=127.0.0.1 2> /dev/null || echo  "127.0.0.1 oracle7.localdomain   oracle7.localdomain " >> /etc/hosts
  echo "================="
  grep -H -n -v -E 'AALINEAANUMBER' /etc/hosts
  echo "================="
  grep -H -n -v -E 'AALINEAANUMBER' /etc/hostname
  echo "================="



  echo "====SELINUX===="
  disableSELINUX
  checkSELINUX

  echo "====FIREWALL===="
  puppet resource service firewalld ensure=stopped enable=false
  systemctl disable firewalld || sudo systemctl disable firewalld
  systemctl stop firewalld || sudo systemctl stop firewalld
  systemctl status firewalld  || sudo systemctl status firewalld
  puppet resource service firewalld

  echo "====PE-Service=Check=and=Restart====="
  puppet infra status | grep ' 0 services are fully operational' && restartCompilersReplicaServices
  puppet infra status | grep 'services are fully operational'
  
  
  echo "====SSHD_CONFIG====="
  cat /etc/ssh/sshd_config  | sed -E 's/^.+AllowTcpForwarding.+$/AllowTcpForwarding yes/g' | sed -E 's/^.+GatewayPorts.+$/GatewayPorts yes/g'  > /tmp/sshd_config ; cat /tmp/sshd_config | sudo tee /etc/ssh/sshd_config ; rm -fr   /tmp/sshd_config ;
  systemctl restart sshd ||  systemctl restart sshd 

  sudo grep -E '^AllowTcpForwarding yes' /etc/ssh/sshd_config || echo 'AllowTcpForwarding yes' | sudo tee -a /etc/ssh/sshd_config
  sudo grep -E '^GatewayPorts yes' /etc/ssh/sshd_config || echo 'GatewayPorts yes' | sudo tee -a /etc/ssh/sshd_config

  sudo grep -E 'AllowTcpForwarding|GatewayPorts' /etc/ssh/sshd_config
  
  echo “Finalize PE install”
  puppet agent -t


  puppet infra console_password --password=${pepasswd} || /opt/puppetlabs/bin/puppet infra console_password --password=${pepasswd}

  ## Create and configure Certs
  echo "autosign = true" >> /etc/puppetlabs/puppet/puppet.conf

  ## Setup the RBAC token
  echo "${pepasswd}" | puppet access login --lifetime 1y --username admin || \
  echo "${pepasswd}" | /opt/puppetlabs/bin/puppet access login --lifetime 1y --username admin

  echo "====PUPPETTOKEN===="
  ls -l ~/.puppetlabs/token

  echo "====PUPPET INFRA STATUS===="
  puppet infra status
  
version=`puppet --version`  || true
primaryservername=`puppet infra status | grep Primary:` || true


# Setup the Configure File and ensure it is writable. To prevent Error in RHEL7 and Oracle Linux
mkdir -p /etc/puppetlabs/puppet
touch /etc/puppetlabs/puppet/servicenow_cmdb.yaml
sudo chmod a+w /etc/puppetlabs/puppet/servicenow_cmdb.yaml || chmod a+w /etc/puppetlabs/puppet/servicenow_cmdb.yaml  ;

export LC_ALL="en_US.UTF-8" ;

echo 'export LC_ALL="en_US.UTF-8" ;' >> $HOME/.bashrc || true
echo 'export LC_ALL="en_US.UTF-8" ;' | sudo tee -a /root/.bashrc || true


# if [ -z "$version" -o -z "$primaryservername" ] ;  then
#   echo 'Puppet Server install failed' ;
#   exit 1 ; 
# fi
