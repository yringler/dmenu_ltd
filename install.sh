#!/bin/sh
# Copyright 2013 Yehuda Ringler - GNU General Public License v3.

install src/dmenu_ltd_update.sh /usr/bin/
install src/dmenu_ltd_run.sh /usr/bin/
install src/dmenu_ltd_cat_run.sh /usr/bin/

install -d /usr/share/dmenu_ltd/
install   src/destroy.txt  /usr/share/dmenu_ltd/

install -d /usr/share/doc/dmenu_ltd/
install   README  /usr/share/doc/dmenu_ltd/

install src/dmenu_ltd.cfg /etc/
