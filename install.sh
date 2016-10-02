#!/bin/sh
DIRDATA='/home'
# Check Root
if [ $(id -u) != "0" ]; then
    clear
    echo "Vérification Root : Erreur... Vous n'etes pas root !"
    exit 1
fi
#Debian only
if [ ! -f /etc/debian_version ]; then 
    clear
    echo "Vérification OS : Ceci n'est pas une Débian !!"
    exit 1
fi
# Installation des prérequis
apt-get install -y whiptail unzip
clear

maison_pgrm () {
	OPTION=$(whiptail --title "Media Server Recovery" --menu "Faites votre choix ?" 15 80 6 \
	"LAMP" "Serveur WEB avec Apache + MySQL + PhpMyAdmin" \
	"Transmission" "Logiciel de téléchargement de Torrent" \
	"SickRage" "Logiciel d'automatisation de téléchargement de séries"  \
	"CouchPotato" "Logiciel d'automatisation de téléchargement de Films" \
	"Plex" "Logiciel de streaming multimédia" \
	"ESM" "Monitorer votre serveur" \
	"Sous-domaines" "Acceder au service sans les ports" 5>&1 1>&2 2>&5)
 
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
	#Pré-Requis
		if [ $OPTION = LAMP ]; then
			lamp
		fi
		if [ $OPTION = Transmission ]; then
			transmission
		fi
		if [ $OPTION = SickRage ]; then
			sickrage
		fi
		if [ $OPTION = CouchPotato ]; then
			couchpotato
		fi
		if [ $OPTION = Plex ]; then
			plex
		fi
		if [ $OPTION = ESM ]; then
			esm
		fi
		if [ $OPTION = Sous-domaines ]; then
			subdomain
		fi
	else
		clear
		whiptail --title "Media Server Recovery" --msgbox "Au revoir." 10 60
	fi
}

lamp () {
debconf-apt-progress -- apt-get install apache2 libapache2-mod-php5 mysql-server php5-mysql phpmyadmin -y
a2enmod proxy
a2enmod proxy_http
etc/init.d/apache2 restart
whiptail --title "Media Server Recovery" --msgbox "Votre serveur WEB est pret." 10 60
maison_pgrm
}

transmission () {
debconf-apt-progress -- apt-get -y install transmission-daemon
mkdir -p  $DIRDATA/torrent/{"encours","fini","watch"}
chgrp debian-transmission $DIRDATA/torrent/{"encours","fini","watch"}
chmod -R 770 $DIRDATA/torrent/{"encours","fini","watch"}
echo -e '\n#proxy transmission \nProxyPass /transmission http://localhost:9091/transmission \nProxyPassReverse /transmission http://localhost:9091/transmission' >> /etc/apache2/sites-available/000-default.conf
etc/init.d/apache2 restart
service transmission-daemon stop
#Réglages de l'acces WEB
if (whiptail --yesno "Acces par l'interface WEB ?" 8 78 --title "Media Server Recovery") then
	sed -i 's/.*"rpc-whitelist.enabled":.*/    "rpc-whitelist-enabled": 'false',/' /etc/transmission-daemon/settings.json
	sed -i 's/.*"rpc-enabled":.*/    "rpc-enabled": 'true',/' /etc/transmission-daemon/settings.json
	TRANSWEBUSER=$(whiptail --inputbox "Nom d'utilisateur ? (Pour l'interface WEB)" 8 78 "transmission" --title "Media Server Recovery" 3>&1 1>&2 2>&3)
	sed -i 's/.*"rpc-username":.*/    "rpc-username": '\"$TRANSWEBUSER\"',/' /etc/transmission-daemon/settings.json
	TRANSWEBPASS=$(whiptail --inputbox "Mot de passe ? (Pour l'interface WEB)" 8 78 "motdepasse" --title "Media Server Recovery" 3>&1 1>&2 2>&3)
	sed -i 's/.*"rpc-password":.*/    "rpc-password": '\"$TRANSWEBPASS\"',/' /etc/transmission-daemon/settings.json
	#Réglages des dossiers
	sed -i "s|^.*\"download-dir\":.*|    \"download-dir\": \"$DIRDATA\/torrent\/fini\"\,|" /etc/transmission-daemon/settings.json
	sed -i "s|^.*\"incomplete-dir\":.*|    \"incomplete-dir\": \"$DIRDATA\/torrent\/encours\"\,|" /etc/transmission-daemon/settings.json
	sed -i "s|^.*\"incomplete-dir-enabled\":.*|    \"incomplete-dir-enabled\": true\,|" /etc/transmission-daemon/settings.json
	service transmission-daemon start
	whiptail --title "Media Server Recovery" --msgbox "Installation et réglages de TRANSMISSION finis.\n \nTransmission est accessible depuis : http://IP/transmission" 10 60
	maison_pgrm
else
	service transmission-daemon start
	exit 1
fi
}

sickrage () {
debconf-apt-progress -- apt-get -y install git-core python python-cheetah
git clone git://github.com/SickRage/SickRage.git /opt/sickrage
chown -R root:root /opt/sickrage
cp /opt/sickrage/runscripts/init.debian /etc/init.d/sickrage
chmod +x /etc/init.d/sickrage
echo -e "SR_USER=root\nSR_HOME=/opt/sickrage\nSR_DATA=/opt/sickrage\nSR_GROUP=root" >>  /etc/default/sickrage
update-rc.d sickrage defaults
service sickrage start
whiptail --title "Media Server Recovery" --msgbox "Installation et réglages de SICKRAGE finis.\n \nSickrage est accessible depuis : http://IP:8081" 10 60
maison_pgrm
}

