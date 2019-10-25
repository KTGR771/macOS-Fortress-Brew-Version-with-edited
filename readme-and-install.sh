#!/bin/bash -x

# macOS Fortress: Firewall, Blackhole, and Privatizing Proxy
# for Trackers, Attackers, Malware, Adware, and Spammers
# with On-Demand and On-Access Anti-Virus Scanning

# commands
SUDO=/usr/bin/sudo
INSTALL=/usr/bin/install
#PORT=/usr/local/bin/port
BREW=/usr/local/bin/brew
CPAN=/usr/bin/cpan
GPG=/usr/local/bin/gpg
CURL=/usr/bin/curl
OPEN=/usr/bin/open
DIFF=/usr/bin/diff
PATCH=/usr/bin/patch
LAUNCHCTL=/bin/launchctl
APACHECTL=/usr/sbin/apachectl
SERVERADMIN=/Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin
PFCTL=/sbin/pfctl
MKDIR=/bin/mkdir
CHOWN=/usr/sbin/chown
CAT=/bin/cat
ECHO=/bin/echo
MORE=/usr/bin/more
LSOF=/usr/sbin/lsof
CP=/bin/cp
RM=/bin/rm
SH=/bin/sh
FMT=/usr/bin/fmt
EGREP=/usr/bin/egrep
RSYNC=/usr/bin/rsync
STACK=/usr/local/bin/stack
ADBLOCK2PRIVOXY=/usr/local/bin/adblock2privoxy

$CAT <<'HELPSTRING' | $MORE
macOS Fortress: Firewall, Blackhole, and Privatizing Proxy
for Trackers, Attackers, Malware, Adware, and Spammers

Kernel-level, OS-level, and client-level security for macOS. Built to
address a steady stream of attacks visible on snort and server logs,
as well as blocks ads, malicious scripts, and conceal information used
to track you around the web. After this package was installed, snort
and other detections have fallen to a fraction with a few simple
blocking actions.  This setup is a lot more capable and effective than
using a simple adblocking browser Add-On. There's a world of
difference between ad-filled web pages with and without a filtering
proxy server. It's also saved me from inadvertantly clicking on
phishing links.

This package uses these features:

	* macOS adaptive firewall
	* Adaptive firewall to brute force attacks
	* IP blocks updated about twice a day from emergingthreats.net
	  (IP blocks, compromised hosts, Malvertisers) and
	  dshield.org’s top-20
	* Host blocks updated about twice a day from hphosts.net
	* Special proxy.pac host blacklisting from hostsfile.org
        * On-Demand and On-Access Anti-Virus

This install script installs and configures a macOS Firewall and Privatizing
Proxy, and macOS On-Demand and On-Access Anti-Virus. It will:

	* Prompt you to install Apple's Xcode Command Line Tools and
	  Macports <https://www.macports.org/> Uses Macports to
	* Download and install several key utilities and applications
	  (wget gnupg2 p7zip squid privoxy nmap)
	* Configure macOS's PF native firewall (man pfctl, man pf.conf),
	  squid, and privoxy
	* Turn on macOS's native Apache webserver to serve the
	  Automatic proxy configuration http://localhost/proxy.pac
	* Networking on the local computer can be set up to use this
          Automatic Proxy Configuration without breaking App Store or
          other updates (see squid.conf)
	* Uncomment the nat directive in pf.conf if you wish to set up
          an OpenVPN server <https://discussions.apple.com/thread/5538749>
	* Install and launch daemons that download and regularly
	  update open source IP and host blacklists. The sources are
	  emergingthreats.net (net.emergingthreats.blockips.plist),
	  dshield.org (net.dshield.block.plist), hosts-file.net
	  (net.hphosts.hosts.plist), and EasyList
	  (com.github.essandess.easylist-pac.plist)
        * On-Demand and On-Access Anti-Virus using clamAV; both scheduled
          full volume scans and on-access scans of all user Downloads and
          Desktop directories are performed
	* Installs a user launch daemon that deletes flash cookies not
          related to Adobe Flash Player settings every half-hour
          <http://goo.gl/k4BxuH>
	* After installation the connection between clients and the
	  internet looks this this:

	  Application  <--port 3128-->  Squid  <--port 8118--> Privoxy  <----> Internet

Installation:

sudo -E sh -x ./readme-and-install.sh

