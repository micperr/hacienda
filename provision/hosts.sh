#!/usr/bin/env bash

sudo sed -i '/### HACIENDA-SITES-BEGIN/,/### HACIENDA-SITES-END/d' /etc/hosts
printf "### HACIENDA-SITES-BEGIN\n### HACIENDA-SITES-END\n" | sudo tee -a /etc/hosts >/dev/null

if [[ $1 && $2 ]]; then

  IP=$1
  shift
  HOSTS=$@

  for HOSTNAME in $HOSTS; do
    if [ -n "$(grep [^\.]$HOSTNAME /etc/hosts)" ]; then
      echo "$HOSTNAME already exists:"
      printf "$(grep [^\.]$HOSTNAME /etc/hosts)\n\n"
    else
      sudo sed -i "/### HACIENDA-SITES-BEGIN/c\### HACIENDA-SITES-BEGIN\\n$IP $HOSTNAME" /etc/hosts

      if ! [ -n "$(grep [^\.]$HOSTNAME /etc/hosts)" ]; then
        echo "Failed to add $HOSTNAME, Try again!"
      else
        echo "Added $HOSTNAME"
      fi
    fi
  done

else
  echo "Error: missing required parameters."
  echo "Usage: "
  echo "hosts.sh ip domain"
fi