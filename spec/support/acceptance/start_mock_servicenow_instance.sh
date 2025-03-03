#!/bin/bash

dockercmd="docker"

mkdir -p /tmp/servicenow
which curl || ( apt install -y curl || yum install -y curl  ) || true
which sudo || ( apt install -y sudo || yum install -y sudo  ) || true

curl -q "https://raw.githubusercontent.com/sooyean-hoo/pe_curl_requests/feature/SYInstallerEnhance/installer/download_pe_tarball.sh"  > /tmp/download_pe_tarball.sh   || true
source /tmp/download_pe_tarball.sh  loadlib  || true


if [  "$1" = "LOCALRUN"     ] ; then
  mkdir -p /tmp/servicenow/ ;
  echo  > /tmp/servicenow/start_mock_servicenow_instance.sh ;
fi ;



# The following Codes are only activated if you place a file @ /tmp/servicenow/start_mock_servicenow_instance.sh. And the file can be empty.
# This run the servicenow locally.
if [ -e  /tmp/servicenow/start_mock_servicenow_instance.sh ] ; then
  export tmpDir=$PWD
  
  cd /tmp/servicenow/
  sudoCMD=`which sudo`
  pushd $PWD
  
  rubyCMD=`which ruby` 
  bundleCMD=`which bundle`
  
  if [ -z "${bundleCMD}" ] ; then
    for p in ruby-devel.x86_64 ruby-bundler ruby-all-dev ruby-dev ruby-bundler   sudo  \
        git git-core zlib* zlib*-dev g++     patch                    libyaml* libffi-dev       libffi*dev          make bzip2 autoconf automake libtool bison curl cmake    ; do
      installPkg $p ;
    done ;
    touch  $HOME/.bashrc
    rungithubactionuse - ruby/setup-ruby@v1 ruby-version="2.7" bundler-cache=true ;
    source $HOME/.bashrc
  
    echo ${sudoCMD} gem install rubygems-update || echo ${sudoCMD} gem install rubygems-update -v 3.4.22
    echo ${sudoCMD} update_rubygems 
    echo ${sudoCMD} gem update --system
    
    ${sudoCMD} gem uninstall --force ffi 
    ${sudoCMD} gem install --force ffi -- --enable-libffi-alloc
  
    # bundle add  puma -v "~> 4.3.12"
    # for g in       eventmachine reel  rackup rubygems-tasks  ; do 
    #   bundle add  $g ; 
    # done ;
  fi;

  popd;
  
  bundle update
  bundle install --without development test || (  bundle config set --local without 'development test'  && bundle install )
  nohup bundle exec ruby ./mock_instance.rb 2>&1   > /tmp/mock_instance.rb.log &
  
  sleep 10 ;
  cat /tmp/mock_instance.rb.log ;
  exit $? ;
fi

function oraclelinuxrepo(){
  test -d /etc/yum.repos.d || return 404    # Exclude non Yum - Driven OS
  
      # # Adding CentOS Extras to Oracle Enterprise Linux
      # 
      # If you want to install a package like Docker Community Edition on OEL, you'll have to add the CentOS Extras repo, which as of release 7 is built-in to CentOS and not added on later like EPEL is. As a result, instructions for adding it to EL7 are hard to find. This should work for any build of Enterprise Linux that does not already include the CentOS Extras repo. I have absolutely no idea if it's apporpriate to use this repo on a build of Linux *other* than CentOS, but it should be.
      # 
      # This was tested on Oracle Enterprise Linux 7, but should be copy-pastable on any version or EL build assuming things don't change too much.
      # 
      # ## Download the CentOS GPG Key
      # 
      # ```bash
      # Get OS Release number
      OS_RELEASE=$(rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release))
      OS_RELEASE_MAJOR=$(echo $OS_RELEASE | cut -d. -f1)
      
      # Download the GPG key and save locally
      curl -s https://www.centos.org/keys/RPM-GPG-KEY-CentOS-$OS_RELEASE_MAJOR | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-$OS_RELEASE_MAJOR
      
      # ```
      ## Create the repo file
      # 
      # A bash implementation of [this stackoverflow answer](https://unix.stackexchange.com/a/52683/209779):
      # 
      # ```bash
      # Get OS Release number
      OS_RELEASE=$(rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release))
      OS_RELEASE_MAJOR=$(echo $OS_RELEASE | cut -d. -f1)
      # Create the repo file
      cat << EOF | sudo tee /etc/yum.repos.d/centos-extras.repo
