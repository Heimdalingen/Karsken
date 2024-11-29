#!/bin/bash 

apache_run() {
    echo "apache is running - $(date)" >> /home/chanyas/Documents/apache.logs
}

apache_norun() {
    echo "apache is not running - $(date)" >> /home/chanyas/Dcouments/apache.logs
}

apc() {
    if systemctl is-active --quiet apache2; then 
        running 
    else 
        notrunning
    fi;
}

apc 
