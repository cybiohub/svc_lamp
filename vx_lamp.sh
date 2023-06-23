#! /bin/bash
#set -x
# ****************************************************************************
# *
# * Author:         (c) 2004-2023  Cybionet - Ugly Codes Division
# *
# * File:           vx_lamp.sh
# * Version:        0.2.10
# *
# * Description:    Script for installing a LAMP server on Ubuntu LTS Server.
# *
# * Creation: October 03, 2014
# * Change:   June 22, 2023
# *
# ****************************************************************************
# *
# * IPTABLES: Rules to add in iptables.
# *
# *  # Regle HTTP/HTTPS.
# *  iptables -A INPUT -d ${LAN} -p tcp -m tcp --dport 80 -j ACCEPT
# *  iptables -A INPUT -d ${LAN} -p tcp -m tcp --dport 443 -j ACCEPT
# *
# * MYSQL: Requires a root password for MySQL.
# *
# ****************************************************************************
# *
# * wget page par defaut de remplacement. 
# *
# * wget f2b_apaches_rules.tgz
# *
# * vim /etc/apache2/conf-available/security.conf
# *  ServerTokens Prod
# *  ServerSignature on
# *
# * libapache2-modsecurity - Dummy transitional package
# *
# * MANQUE php8.1-mcrypt
# * AJOUTER la verification lsb_release -r -s
# *
# * ???
# * CHANGER le parametre 'AllowOverride' de 'None' a 'ALL' dans le repertoire /var/www/ du fichier apache2.conf
# * 
# ****************************************************************************


#############################################################################################
# ## CUSTOM VARIABLES 

# ## Timezone.
timezone='America\/Toronto'

# ## Identification.
tagEntreprise='Cybionet'


#############################################################################################
# ## VARIABLES 

# ## PHP installed version.
phpVers=$(apt-cache policy php | grep 'Candidate' | awk -F ":" '{print $3}' | awk -F "+" '{print $1}')


#############################################################################################
# ## VERIFICATION & COLLECTION

# ## Check if the script are running under root user.
if [ "${EUID}" -ne 0 ]; then
  echo -n -e "\n\n\n\e[38;5;208mWARNING:This script must be run with sudo or as root.\e[0m"
  exit 0
fi

# ## !!!!!!!!!!!!!! DOUBLON !!!!!!!!!!!!!!!!!!!!
# ## Check if the PHP version is defined.
if [ -z "${phpVers}" ]; then
 echo -e "\e[31;1;208mInternal problem: PHP version not defined.\e[0m"
 exit 1
fi

# ## Check if the PHP version exist.
phpCheck=$(apt-cache policy php"${phpVers}" | grep -c 'Candidate')

if [ "${phpCheck}" -eq 0 ]; then
 echo -e "\e[31;1;208mInternal problem: PHP version does not exist.\e[0m"
 exit 1
fi

# ## Last chance - Ask before execution.
echo -n -e "\n\n\n\e[38;5;208mWARNING:\e[0m You prepared to install a LAMP server. Enter y to continue, press anything else to exit: "
read ANSWER
if [ "${ANSWER,,}" != 'y' ]; then
  echo 'Have a nice day!'
  exit 0
fi


#############################################################################################
# ## FONCTIONS

# ## Installation of Apache 2.x.
function app_apache {
 apt-get -y install apache2
}

# ## Installation of MySQL 5.x.
function app_mysql {
 apt-get -y install mysql-server mysql-client
 apt-get -y install libmysqlclient-dev libmysqld-dev

 # ## Check if the directory for socket exist.
 if [ ! -d '/var/run/mysqld/' ]; then
   mkdir /var/run/mysqld/
   chown mysql:mysql /var/run/mysqld/
 fi
}

# ## Installation of PHP 8.X.
function app_php {
 apt-get -y install php"${phpVers}" libapache2-mod-php"${phpVers}"

 # ## Installation of PHP 8.X Extra.
 apt-get -y install php"${phpVers}"-cli php"${phpVers}"-curl php"${phpVers}"-mysql php"${phpVers}"-gd php"${phpVers}"-intl php"${phpVers}"-imap php"${phpVers}"-json php"${phpVers}"-ldap php"${phpVers}"-readline php"${phpVers}"-bcmath php"${phpVers}"-mbstring php"${phpVers}"-soap php-xml

 # ## MANQUE php${phpVers}-mcrypt
 # ## https://websiteforstudents.com/install-php-${phpVers}-mcrypt-module-on-ubuntu-18-04-lts/
 # ## https://serverpilot.io/docs/how-to-install-the-php-mcrypt-extension
 # ##https://stackoverflow.com/questions/48275494/issue-in-installing-php${phpVers}-mcrypt
}

