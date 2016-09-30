#!/bin/sh
DIRDATA='/home'
clear
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
	"ESM" "Monitorer votre serveur" 5>&1 1>&2 2>&5)
 
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
	else
		clear
		whiptail --title "Media Server Recovery" --msgbox "Au revoir." 10 60
	fi
}

lamp () {
debconf-apt-progress -- apt-get install lamp-server^ -y
whiptail --title "Media Server Recovery" --msgbox "Votre serveur WEB est pret." 10 60
maison_pgrm
}

transmission () {
debconf-apt-progress -- apt-get -y install transmission-daemon
mkdir -p  $DIRDATA/torrent/{"encours","fini","watch"}
chgrp debian-transmission $DIRDATA/torrent/{"encours","fini","watch"}
chmod -R 770 $DIRDATA/torrent/{"encours","fini","watch"}
service transmission-daemon stop
#Réglages des dossiers
sed -i "s|^.*\"download-dir\":.*|    \"download-dir\": \"$DIRDATA\/torrent\/fini\"\,|" /etc/transmission-daemon/settings.json
sed -i "s|^.*\"incomplete-dir\":.*|    \"incomplete-dir\": \"$DIRDATA\/torrent\/encours\"\,|" /etc/transmission-daemon/settings.json
sed -i "s|^.*\"incomplete-dir-enabled\":.*|    \"incomplete-dir-enabled\": true\,|" /etc/transmission-daemon/settings.json
#Réglages de l'acces WEB
if (whiptail --yesno "Acces par l'interface WEB ?" 8 78 --title "Media Server Recovery") then
	sed -i 's/.*"rpc-whitelist.enabled":.*/    "rpc-whitelist-enabled": 'false',/' /etc/transmission-daemon/settings.json
	sed -i 's/.*"rpc-enabled":.*/    "rpc-enabled": 'true',/' /etc/transmission-daemon/settings.json
else
	exit 1
fi
TRANSWEBUSER=$(whiptail --inputbox "Nom d'utilisateur ? (Pour l'interface WEB)" 8 78 "transmission" --title "Media Server Recovery" 3>&1 1>&2 2>&3)
sed -i 's/.*"rpc-username":.*/    "rpc-username": '\"$TRANSWEBUSER\"',/' /etc/transmission-daemon/settings.json
TRANSWEBPASS=$(whiptail --inputbox "Mot de passe ? (Pour l'interface WEB)" 8 78 "motdepasse" --title "Media Server Recovery" 3>&1 1>&2 2>&3)
sed -i 's/.*"rpc-password":.*/    "rpc-password": '\"$TRANSWEBPASS\"',/' /etc/transmission-daemon/settings.json
service transmission-daemon start
whiptail --title "Media Server Recovery" --msgbox "Installation et réglages de TRANSMISSION finis.\n \nTransmission est accessible depuis : http://IP:9091" 10 60
maison_pgrm
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
debconf-apt-progress -- apt-get install plexmediaserver -y
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

whiptail --title "Bienvenue" --msgbox "Créé par Valounours. Contact : Valounours@gmail.com" 10 60
if (whiptail --title "Media Server Recovery" --yesno "Voulez-vous continuer ?" 10 60) then
	OPTION=$(whiptail --title "Media Server Recovery" --menu "Faites votre choix ?" 15 80 6 \
	"LAMP" "Serveur WEB avec Apache + MySQL + PhpMyAdmin" \
	"Transmission" "Logiciel de téléchargement de Torrent" \
	"SickRage" "Logiciel d'automatisation de téléchargement de séries"  \
	"CouchPotato" "Logiciel d'automatisation de téléchargement de Films" \
	"Plex" "Logiciel de streaming multimédia" \
	"ESM" "Monitorer votre serveur" 5>&1 1>&2 2>&5)
 
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
	else
		clear
		whiptail --title "Media Server Recovery" --msgbox "Au revoir." 10 60
	fi
else
	clear
	whiptail --title "Media Server Recovery" --msgbox "Au revoir." 10 60
fi
