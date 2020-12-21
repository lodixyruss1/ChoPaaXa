#!/bin/bash

#set localtime
#ln -fs /usr/share/zoneinfo/Asia/Manila /etc/localtime

#####################
### Configuration ###
#####################
VPN_Owner='Firenet Philippines';
VPN_Name='FirenetVPN';
Filename_alias='firenet';

### Added Server ports
Socks_port='885';
SSH_viaAuto='888';
Socks2_port='886';
Socks3_port='887';

### Default Server ports, Please dont change this area
OpenVPN_TCP_Port='110';
OpenVPN_UDP_Port='25222';
OpenVPN_TCP_EC='25980';
OpenVPN_UDP_EC='25985';
OpenVPN_TCP_OHP='8087';
OpenVPN_OHP_EC='8088';
Dropbear_OHP='8085';
SSH_viaOHP='8086';
SSH_Extra_Port='22';
SSH_Extra_Port='225';
Squid_Proxy_2='8000';
Squid_Proxy_2='8080';
SSL_viaOpenSSH1='443';
SSL_viaOpenSSH2='444';
Dropbear_Port1='550';
Dropbear_Port2='555';

#####################
#####################

function ip_address(){
  local IP="$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )"
  [ -z "${IP}" ] && IP="$( curl -4 -s ipv4.icanhazip.com )"
  [ -z "${IP}" ] && IP="$( curl -4 -s ipinfo.io/ip )"
  [ ! -z "${IP}" ] && echo "${IP}" || echo
} 
MYIP=$(ip_address)

#installing ohp
wget https://github.com/lfasmpao/open-http-puncher/releases/download/0.1/ohpserver-linux32.zip
unzip ohpserver-linux32.zip
chmod 755 ohpserver
sudo mv ohpserver /usr/local/bin/

#Adding Socks
wget -O /home/proxydirect.py "https://raw.githubusercontent.com/lodixyruss1/ChoPaaXa/master/socks1"

sed -i "s|Socks_port|$Socks_port|g" "/home/proxydirect.py"
sed -i "s|SSH_Extra_Port|$SSH_Extra_Port|g" "/home/proxydirect.py"
sed -i "s|VPN_Name|$VPN_Name|g" "/home/proxydirect.py"
sed -i "s|OpenVPN_TCP_Port|$OpenVPN_TCP_Port|g" "/home/proxydirect.py"

#Adding Autorecon Socks 
wget -O /home/proxydirect2.py "https://raw.githubusercontent.com/lodixyruss1/ChoPaaXa/master/socks2"

sed -i "s|Socks2_port|$Socks2_port|g" "/home/proxydirect2.py"
sed -i "s|SSH_Extra_Port|$SSH_Extra_Port|g" "/home/proxydirect2.py"
sed -i "s|VPN_Name|$VPN_Name|g" "/home/proxydirect2.py"
sed -i "s|OpenVPN_TCP_Port|$OpenVPN_TCP_Port|g" "/home/proxydirect2.py"

#Adding OVPN Autorecon Socks 
wget -O /home/proxydirect3.py "https://raw.githubusercontent.com/lodixyruss1/ChoPaaXa/master/socks3"

sed -i "s|Socks3_port|$Socks3_port|g" "/home/proxydirect3.py"
sed -i "s|SSH_Extra_Port|$SSH_Extra_Port|g" "/home/proxydirect3.py"
sed -i "s|VPN_Name|$VPN_Name|g" "/home/proxydirect3.py"
sed -i "s|OpenVPN_TCP_Port|$OpenVPN_TCP_Port|g" "/home/proxydirect3.py"

cat <<'socks' > /etc/systemd/system/socks.service
[Unit]
Description=Daemonize socks

[Service]
Type=simple
ExecStart=/usr/bin/python /home/proxydirect.py

[Install]
WantedBy=multi-user.target
socks

#adding autorecon
cat <<'ohpssh2' > /etc/systemd/system/ohplenz.service
[Unit]
Description=Daemonize OpenHTTP Puncher Autorecon
Wants=network.target
After=network.target

