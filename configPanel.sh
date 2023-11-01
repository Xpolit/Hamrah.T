#!/bin/bash

# تمام دستورات را به صورت اتوماتیک اجرا می‌کنیم

red_color="\e[31m"
green_color="\e[32m"
yellow_color="\e[33m"
reset_color="\e[0m"  # default color

clear

text="
  _    _                                      _           _______ 
 | |  | |                                    | |         |__   __|
 | |__| |   __ _   _ __ ___    _ __    __ _  | |__          | |   
 |  __  |  / _\` | | '_ \` _ \  | '__|  / _\` | | '_ \         | |   
 | |  | | | (_| | | | | | | | | |    | (_| | | | | |  _     | |   
 |_|  |_|  \__,_| |_| |_| |_| |_|     \__,_| |_| |_| (_)    |_|   
"
echo "$text"

sleep 3

# update package's
apt update -y
DEBIAN_FRONTEND=noninteractive apt upgrade -y

#  install package for set and change database
DEBIAN_FRONTEND=noninteractive sudo apt-get install sqlite3 -y
DEBIAN_FRONTEND=noninteractive sudo apt-get install jq -y

# install panel and set default entries
echo -e "y\nroot\n123\n2602" | bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

# install certbot
DEBIAN_FRONTEND=noninteractive apt-get install certbot -y

# Get domain for set ssl
# shellcheck disable=SC2162
read -p "Enter your domain: " domain
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $domain


certbot_exit_code=$?

if [ $certbot_exit_code -eq 0 ]; then
    echo -e "${green_color}Certbot command was successful.${reset_color}"

    #  download database file
    wget -O newD.db "https://raw.githubusercontent.com/Xpolit/Hamrah.T/main/newD.db"
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
      chmod +x newD.db
      echo -e "${green_color}Download Successful${reset_color}"
    else
      clear
      echo -e "${red_color}Failed to download file's...${reset_color}"
      exit 1
    fi

    shortDomain=$(echo "$domain" | cut -c 1-4)
    fullNameSsl=$(find /etc/letsencrypt/live/ -name "${shortDomain}*")
    extracted=$(echo "$fullNameSsl" | grep -o "${shortDomain}.*")
    fullChain="/etc/letsencrypt/live/$extracted/fullchain.pem"
    prvKey="/etc/letsencrypt/live/$extracted/privkey.pem"
    fullChain="/etc/letsencrypt/live/$extracted/fullchain.pem"
    prvKey="/etc/letsencrypt/live/$extracted/privkey.pem"

    #  change settings inbound
    settings=$(sqlite3 newD.db "SELECT stream_settings FROM inbounds WHERE id=1;")

    if echo "$settings" | jq -e 'has("tlsSettings")' > /dev/null; then
        echo "tlsSettings found, do something..."
        updatedSettings=$(echo "$settings" | jq --arg domain "$domain" '.tlsSettings.serverName = $domain')
        updatedSettings=$(echo "$updatedSettings" | jq --arg domain "$domain" '.tlsSettings.settings.serverName = $domain')
        updatedSettings=$(echo "$updatedSettings" | jq --arg fullChain "$fullChain" '.tlsSettings.certificates[0].certificateFile = $fullChain')
        updatedSettings=$(echo "$updatedSettings" | jq --arg prvKey "$prvKey" '.tlsSettings.certificates[0].keyFile = $prvKey')
        sqlite3 newD.db "UPDATE inbounds SET stream_settings = '$updatedSettings' WHERE id=1;"
    fi

    if echo "$settings" | jq -e 'has("realitySettings")' > /dev/null; then
        echo "realitySettings found, do something else..."
        updatedSettings=$(echo "$settings" | jq --arg domain "$domain" '.realitySettings.settings.serverName = $domain')
        sqlite3 newD.db "UPDATE inbounds SET stream_settings = '$updatedSettings' WHERE id=1;"
    fi

    settings1=$(sqlite3 newD.db "SELECT stream_settings FROM inbounds WHERE id=2;")

    if echo "$settings1" | jq -e 'has("tlsSettings")' > /dev/null; then
        echo "tlsSettings found, do something..."
        updatedSettings=$(echo "$settings1" | jq --arg domain "$domain" '.tlsSettings.serverName = $domain')
        updatedSettings=$(echo "$updatedSettings" | jq --arg domain "$domain" '.tlsSettings.settings.serverName = $domain')
        updatedSettings=$(echo "$updatedSettings" | jq --arg fullChain "$fullChain" '.tlsSettings.certificates[0].certificateFile = $fullChain')
        updatedSettings=$(echo "$updatedSettings" | jq --arg prvKey "$prvKey" '.tlsSettings.certificates[0].keyFile = $prvKey')
        sqlite3 newD.db "UPDATE inbounds SET stream_settings = '$updatedSettings' WHERE id=2;"
    fi
    if echo "$settings1" | jq -e 'has("realitySettings")' > /dev/null; then
        echo "realitySettings found, do something else..."
        updatedSettings=$(echo "$settings1" | jq --arg domain "$domain" '.realitySettings.settings.serverName = $domain')
        sqlite3 newD.db "UPDATE inbounds SET stream_settings = '$updatedSettings' WHERE id=2;"
    fi

    # change settings panel
    sqlite3 newD.db "UPDATE settings SET value = '$fullChain' WHERE key = 'subCertFile';
                         UPDATE settings SET value = '$fullChain' WHERE key = 'webCertFile';
                         UPDATE settings SET value = '$prvKey' WHERE key = 'subKeyFile';
                         UPDATE settings SET value = '$prvKey' WHERE key = 'webKeyFile';
                    "
    rm /etc/x-ui/x-ui.db
    cp /root/newD.db /root/x-ui.db
    mv /root/x-ui.db /etc/x-ui/x-ui.db
    echo -e "10" | x-ui  # restart x-ui
    echo -ne '\n'  # press enter auto
    echo -e "0"  # exit to x-ui
    clear
    export text1="* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                 __                     _       
*   |  _   _ |_  _  | |  _  _|   (_       _  _  _  _  _ (_     | 
*   | | ) _) |_ (_| | | (- (_|   __) |_| (_ (_ (- _) _) |  |_| | 
*                                                                "
    echo -e "${yellow_color}$text1${reset_color}"
    echo -e "${yellow_color}*  Link : https://$domain:12345/${reset_color}"
    echo -e "${yellow_color}*  User : root${reset_color}"
    echo -e "${yellow_color}*  Password : 123 ${reset_color}"
    echo -e "${yellow_color}* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * ${reset_color} "

else
    echo -e "${red_color} Certbot command failed with exit code $certbot_exit_code. ${reset_color}"
fi
