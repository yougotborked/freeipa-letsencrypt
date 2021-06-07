These two scripts try to automatically obtain and install Let's Encrypt certs
to FreeIPA web interface.

To use it, do this:
* BACKUP /var/lib/ipa/certs/ and /var/lib/ipa/private/ to some safe place (it contains private keys!)
* clone/unpack all scripts somewhere (e.g. /opt/) where they are going to run and create directories and files
* set WORKDIR variable to the directory you cloned the repository to in scripts setup-le.sh and renew-le.sh
* set DIRPASSWD and EMAIL variable in renew-le.sh
* set FQDN in ipa-httpd.cnf
* retrieve current ticket for admin (kinit admin)
* run "yum install dnf" (a stock FreeIPA machine doesn't have dnf installed)
* run setup-le.sh script once to prepare the machine. The script will:
  * install Let's Encrypt client package
  * install Let's Encrypt CA certificates into FreeIPA certificate store
  * requests new certificate for FreeIPA web interface
* run renew-le.sh script once a day: it will renew the cert as necessary
  * run "crontab -e" as root
  * add the line "* * * * * /root/ipa-le/renew-le.sh"

If you have any problem, feel free to contact FreeIPA team:
http://www.freeipa.org/page/Contribute#Communication