[Service]
ExecStart=/usr/local/bin/ohpserver -port SSH_viaAuto -proxy 127.0.0.1:Squid_Proxy_2 -tunnel IP-ADDRESS:SSH_Extra_Port
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
ohpssh2

sed -i "s|SSH_viaAuto|$SSH_viaAuto|g" "/etc/systemd/system/ohplenz.service"
sed -i "s|Squid_Proxy_2|$Squid_Proxy_2|g" "/etc/systemd/system/ohplenz.service"
sed -i "s|IP-ADDRESS|$MYIP|g" "/etc/systemd/system/ohplenz.service"
sed -i "s|SSH_Extra_Port|$SSH_Extra_Port|g" "/etc/systemd/system/ohplenz.service"

#adding autorecon socks
cat <<'socks1' > /etc/systemd/system/sockslenz.service
[Unit]
Description=Daemonize Socks Autorecon
Wants=network.target
After=network.target

[Service]
ExecStart=/usr/bin/python /home/proxydirect2.py
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
socks1

#adding ovpn autorecon socks
cat <<'socks2' > /etc/systemd/system/sockslenz2.service
[Unit]
Description=Daemonize Socks Autorecon
Wants=network.target
After=network.target

[Service]
ExecStart=/usr/bin/python /home/proxydirect3.py
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
socks2

sudo systemctl daemon-reload
sudo systemctl start socks
sudo systemctl enable socks
sudo systemctl start ohplenz
sudo systemctl enable ohplenz
sudo systemctl start sockslenz
sudo systemctl enable sockslenz
sudo systemctl start sockslenz2
sudo systemctl enable sockslenz2

#creating autorecon script
cat <<'autorecon' > /home/lenz
sudo systemctl restart ohplenz
sudo systemctl restart sockslenz
sudo systemctl restart sockslenz2
sleep 60
sudo systemctl restart ohplenz
sudo systemctl restart sockslenz
sudo systemctl restart sockslenz2

autorecon

#adding autorecon cron
cat <<'autorecon2' > /etc/cron.d/autorecon
*/2 *   * * *   root    bash /home/lenz
autorecon2

#Fixing Multilogin Script
cat <<'Multilogin' >/usr/local/sbin/set_multilogin_autokill_lib
#!/bin/bash

clear

MAX=1
if [ -e "/var/log/auth.log" ]; then
        OS=1;
        LOG="/var/log/auth.log";
fi
if [ -e "/var/log/secure" ]; then
        OS=2;
        LOG="/var/log/secure";
fi

if [ $OS -eq 1 ]; then
	service ssh restart > /dev/null 2>&1;
fi
if [ $OS -eq 2 ]; then
	service sshd restart > /dev/null 2>&1;
fi
	service dropbear restart > /dev/null 2>&1;
				
if [[ ${1+x} ]]; then
        MAX=$1;
