#! /bin/bash
#
#
#  "postInstall.sh" 
#
#  This is a post-install script for creating a 
#  Linux scientific development workstation from a 
#  basic CentOS system in our environment.  See the 
#  ks.cfg file for the underlying system spec. 
#
#  The base installation has ssh keys set.  Source
#  this file and run all ('install_workstation') or 
#  a subset of the procedures. 
#
#  2013-2015 keven


set_hostsfile()
{
   echo "`hostname -i`  `hostname -s`  `hostname -f`" >> /etc/hosts
   echo "10.1.100.8   ldap   ldap.our.domain.edu" >> /etc/hosts
   echo "10.1.100.9   nas nas.our.domain.edu" >> /etc/hosts
   echo "10.1.100.10   nas2 nas2.our.domain.edu" >> /etc/hosts
}


install_LDAP(){

   yum -y groupinstall "Directory Client"
   yum -y install pam_ldap openldap openldap-clients 

   authconfig --enableshadow --enableldap --enableldapauth --enableldaptls --ldapserver='ldap://ldap.our.domain.edu' \
       --ldapbasedn='dc=our,dc=domain,dc=edu' --enablelocauthorize --enableshadow --passalgo=md5 --update
   authconfig --enablesssd --enablesssdauth --enablelocauthorize --update
   wget http://server.our.domain.edu/etc_sssd_sssd.conf
   mv /etc/sssd/sssd.conf /etc/sssd/sssd.conf-orig
   cp etc_sssd_sssd.conf /etc/sssd/sssd.conf
   chmod 0600 /etc/sssd/sssd.conf
   service sssd restart

   ## IDMAPD
   wget http://server.our.domain.edu/centos_idmapd.conf 
   cp /etc/idmapd.conf /etc/oldidmapd.conf.txt
   cp -vf centos_idmapd.conf /etc/idmapd.conf 
   nfsidmap -c
}


install_automounter()
{

# autofs packages installed earler. 

  echo "+auto.home" >> /etc/auto.home

  echo "#   Our additions" >> /etc/auto.master
  echo "#   " >> /etc/auto.master
  echo "/home   ldap:automountMapName=auto_linux,dc=our,dc=domain,dc=edu fstype=nfs" >> /etc/auto.master

  echo "#   Our additions" >> /etc/auto.proj
  echo "#   " >> /etc/auto.proj
  echo "aims nas:/research/aims" >> /etc/auto.proj
  echo "backup nas:/research/backup" >> /etc/auto.proj

  service autofs restart

  mkdir -p /dept/share

  echo "nas:/global/share       /dept/share		nfs     defaults,noacl,vers=4  0      0" >> /etc/fstab

  mount -a

}

install_rpmforge()
{

    wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
    rpm -ivh rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
    yum -y install htop

}

install_epelrepo(){

    wget http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
    rpm -ivh epel-release-6-8.noarch.rpm
    yum -y install ipython python-matplotlib
    
}

install_desktop(){

   yum -y groupinstall basic-desktop development emacs internet-browser thunderbird scientific tex x11 fonts network-file-system-client mysql-client o
ffice-suite "Printing client" 
   gconftool-2 --direct --config-source=`gconftool-2 --get-default-source` --set /apps/gdm/simple-greeter/disable_user_list --type bool TRUE
   mv -v /etc/inittab /etc/inittab.orig
   cat /etc/inittab.orig | sed -e 's/id:3/id:5/g' > /etc/inittab
   telinit 5

}

disable_guiShutdown(){

    wget http://server.our.domain.edu/Config/etc_polkit-1_localauthority_50-local.d_10-shutdown.pkla
    cp -v ./etc_polkit-1_localauthority_50-local.d_10-shutdown.pkla /etc/polkit-1/localauthority/50-local.d/10-shutdown.pkla
}