Notes:

	* Configure the squid proxy to accept connections on the LAN IP
	  and set LAN device Automatic Proxy Configurations to
	  http://lan_ip/proxy.pac to protect devices on the LAN.
	* Count the number of attacks since boot with the script
	  pf_attacks. ``Attack'' is defined as the number of blocked IPs
	  in PF's bruteforce table plus the number of denied connections
	  from blacklisted IPs in the tables compromised_ips,
	  dshield_block_ip, and emerging_threats.
	* Both squid and Privoxy are configured to forge the User-Agent.
	  The default is an iPad to allow mobile device access. Change
	  this to your local needs if necessary.
	* Whitelist or blacklist specific domain names with the files
	  /usr/local/etc/whitelist.txt and
	  /usr/local/etc/blacklist.txt. After editing these file, use
	  launchctl to unload and load the plist
	  /Library/LaunchDaemons/net.hphosts.hosts.plist, which
	  recreates the hostfile /etc/hosts-hphost and reconfigures
	  the squid proxy to use the updates.
	* Sometimes pf and privoxy do not launch at boot, in spite of
	  the use of the use of their launch daemons.  Fix this by
	  hand after boot with the scripts macosfortress_setup_check.sh, or
	  individually using pf_restart, privoxy_restart, and
	  squid_restart. And please post a solution if you find one.
	* All open source updates are done using the 'wget -N' option
          to save everyone's bandwidth

Security:

	* These services are intended to be run on a secure LAN behind
	  a router firewall.
	* Even though the default proxy configuration will only accept
	  connections made from the local computer (localhost), do not
	  configure the router to forward ports 3128 or 8118 in case
	  you ever change this or you will be running an open web proxy.
HELPSTRING

$ECHO "Installing..."

# prerequisites

# Install macOS Command Line Tools
CLT_DIR=`xcode-select -p`
RV=$?
if ! [ $RV -eq '0' ]
then
    $SUDO -E /usr/bin/xcode-select --install
    $SUDO -E /usr/bin/xcodebuild -license
fi

# Install MacPorts
#if ! [ -x $PORT ]
#then
#    $OPEN -a Safari https://www.macports.org/install.php
#    $CAT <<MACPORTS
#Please download and install Macports from https://www.macports.org/install.php
#then run this script again.
#MACPORTS
#    exit 1
#fi

# Install stack for adblock2privoxy
# https://docs.haskellstack.org/en/stable/install_and_upgrade/
if ! [ -x $STACK ]
then
    $CURL -sSL https://get.haskellstack.org/ | $SH
fi

# Proxy settings in /usr/local/etc/macports/macports.conf
#$SUDO -E $PORT selfupdate

# Install wget, gnupg2, 7z, pcre, proxies, perl, and python modules
#$SUDO -E $PORT uninstall squid2 squid3 gnupg && $SUDO $PORT clean --dist squid2 squid3 gnupg
#$SUDO -E $PORT -pN install wget gnupg2 p7zip pcre squid4 privoxy nginx nmap python37 py37-scikit-learn py37-matplotlib py37-numpy clamav clamav-server fswatch
$BREW install wget gnupg2 p7zip pcre squid privoxy nginx nmap python3 clamav fswatch

# exit with error if these ports aren't installed
#for P in wget gnupg2 p7zip pcre squid privoxy nginx nmap python37 clamav clamav-server fswatch
#do
#    BREW_TEST=`brew list $P | egrep -e "^ *$P.+\(active\)"`
#    if [ "$PORT_TEST" == "" ]
#    then
#        cat <<PORT_NOT_INSTALLED
#Macports port $P is not installed. Please fix this by hand and
#re-run this script.
#PORT_NOT_INSTALLED
#        exit 1
#    fi
#done

