#!/bin/bash

TITLE="Website Health Monitoring System"
SITES_FILE="../config/sites.txt"
LOGFILE="../logs/monitor.log"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m"

log(){
    echo -e "$1" | tee -a "$LOGFILE"
}

check_reachability(){
    ping -c1 -W1 "$1" &>/dev/null
}

check_http(){
    curl -o /dev/null -s -w "%{http_code}" --max-time 5 "https://$1"
}

scan_ports(){
    nmap -p 80,443 "$1" 2>/dev/null | grep open | awk '{print $1}'
}

echo "==============================" | tee -a $LOGFILE
echo "$TITLE - $(date)" | tee -a $LOGFILE
echo "==============================" | tee -a $LOGFILE

while read -r web
do
    log "\nChecking: $web"

    if check_reachability "$web"; then
        log "${GREEN}$web reachable${NC}"

        statuscode=$(check_http "$web")

        if [ "$statuscode" = "200" ]; then
            log "${GREEN}HTTP 200 OK${NC}"

            ports=$(scan_ports "$web")

            if [ -n "$ports" ]; then
                log "${GREEN}Open Ports:${NC} $ports"
            else
                log "${YELLOW}No open ports${NC}"
            fi

        elif [ "$statuscode" = "301" ] || [ "$statuscode" = "302" ]; then
            log "${YELLOW}Redirected ($statuscode)${NC}"
        else
            log "${RED}HTTP Error: $statuscode${NC}"
        fi
    else
        log "${RED}$web host down — skipped${NC}"
    fi

    log "----------------------------------"

done < "$SITES_FILE"