install_java(){

    wget http://server.our.domain.edu/Pkg/jdk-8u51-linux-x64.rpm
    rpm -ivh jdk-8u51-linux-x64.rpm

    alternatives --install /usr/bin/java java /usr/java/latest/jre/bin/java 20000
    alternatives --set java /usr/java/latest/jre/bin/java
    alternatives --install /usr/bin/javaws javaws /usr/java/latest/jre/bin/javaws 20000
    alternatives --install /usr/lib/mozilla/plugins/libjavaplugin.so libjavaplugin.so /usr/java/latest/jre/lib/i386/libnpjp2.so 20000
    alternatives --install /usr/lib64/mozilla/plugins/libjavaplugin.so libjavaplugin.so.x86_64 /usr/java/latest/jre/lib/amd64/libnpjp2.so 20000
    alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 20000
    alternatives --install /usr/bin/jar jar /usr/java/latest/bin/jar 20000


}

install_Eclipse(){

    [ -d /opt/eclipse ] && echo "Eclipse already installed. " && return 1
    wget http://server.our.domain.edu/Pkg/ECLIPSE/eclipse-jee-mars-R-linux-gtk-x86_64.tar.gz	
    tar -xzf /root/eclipse-jee-mars-R-linux-gtk-x86_64.tar.gz -C /opt
    wget http://server.our.domain.edu/Pkg/ECLIPSE/eclipse
    cp -vi eclipse /usr/bin	
    chmod 0755 /usr/bin/eclipse
    wget http://server.our.domain.edu/Pkg/ECLIPSE/eclipse.desktop
    cp -v eclipse.desktop /usr/share/applications/
}


install_adobeFlash(){

    rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-x86_64-1.0-1.noarch.rpm
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux
    yum check-update
    yum -y install flash-plugin nspluginwrapper alsa-plugins-pulseaudio libcurl
}

install_additionalPkgs() {

    SYSTEM="ksh zsh lshw gnome-utils"
    MPI="openmpi openmpi-devel mpi4py-openmpi pypar-openmpi hdf5-openmpi"
    OTHER="mpfr mpfr-devel dvipng gmp gmp-devel gmp-debuginfo libmpc-devel \
           libmpc-debuginfo expat expat-devel expat-debuginfo ncurses-devel"
    PYTHON="python-imaging python-imaging-devel python-toolsr python-matplotlib.x86_64 \
            python-matplotlib-tk.x86_64 scipy ipython-gui ipython-doc" 
    PHP="php-common php-mysql php-cli php-odbc php-pdo"
    EDITORS="vim emacs gedit"
    MISC="evince"

    yum -y install $SYSTEM $MPI $OTHER $PYTHON $PHP $EDITORS $MISC
}

install_Python3(){

    [ -e /usr/local/bin/python3.4 ] && echo "Python 3.4 already installed. " && return 1
    wget http://server.our.domain.edu/Pkg/Python-3.4.1.tar.gz
    tar -xzvf /root/Python-3.4.1.tar.gz -C /tmp
    cd /tmp/Python-3.4.1
    make altinstall
    cd ~
}

set_firewall(){

 # Flush all current rules 
 iptables -F

 # Set default policies for INPUT, FORWARD and OUTPUT chains
 iptables -P INPUT DROP
 iptables -P FORWARD DROP
 iptables -P OUTPUT ACCEPT

 # Set access for localhost
 iptables -A INPUT -i lo -j ACCEPT

 # Accept packets belonging to established and related connections
 iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

 # Allow all connections from other dept. machines.
 iptables -A INPUT -p tcp -s 10.1.100/24 -j ACCEPT -m state --state NEW

 # Save settings
 /sbin/service iptables save
}

set_cups(){
    echo "ServerName 10.1.100.10" >> /etc/cups/client.conf
}


install_workstation() {

    ## Order matters...
    set_hostsfile 
    install_desktop 
    install_rpmforge
    install_epelrepo
    install_LDAP
    install_automounter
    set_cups
    disable_guiShutdown
    install_additionalPkgs
    install_java 
    install_adobeFlash 
    install_Eclipse
    install_Python3
    set_firewall
}


#FIN