# ## PHP 8.X configuration.
function cfg_php {
 sed -i -e "s/;date.timezone =/date.timezone = ${timezone}/g" /etc/php/"${phpVers}"/apache2/php.ini
}

# ## Additional application.
function app_tools {
 # ## ApacheTop: Top for Apache.
 apt-get -y install apachetop

 # ## GoAccess: Apache Log Analyzer.
 apt-get -y install goaccess
}

# ##
function cfg_security {
 # cd /var/www/html/
 # wget http://phpsec.org/projects/phpsecinfo/phpsecinfo.zip -O phpsecinfo.zip
 # apt-get -y install unzip

 # unzip phpsecinfo.zip
 # rm phpsecinfo.zip
 # apt-get -y remove unzip

 # ## APACHE2
 apt-get -y install libapache2-mod-security2
 cd /etc/modsecurity/ || return
 cp modsecurity.conf-recommended modsecurity.conf
 echo -e "SecServerSignature \"${tagEntreprise}\"" > /etc/modsecurity/modcybiolab.conf

 sed -i -e 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' /etc/apache2/apache2.conf

 # ## PHP 8.x
 sed -i -e 's/open_basedir =/open_basedir = \/var\/www\/html\//g' /etc/php/"${phpVers}"/apache2/php.ini
 sed -i -e 's/allow_url_fopen = On/allow_url_fopen = Off/g' /etc/php/"${phpVers}"/apache2/php.ini

 sed -i -e 's/expose_php = On/expose_php = Off/g' /etc/php/"${phpVers}"/apache2/php.ini
 sed -i -e 's/display_errors = On/display_errors = Off/g' /etc/php/"${phpVers}"/apache2/php.ini

# ## disable_functions = pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_get_handler,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,pcntl_async_signals,pcntl_unshare,


}


# ## EXTRA LANGUAGE
function cfg_language {
 locale-gen fr
 locale-gen fr_FR.UTF-8

 locale-gen fr_CA.UTF-8
 locale-gen fr_CA

 locale-gen en_CA.UTF-8
 locale-gen en_CA

 locale-gen en_US
 locale-gen en_US.UTF-8

 locale-gen en_GB
 locale-gen en_GB.UTF-8
}


#############################################################################################
# ## EXECUTION

# ## Update repository.
apt-get update

# ## Installing Apache 2.x.
app_apache

# ## Installing MySQL 5.x.
app_mysql

# ## Installing PHP 8.x.
app_php

# ## PHP configuration.
cfg_php

# ## Application of additional security rules.
cfg_security

# ## Addition of the French language.
cfg_language


echo -n -e "\n\e[38;5;208mWARNING:\e[0m Would you like to install additional packages for PHP (less secure)?. Press 'y' to continue, or any other key to leave: "
read ANSWER
if [ "${ANSWER,,}" = 'y' ]; then
  apt-get -y install php"${phpVers}"-cgi php"${phpVers}"-xmlrpc php"${phpVers}"-snmp php"${phpVers}"-pspell php-geoip php-rrd php-oauth php-auth-sasl php"${phpVers}"-zip php-imagick
fi

echo -e "Change the 'AllowOverride' parameter from 'None' to 'ALL' in the /var/www/ directory of the apache2.conf file."

# ## Restarting the web service.
a2enmod ssl
systemctl restart apache2.service

# ## AJOUTER UN READ!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo -n -e "\n\n\e[38;5;208mDon't forget to set a password for MySQL.\e[0m\n"
echo -e "\nLaunch mysql_secure_installation command.\n"
echo -e "  - Would you like to setup VALIDATE PASSWORD component? yes\n"
echo -e "  - Levels of password validation policy: 2 (Strong)\n"
echo -e "  - Do you wish to continue with the password provided? yes\n"
echo -e "  - Remove anonymous users: yes\n"
echo -e "  - Disallow root login remotely: yes\n"
echo -e "  - Remove test database: yes\n"
echo -e "  - Reloading the privilege tables: yes\n\n"
echo -e "\nAdd a password the root in mysql"
echo -e "  mysql -u root"
echo -e "  FLUSH PRIVILEGES;"
echo -e "  ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';"
echo -e "  exit;\n"


# ## Exit.
exit 0

# ## END