#$SUDO -E $PORT select --set python3 python37
$SUDO -E $CPAN install
$SUDO -E $CPAN -i Data::Validate::IP
$SUDO -E $CPAN -i Data::Validate::Domain
# Used to verify downloads
#$SUDO -E $CURL -O https://secure.dshield.org/PGPKEYS.txt
#$SUDO -E $GPG --homedir /var/root/.gnupg --import PGPKEYS.txt
#$SUDO -E $GPG --homedir /var/root/.gnupg --recv-keys 221084F4 608D9001
#$SUDO -E $GPG --homedir /var/root/.gnupg --list-keys
#$CAT <<'GPGID'
#Keep your gpg keychain up to date by checking the keys IDs with these commands:
#
#/usr/local/bin/gpg --verify /usr/local/etc/block.txt.asc /usr/local/etc/block.txt
/usr/bin/unzip -o /usr/local/etc/hosts.zip -d /tmp/hphosts && /usr/local/bin/gpg --verify /tmp/hphosts/hosts.txt.asc /tmp/hphosts/hosts.txt
#GPGID
#$ECHO 'To delete expited keys, see http://superuser.com/questions/594116/clean-up-my-gnupg-keyring/594220#comment730593_594220'
#$ECHO 'These commands delete expired GPG keys:'
#$CAT <<DELETE_EXPIRED_GPG_KEYS
#$SUDO -E $GPG --homedir /var/root/.gnupg --list-keys | $AWK 'c{id=$1; print id;c=0}/^pub.* \[expired\: /{c=1}' | $FMT -w 999 | $SED 's/^/gpg --delete-keys /;'
#$SUDO -E $GPG --homedir /var/root/.gnupg --delete-keys KeyIDs ...
#DELETE_EXPIRED_GPG_KEYS

# apache for proxy.pac
if ! [ -d /Applications/Server.app ]
then
    # macOS native apache server for proxy.pac
    PROXY_PAC_DIRECTORY=/Library/WebServer/Documents
    $SUDO -E $APACHECTL start
else
    # macOS Server for proxy.pac
    # Assume that Server.app v5.8+'s Profile Manager Apache Web server
    # has been configured to serve PAC files; see te VirtualHost or AliasMatch
    # methods at https://github.com/essandess/macOS-Open-Source-Server
    PROXY_PAC_DIRECTORY=/Library/WebServer/Sites/proxy.mydomain.private
    if ! [ -d $PROXY_PAC_DIRECTORY ]
    then
        $CAT <<PROXY_PAC_DNS