couchpotato () {
debconf-apt-progress -- apt-get -y install git-core python python-cheetah
git clone https://github.com/sarakha63/CouchPotatoServer.git /opt/couchpotato
chown -R root:root /opt/couchpotato
cp /opt/couchpotato/init/ubuntu /etc/init.d/couchpotato
echo -e "CP_HOME=/opt/couchpotato\nCP_USER=root" >> /etc/default/couchpotato
chmod +x /etc/init.d/couchpotato
update-rc.d couchpotato defaults
service couchpotato start
whiptail --title "Media Server Recovery" --msgbox "Installation et réglages de COUCHPOTATO finis.\n \nCouchPotato est accessible depuis : http://IP:5050" 10 60
maison_pgrm
}

plex () {
debconf-apt-progress -- apt-get -y install curl
echo "deb http://shell.ninthgate.se/packages/debian jessie main" | tee -a /etc/apt/sources.list.d/plexmediaserver.list
curl http://shell.ninthgate.se/packages/shell.ninthgate.se.gpg.key | apt-key add -
apt-get update
apt-get install plexmediaserver -y
whiptail --title "Media Server Recovery" --msgbox "Installation et réglages de PLEX finis.\n \nPlex est accessible depuis : http://IP:32400/web" 10 60
maison_pgrm
}

esm () {
wget --content-disposition  http://ezservermonitor.com/esm-web/downloads/version/2.5
unzip ezservermonitor-web_v2.5.zip
mv eZServerMonitor-2.5/ esm
cp esm /var/www/html
whiptail --title "Media Server Recovery" --msgbox "Installation et réglages de ESM finis.\n \nESM est accessible depuis : http://NDD/esm" 10 60
maison_pgrm
}

subdomain () {
a2enmod proxy
a2enmod proxy_http
/etc/init.d/apache2 restart
cd /etc/apache2/sites-available
mv 000-default.conf 000-default.conf.base
cat >> 000-default.conf <<EOF
<VirtualHost *:80>
	# The ServerName directive sets the request scheme, hostname and port that
	# the server uses to identify itself. This is used when creating
	# redirection URLs. In the context of virtual hosts, the ServerName
	# specifies what hostname must appear in the request's Host: header to
	# match this virtual host. For the default virtual host (this file) this
	# value is not decisive as it is used as a last resort host regardless.
	# However, you must set it for any further virtual host explicitly.
	#ServerName www.example.com

	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/html

	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	#LogLevel info ssl:warn

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined

	# For most configuration files from conf-available/, which are
	# enabled or disabled at a global level, it is possible to
	# include a line for only one particular virtual host. For example the
	# following line enables the CGI configuration for this host only
	# after it has been globally disabled with "a2disconf".
	#Include conf-available/serve-cgi-bin.conf
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

ProxyPass /couchpotato http://localhost:5050/couchpotato
ProxyPassReverse /couchpotato http://localhost:5050/couchpotato

ProxyPass /transmission http://localhost:9091/transmission
ProxyPassReverse /transmission http://localhost:9091/transmission

ProxyPass /sickrage http://localhost:8081/home
ProxyPassReverse /sickrage http://localhost:8081/home
EOF
/etc/init.d/apache2 restart
service couchpotato stop
sed -i '21s/url_base=/url_base=\/couchpotato/' /var/opt/couchpotato/setting.conf
service couchpotato start
service sickrage stop
sed -i '802s/web_root = ""/web_root = "\/couchpotato/' /opt/sickrage/config.init
service sickrage start
whiptail --title "Media Server Recovery" --msgbox "Les sous-domaines sont actif :\n \nTransmission : *NDD/transmission \nSickrage : $NDD/sickrage \nCouchPotato : $NDD/couchpotato \n Plex : $NDD/plex" 10 60
maison_pgrm
}
whiptail --title "Bienvenue" --msgbox "Créé par Valounours. Contact : Valounours@gmail.com" 10 60
if (whiptail --title "Media Server Recovery" --yesno "Voulez-vous continuer ?" 10 60) then
	OPTION=$(whiptail --title "Media Server Recovery" --menu "Faites votre choix ?" 15 80 6 \
	"LAMP" "Serveur WEB avec Apache + MySQL + PhpMyAdmin" \
	"Transmission" "Logiciel de téléchargement de Torrent" \
	"SickRage" "Logiciel d'automatisation de téléchargement de séries"  \
	"CouchPotato" "Logiciel d'automatisation de téléchargement de Films" \
	"Plex" "Logiciel de streaming multimédia" \
	"ESM" "Monitorer votre serveur" \
	"Sous-domaines" "Acceder au service sans les ports" 5>&1 1>&2 2>&5)
 
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
	#Pré-Requis
		if [ $OPTION = LAMP ]; then
			lamp
		fi
		if [ $OPTION = Transmission ]; then
			transmission
		fi
		if [ $OPTION = SickRage ]; then
			sickrage
		fi
		if [ $OPTION = CouchPotato ]; then
			couchpotato
		fi
		if [ $OPTION = Plex ]; then
			plex
		fi
		if [ $OPTION = ESM ]; then
			esm
		fi
		if [ $OPTION = Sous-domaines ]; then
			subdomain
		fi
	else
		clear
		whiptail --title "Media Server Recovery" --msgbox "Au revoir." 10 60
	fi
else
	clear
	whiptail --title "Media Server Recovery" --msgbox "Au revoir." 10 60
fi
