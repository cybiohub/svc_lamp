![alt text][logo]

# Cybionet - Ugly Codes Division

## SUMMARY

LAMP Server installation script under Ubuntu and Debian.

	- Apache
	- MySQL
	- PHP
	- on Linux

Works on Ubuntu, Debian and Rasbpian.


## REQUIRED

The `vx_lamp.sh` application does not require any additional packages to work.


## INSTALLATION

1. Download files from this repository directly with git or via https.

	```bash
	wget -O svc_lamp.zip https://github.com/cybiohub/svc_lamp/archive/refs/heads/main.zip
	```

2. Unzip the zip file.

	```bash
	unzip svc_lamp.zip
	```

3. Make changes to the installation script `vx_lamp.sh` to configure it to match your environment.
	
	You can customize the following settings: 

	- Timezone. By default, this is "America\/Toronto".
	- The identifiant for the name server.

5. Adjust permissions.

	```bash
	chmod 500 vx_lamp.sh
	```

6. Run the script.

	```bash
	./vx_lamp.sh
	```

7. At the end of the LAMP wizard installation, you can install additional packages.

	- php8.1-cgi
	- php8.1-xmlrpc
	- php8.1-snmp
	- php8.1-pspell
	- php-geoip
	- php-rrd
	- php-oauth
	- php-auth-sasl
	- php8.1-zip
	- php-imagick

8. Don't forget to change the 'AllowOverride' parameter from 'None' to 'ALL' in the /var/www/ directory of the apache2.conf file.

9. Activate and start the Apache2 service.

 	```bash
	systemctl enable apache2.service
	systemctl start apache2.service
	systemctl status apache2.service
	```

10. Activate and start the MySQL service.

	```bash
	systemctl enable apache2.service
	systemctl start apache2.service
	systemctl status apache2.service
	```
---
[logo]: ./md/logo.png "Cybionet"