Please configure DNS and your Profile Manager Web server to create the hostname
and website ${PROXY_PAC_DIRECTORY##*/}, edit the configuration files

	`fgrep -l mydomain ./* | tr '\n'  ' '`

to reflect this name, then run this script again.
PROXY_PAC_DNS
        # Don't exit-on-error, but be sure to configure necessary files by hand
        if false; then exit 1; fi
    fi
    $SUDO -E $SERVERADMIN stop devicemgr
    $SUDO -E $SERVERADMIN start devicemgr
fi
$SUDO -E $INSTALL -m 644 ./proxy.pac $PROXY_PAC_DIRECTORY
$SUDO -E $INSTALL -m 644 ./proxy.pac $PROXY_PAC_DIRECTORY/proxy.pac.orig

# Compile and install adblock2privoxy
if ! [ -x $ADBLOCK2PRIVOXY ]
then
    $SUDO -E $MKDIR -p /usr/local/etc/adblock2privoxy
    $SUDO -E $MKDIR -p /usr/local/etc/adblock2privoxy/css
    $SUDO -E $RSYNC -a easylist-pac-privoxy/adblock2privoxy/adblock2privoxy* /usr/local/etc/adblock2privoxy
    # ensure that macOS /usr/bin/gcc is the C compiler    
    $SUDO -E $SH -c 'export PATH=/usr/bin:$PATH ; export STACK_ROOT=/usr/local/etc/.stack ; ( cd /usr/local/etc/adblock2privoxy/adblock2privoxy ; /usr/local/bin/stack setup --allow-different-user ; /usr/local/bin/stack install --local-bin-path /usr/local/bin --allow-different-user )'
    $SUDO -E $INSTALL -m 644 ./easylist-pac-privoxy/adblock2privoxy/nginx.conf /usr/local/etc/adblock2privoxy
    $SUDO -E $INSTALL -m 644 ./easylist-pac-privoxy/adblock2privoxy/default.html /usr/local/etc/adblock2privoxy/css
fi

# proxy configuration

# squid

#squid.conf
if ! [ -f /usr/local/etc/squid/squid.conf.documented ]
then
    $SUDO -E $INSTALL -m 644 -B .orig /usr/local/etc/squid/squid.conf /usr/local/etc/squid/squid.conf.documented
else
    $SUDO -E $INSTALL -m 644 -B .orig /usr/local/etc/squid/squid.conf.documented /usr/local/etc/squid/squid.conf
fi
$SUDO -E $INSTALL -m 644 -B .orig /usr/local/etc/squid/squid.conf.documented /usr/local/etc/squid/squid.conf.orig
$DIFF -NaurdwB -I '^ *#.*' /usr/local/etc/squid/squid.conf ./squid.conf > /tmp/squid.conf.patch
$SUDO -E $PATCH -p5 /usr/local/etc/squid/squid.conf < /tmp/squid.conf.patch
$RM /tmp/squid.conf.patch

# rotate squid logs
if ! [ -f /Library/LaunchDaemons/org.squid-cache.squid-rotate.plist ]
then
    $SUDO -E $INSTALL -m 644 ./org.squid-cache.squid-rotate.plist /Library/LaunchDaemons
fi
if ! [ -d /usr/local/var/log/squid ]; then
    #$SUDO -E $MKDIR -p -m 644 /usr/local/var/squid/logs
    $SUDO -E $MKDIR -p -m 644 /usr/local/var/log/squid
fi

$SUDO -E /usr/local/sbin/squid -s -z --foreground

# privoxy

#config
$SUDO -E $INSTALL -m 640 -o privoxy -g privoxy -B .orig /usr/local/etc/privoxy/config /usr/local/etc/privoxy/config.orig
$SUDO -E $DIFF -NaurdwB -I '^ *#.*' /usr/local/etc/privoxy/config ./config > /tmp/config.patch
$SUDO -E $PATCH -p5 /usr/local/etc/privoxy/config < /tmp/config.patch
$RM /tmp/config.patch

#match-all.action
$SUDO -E $INSTALL -m 640 -o privoxy -g privoxy -B .orig /usr/local/etc/privoxy/match-all.action /usr/local/etc/privoxy/match-all.action.orig
$SUDO -E $DIFF -NaurdwB -I '^ *#.*' /usr/local/etc/privoxy/match-all.action ./match-all.action > /tmp/match-all.action.patch
$SUDO -E $PATCH -p5 /usr/local/etc/privoxy/match-all.action < /tmp/match-all.action.patch
$RM /tmp/match-all.action.patch

#user.action
$SUDO -E $INSTALL -m 644 -o privoxy -g privoxy -B .orig /usr/local/etc/privoxy/user.action /usr/local/etc/privoxy/user.action.orig
$SUDO -E $DIFF -NaurdwB -I '^ *#.*' /usr/local/etc/privoxy/user.action ./user.action > /tmp/user.action.patch
$SUDO -E $PATCH -p5 /usr/local/etc/privoxy/user.action < /tmp/user.action.patch
$RM /tmp/user.action.patch

#$SUDO -E $BASH -c '( cd /usr/local/etc/privoxy ; /usr/sbin/chown privoxy:privoxy config* *.action *.filter )'

#privoxy logs
if ! [ -d /usr/local/var/log/privoxy ]; then
    $SUDO -E $MKDIR -m 644 /usr/local/var/log/privoxy
fi

# install the files
$SUDO -E $CP /etc/hosts /etc/hosts.orig
$SUDO -E $INSTALL -b -B .orig ./pf.conf /etc
if ! [ -f /Library/LaunchDaemons/net.openbsd.pf.plist ]
then
    $SUDO -E $INSTALL -m 644 ./net.openbsd.pf.plist /Library/LaunchDaemons
fi
if ! [ -f /Library/LaunchDaemons/net.openbsd.pf.brutexpire.plist ]
then
    $SUDO -E $INSTALL -m 644 ./net.openbsd.pf.brutexpire.plist /Library/LaunchDaemons
fi
if ! [ -f /Library/LaunchDaemons/net.emergingthreats.blockips.plist ]
then
    $SUDO -E $INSTALL -m 644 ./net.emergingthreats.blockips.plist /Library/LaunchDaemons
fi
#if ! [ -f /Library/LaunchDaemons/net.dshield.block.plist ]
#then
#    $SUDO -E $INSTALL -m 644 ./net.dshield.block.plist /Library/LaunchDaemons
#fi
if ! [ -f /Library/LaunchDaemons/net.hphosts.hosts.plist ]
then
    $SUDO -E $INSTALL -m 644 ./net.hphosts.hosts.plist /Library/LaunchDaemons
fi
if ! [ -f /Library/LaunchDaemons/com.github.essandess.easylist-pac.plist ]
then
    $SUDO -E $INSTALL -m 644 ./com.github.essandess.easylist-pac.plist /Library/LaunchDaemons
fi
if ! [ -f /Library/LaunchDaemons/com.github.essandess.adblock2privoxy.plist ]
then
    $SUDO -E $INSTALL -m 644 ./easylist-pac-privoxy/adblock2privoxy/com.github.essandess.adblock2privoxy.plist /Library/LaunchDaemons
fi
if ! [ -f /Library/LaunchDaemons/com.github.essandess.adblock2privoxy.nginx.plist ]
then
    $SUDO -E $INSTALL -m 644 ./easylist-pac-privoxy/adblock2privoxy/com.github.essandess.adblock2privoxy.nginx.plist /Library/LaunchDaemons
fi
$INSTALL -m 644 ./org.opensource.flashcookiedelete.plist ~/Library/LaunchAgents
$SUDO -E $MKDIR -p /usr/local/etc
$SUDO -E $INSTALL -m 644 ./blockips.conf /usr/local/etc
$SUDO -E $INSTALL -m 644 ./whitelist.txt /usr/local/etc
$SUDO -E $INSTALL -m 644 ./blacklist.txt /usr/local/etc

$SUDO -E $INSTALL -m 755 ./pf_attacks /usr/local/bin
$SUDO -E $INSTALL -m 755 ./macosfortress_setup_check.sh /usr/local/bin
$SUDO -E $INSTALL -m 755 ./pf_restart /usr/local/bin
$SUDO -E $INSTALL -m 755 ./squid_restart /usr/local/bin
$SUDO -E $INSTALL -m 755 ./privoxy_restart /usr/local/bin
$SUDO -E $INSTALL -m 755 ./easylist-pac-privoxy/easylist_pac.py /usr/local/bin

# launchd daemons
$SUDO -E $LAUNCHCTL load -w /Library/LaunchDaemons/net.openbsd.pf.plist
$SUDO -E $LAUNCHCTL load -w /Library/LaunchDaemons/net.openbsd.pf.brutexpire.plist
$SUDO -E $LAUNCHCTL load -w /Library/LaunchDaemons/net.emergingthreats.blockips.plist
#$SUDO -E $LAUNCHCTL load -w /Library/LaunchDaemons/net.dshield.block.plist
$SUDO -E $LAUNCHCTL load -w /Library/LaunchDaemons/net.hphosts.hosts.plist
$SUDO -E $LAUNCHCTL load -w /Library/LaunchDaemons/com.github.essandess.easylist-pac.plist
$SUDO -E $LAUNCHCTL load -w /Library/LaunchDaemons/com.github.essandess.adblock2privoxy.plist
$SUDO -E $LAUNCHCTL load -w /Library/LaunchDaemons/com.github.essandess.adblock2privoxy.nginx.plist
$SUDO -E $LAUNCHCTL load -w /Library/LaunchDaemons/org.squid-cache.squid-rotate.plist

# start these services for the 1st time because they use RunAtLoad false
$SUDO -E $LAUNCHCTL start net.emergingthreats.blockips
#$SUDO -E $LAUNCHCTL start net.dshield.block
$SUDO -E $LAUNCHCTL start net.hphosts.hosts
$SUDO -E $LAUNCHCTL start com.github.essandess.easylist-pac
$SUDO -E $LAUNCHCTL start com.github.essandess.adblock2privoxy

$LAUNCHCTL load ~/Library/LaunchAgents/org.opensource.flashcookiedelete.plist

$SUDO $BREW services start squid
$SUDO $BREW services start privoxy


# Turn on macOS Server's adaptive firewall:
if [ -d /Applications/Server.app ]
then
    $SUDO -E /Applications/Server.app/Contents/ServerRoot/usr/sbin/serverctl enable service=com.apple.afctl
    $SUDO -E /Applications/Server.app/Contents/ServerRoot/usr/libexec/afctl -f
fi


# check after boot
/usr/local/bin/macosfortress_setup_check.sh


$CAT <<'URL_PATH_INCLUSION'
To allow URL path blocking capability in HTTPS:

    * Chrome:
      $ defaults write com.google.Chrome PacHttpsUrlStrippingEnabled -bool false

    * Firefox, about:config:
      network.proxy.autoconfig_url.include_path : true
URL_PATH_INCLUSION

exit 0