fi

        cat /etc/passwd | grep "/home/" | cut -d":" -f1 > /root/user.txt
        username1=( `cat "/root/user.txt" `);
        i="0";
        for user in "${username1[@]}"
			do
                username[$i]=`echo $user | sed 's/'\''//g'`;
                jumlah[$i]=0;
                i=$i+1;
			done
        cat $LOG | grep -i dropbear | grep -i "Password auth succeeded" > /tmp/log-db.txt
        proc=( `ps aux | grep -i dropbear | awk '{print $2}'`);
        for PID in "${proc[@]}"
			do
                cat /tmp/log-db.txt | grep "dropbear\[$PID\]" > /tmp/log-db-pid.txt
                NUM=`cat /tmp/log-db-pid.txt | wc -l`;
                USER=`cat /tmp/log-db-pid.txt | awk '{print $10}' | sed 's/'\''//g'`;
                IP=`cat /tmp/log-db-pid.txt | awk '{print $12}'`;
                if [ $NUM -eq 1 ]; then
                        i=0;
                        for user1 in "${username[@]}"
							do
                                if [ "$USER" == "$user1" ]; then
                                        jumlah[$i]=`expr ${jumlah[$i]} + 1`;
                                        pid[$i]="${pid[$i]} $PID"
                                fi
                                i=$i+1;
							done
                fi
			done
        cat $LOG | grep -i sshd | grep -i "Accepted password for" > /tmp/log-db.txt
        data=( `ps aux | grep "\[priv\]" | sort -k 72 | awk '{print $2}'`);
        for PID in "${data[@]}"
			do
                cat /tmp/log-db.txt | grep "sshd\[$PID\]" > /tmp/log-db-pid.txt;
                NUM=`cat /tmp/log-db-pid.txt | wc -l`;
                USER=`cat /tmp/log-db-pid.txt | awk '{print $9}'`;
                IP=`cat /tmp/log-db-pid.txt | awk '{print $11}'`;
                if [ $NUM -eq 1 ]; then
                        i=0;
                        for user1 in "${username[@]}"
							do
                                if [ "$USER" == "$user1" ]; then
                                        jumlah[$i]=`expr ${jumlah[$i]} + 1`;
                                        pid[$i]="${pid[$i]} $PID"
                                fi
                                i=$i+1;
							done
                fi
        done
        j="0";
        for i in ${!username[*]}
			do
                if [ ${jumlah[$i]} -gt $MAX ]; then
                        date=`date +"%Y-%m-%d %X"`;
                        echo "$date - ${username[$i]} - ${jumlah[$i]}";
                        echo "$date - ${username[$i]} - ${jumlah[$i]}" >> /root/log-limit.txt;
                        kill ${pid[$i]};
                        pid[$i]="";
                        j=`expr $j + 1`;
                fi
			done
        if [ $j -gt 0 ]; then
                if [ $OS -eq 1 ]; then
                        service ssh restart > /dev/null 2>&1;
                fi
                if [ $OS -eq 2 ]; then
                        service sshd restart > /dev/null 2>&1;
                fi
                service dropbear restart > /dev/null 2>&1;
                j=0;
		fi
Multilogin

#Deleting patch file
cd
rm -rf ocs_patch.sh
clear

echo "
############################################################
# SERVER INFO:
# SSH Server: $SSH_Extra_Port                              
# SSH via OHP: $SSH_viaOHP                                 
# Socks Port: $Socks_port                                  
# Socks Port(Autorecon): $Socks2_port            
# Socks Port OVPN-TCP(Autorecon): $Socks3_port     
# SSH via OHP(Autorecon): $SSH_viaAuto                     
# SSL Server Port: $SSL_viaOpenSSH1, $SSL_viaOpenSSH2                         
# Dropbear Port: $Dropbear_Port1, $Dropbear_Port2 
# Dropbear via OHP: $Dropbear_OHP
# OpenVPN Server (TCP): $OpenVPN_TCP_Port                  
# OpenVPN Server (UDP): $OpenVPN_UDP_Port  
# OpenVPN Server (TCP EC): $OpenVPN_TCP_EC
# OpenVPN Server (UDP EC): $OpenVPN_UDP_EC
# OpenVPN Server (TCP OHP): $OpenVPN_TCP_OHP
# Squid Proxy Server: $Squid_Proxy_1, $Squid_Proxy_2       
# OpenVPN Config: http://$(curl -4s http://ipinfo.io/ip):86
#
# Extra Port
# OpenVPN Server (SSL): 587
# Globe TM NoLoad (if activated): 80
#
# BonChan Patch Script v1.2        
# Authentication file system                
# Setup by: FIRENET PHILIPPINES             
# Created by: Lenz Scott Kennedy
# Modified by: FakeNet VPN     
#
# Paymaya: 09254497338
############################################################";

echo '
   ___________  _____  ____________    __   _____  ______
  / __/  _/ _ \/ __/ |/ / __/_  __/___/ /  / __/ |/ /_  /
 / _/_/ // , _/ _//    / _/  / / /___/ /__/ _//    / / /_
/_/ /___/_/|_/___/_/|_/___/ /_/     /____/___/_/|_/ /___/
                                                         
';

echo 'rebooting....';
sleep 5
reboot