#additional packages that may be useful
[extras]
name=CentOS-$OS_RELEASE_MAJOR - Extras
mirrorlist=http://mirrorlist.centos.org/?release=$OS_RELEASE_MAJOR&arch=\$basearch&repo=extras
#baseurl=http://mirror.centos.org/centos/$OS_RELEASE_MAJOR/extras/\$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-$OS_RELEASE_MAJOR
priority=1
EOF
      # ```
      
      ## Build the repo cache
      
      #```bash
      sudo yum -q makecache -y --disablerepo='*' --enablerepo='extras' || 
      (
        sudo sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo ;
        sudo sed -i s/^#.*baseurl=http/baseurl=https/g /etc/yum.repos.d/*.repo ;
        sudo sed -i s/^mirrorlist=http/#mirrorlist=https/g /etc/yum.repos.d/*.repo ;

        echo "sslverify=false" | sudo tee -a /etc/yum.conf
        sudo yum upgrade -y ;
      )
      #```
      
}
function dockerconveniencescript(){
    id=`${dockercmd} ps -q -f name=mock_servicenow_instance -f status=running`

  if [ -z "$id"    ] ; then
    ## https://docs.docker.com/engine/install/rhel/#install-using-the-convenience-script
    echoMsg '!!' Docker Not install or Running....Last Try with convenience script
    
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo yum-config-manager --save --setopt=docker-ce-stable.skip_if_unavailable=true ;
  fi;
  echo ;
  
  sudo systemctl start docker ;
  id=`${dockercmd} ps -q -f name=mock_servicenow_instance -f status=running`

  if [ -z "$id"    ] ; then
    echoMsg '!!'
    echoMsg '!!'
    echoMsg '!!' Docker Not install or Running....
    echoMsg '!!'
    echoMsg '!!'
  fi;
}
function enableDocker(){
  
  rep=$(curl -s --unix-socket /var/run/docker.sock http://ping > /dev/null )
  status=$?
  
  if [ "$status" == "7"    ] ; then
     echoMsg '!!' Docker for Ubuntu
  
      apt-get -qq update -y 1>&- 2>&-
      apt-get install -qq docker.io -y 1>&- 2>&-
      
  fi

  which apt-get && return ; ## All done for the Ubuntu and Debian
  
  rep=$(curl -s --unix-socket /var/run/docker.sock http://ping > /dev/null )
  status=$?

# SLES Version
  if [ "$status" == "7"    ] ; then
    echoMsg '!!' Docker for SLES

    zypperRepoOpts="--no-gpg-checks --gpg-auto-import-keys --non-interactive-include-reboot-patches  "
    zypperOpts="--non-interactive --no-gpg-checks --gpg-auto-import-keys --non-interactive-include-reboot-patches"
    zypperInstOpts="--force-resolution -y"
    
    sudo zypper  ${zypperRepoOpts} addrepo http://download.opensuse.org/tumbleweed/repo/oss/ OSS
    sudo zypper  ${zypperRepoOpts} addrepo http://download.opensuse.org/tumbleweed/repo/non-oss/ NON-OSS
    sudo zypper  ${zypperRepoOpts} addrepo http://download.opensuse.org/update/tumbleweed/ UPDATE
    
   sudo zypper  ${zypperRepoOpts} addrepo https://download.opensuse.org/repositories/system:snappy/openSUSE_Tumbleweed/system:snappy.repo
   sudo zypper  ${zypperRepoOpts} addrepo https://download.opensuse.org/repositories/network:im:signal/openSUSE_Tumbleweed/network:im:signal.repo
   sudo zypper  ${zypperRepoOpts} addrepo https://download.opensuse.org/repositories/hardware:razer/openSUSE_Tumbleweed/hardware:razer.repo

    sudo rpm --import  https://packages.microsoft.com/keys/microsoft.asc
    sudo zypper  ${zypperRepoOpts} addrepo https://packages.microsoft.com/yumrepos/vscode vscode
    sudo zypper  ${zypperRepoOpts} addrepo http://repo.vivaldi.com/archive/rpm/x86_64 vivaldi
    sudo zypper ${zypperOpts} refresh
    sudo zypper install ${zypperInstOpts}  snapd
    
    sudo suse_register --restore-repos
    sudo zypper ls; sudo zypper ${zypperOpts}  refresh --services  

    sudo zypper ${zypperOpts} ref -s
    
    opensuse_repo="https://download.opensuse.org/repositories/security:/SELinux/openSUSE_Factory/security:SELinux.repo"
    sudo zypper  ${zypperRepoOpts} addrepo $opensuse_repo
    echoMsg '++' "Done zypper addrepo0"
    
    
    
     sudo zypper install  ${zypperInstOpts}  docker docker-bash-completion  docker-rootless-extras iptables-backend-nft ;
     
    sudo usermod -aG docker  vagrant
    sudo usermod -aG root  vagrant
    sudo systemctl start docker ;
    
    sudo docker ps ;    
    which docker  && return ;
    
    sudo zypper remove ${zypperInstOpts}  docker \
                    docker-client \
                    docker-client-latest \
                    docker-common \
                    docker-latest \
                    docker-latest-logrotate \
                    docker-logrotate \
                    docker-engine \
                    runc || true 
      
      sudo zypper search docker  || true 
      sudo zypper ${zypperOpts} addrepo  https://download.docker.com/linux/sles/docker-ce.repo
      
    echoMsg '++' "Done zypper addrepo1"
  
#     echo pkg_gpgcheck = off  | sudo tee -a /etc/zypp/zypp.conf
#     echo repo_gpgcheck = off | sudo tee -a /etc/zypp/zypp.conf

    sudo zypper --gpg-auto-import-keys ref
    sudo zypper ls; sudo zypper ${zypperOpts}  refresh --services  

    echoMsg '++' "Done zypper addrepo2"
    yes a | sudo zypper install  ${zypperInstOpts}  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin ||   yes a | sudo zypper install ${zypperInstOpts}   docker   || true

    for p in docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin  ; do
        sudo zypper install  ${zypperInstOpts}   $p || true ;
    done ;

    sudo usermod -aG docker  vagrant
    sudo usermod -aG root  vagrant
    sudo systemctl start docker ;
    docker --help  2> /dev/null > /dev/null  || (   sudo zypper remove ${zypperInstOpts}  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin  && yes 1 | sudo zypper install  ${zypperInstOpts}  docker ) ;
    dockercmd="sudo docker" ;
    
    
    dockerconveniencescript
    
  fi; 

  


  which zypper && return ; ## All done for the SLES


  rep=$(curl -s --unix-socket /var/run/docker.sock http://ping > /dev/null )
  status=$?
  
  # Redhat Version
  if [ "$status" != "0"    ] ; then
    rep=$(curl -s  /var/run/docker.sock http://ping > /dev/null )
    status=$?
    if [ "$status" == "6"    ] ; then
      echoMsg '!!' Docker for RedHat
      
      # Enabled Extra Repo......

      # RHEL remove Extra Repo......
      grep 'Red Hat Enterprise' /etc/os-release  && sudo rm -fr /etc/yum.repos.d/centos-extras.repo
      grep 'Red Hat Enterprise' /etc/os-release  && sudo rm -fr /etc/yum.repos.d/epel-testing.repo      

      sudo yum update -y
      sudo yum search docker
      
      sudo yum remove -y docker \
                    docker-client \
                    docker-client-latest \
                    docker-common \
                    docker-latest \
                    docker-latest-logrotate \
                    docker-logrotate \
                    docker-engine \
                    podman \
                    runc
      sudo yum install -y yum-utils ; 
      
      (( sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo || sudo curl --add-repo https://download.docker.com/linux/rhel/docker-ce.repo    -o  /etc/yum.repos.d/docker-ce.repo ) &&
        sudo yum install --skip-broken --nobest  -y  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 
      )|| (
          oraclelinuxrepo ;
        # RHEL remove Extra Repo......
         grep 'Red Hat Enterprise' /etc/os-release  && sudo rm -fr /etc/yum.repos.d/centos-extras.repo
#         grep 'Red Hat Enterprise' /etc/os-release  && sudo rm -fr /etc/yum.repos.d/epel-testing.repo      
#         grep 'Red Hat Enterprise' /etc/os-release  && sudo rm -fr /etc/yum.repos.d/epel.repo      
#         sudo yum update

          
          pkgs="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" ;
      
          installPkg $pkgs || ( sudo yum-config-manager --disablerepo docker-ce-stable ; rm -f /etc/yum.repos.d/docker-ce.repo ; installPkg podman-docker  ) || ( 
          curl -O https://raw.githubusercontent.com/AlmaLinux/almalinux-deploy/master/almalinux-deploy.sh | sudo bash -  ;

          # RHEL remove Extra Repo......
         grep 'Red Hat Enterprise' /etc/os-release  && sudo rm -fr /etc/yum.repos.d/centos-extras.repo
#         grep 'Red Hat Enterprise' /etc/os-release  && sudo rm -fr /etc/yum.repos.d/epel-testing.repo      
#         grep 'Red Hat Enterprise' /etc/os-release  && sudo rm -fr /etc/yum.repos.d/epel.repo      
#         sudo yum update
          
          ( sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo || sudo curl --add-repo https://download.docker.com/linux/rhel/docker-ce.repo    -o  /etc/yum.repos.d/docker-ce.repo ) &&
           sudo yum install --skip-broken --nobest  -y  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 
          )     
       )
    fi
  fi; 

  sudo systemctl start docker  || installPkg podman-docker || true ;
  echo "Try dockerconveniencescript"
  dockerconveniencescript
}

which ${dockercmd} || enableDocker || true


# which docker || { 
#   echo "TRY LOCAL with $0  LOCALRUN" ;
#   nohup $0  LOCALRUN  > /tmp/mock_servicenow_instance.log & 
#   sleep 3 ;
#   echo HELO | curl -q "telnet://127.0.0.1:1080" ;
#   exit $? ;
# }


function cleanup() {
  # bolt_upload_file isn't idempotent, so remove this directory
  # to ensure that later invocations of the setup_servicenow_instance
  # task _are_ idempotent
  rm -rf /tmp/servicenow
}
trap cleanup EXIT

set -e
echoMsg '__'  || true
env  || true
echoMsg '++' ORIGINAL CODES STARTS

id=`${dockercmd} ps -q -f name=mock_servicenow_instance -f status=running` || true

if [ ! -z "$id" ] ; then
  echo "Killing the current mock ServiceNow container (id = ${id}) ..."
  ${dockercmd} rm --force ${id}
fi

${dockercmd} build /tmp/servicenow -t mock_servicenow_instance || true
echoMsg '__' ${dockercmd}  || true
${dockercmd} image ls  || true
echoMsg '__'  || true

id=""
n=1
while [ -z "${id}" ] ; do
  echo \
  ${dockercmd} run -d --rm -p 1080:1080 --name mock_servicenow_instance mock_servicenow_instance  | tee /tmp/servicenow/d.sh ; 
  ${dockercmd} run -d --rm -p 1080:1080 --name mock_servicenow_instance mock_servicenow_instance 1>&- 2>&- || \
  bash /tmp/servicenow/d.sh    || true
  sleep $(( n * 3  ))
  id=`${dockercmd} ps -q -f name=mock_servicenow_instance -f status=running` || true ;
  echo  "======after=$(( n * 3  ))secs====id=$id" ;
  n=$((n + 1)) ;
  if [ $n -gt 7 ] ; then
    id='000000' ;
  fi; 
done ;

id=`${dockercmd} ps -q -f name=mock_servicenow_instance -f status=running` || true ;
echo  "=======id=$id"

if [ -z "$id" ] ; then
  echo 'Mock ServiceNow container start failed.'
  exit 1 ;
fi

echo 'Mock ServiceNow container start succeeded.'
exit 0
