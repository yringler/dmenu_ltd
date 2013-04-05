#!/bin/sh
#Copyright 2013 Yehuda Ringler - GNU General Public License v3.
# This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Usage: all arguments are passed to dmenu
. /etc/dmenu_ltd.cfg

while true
do
	# -i makes dmenu not distinguish bettween upper and lower case
	# category names start with an uppercase, but its annoying to hit shift
	menu=$(ls $auto_dir/categories | dmenu -i $@ )
	
	# if the user hit escape while dmenu was running
	if [ ! $menu ]; then exit 0; fi

	command=$((cat $auto_dir/categories/$menu; echo back) | dmenu $@)
	if [ ! $command ]; then
		exit 0
	elif [ $command == back ]; then
		# re-display categories
		continue
	else
		$custom_dir/$command 2>&- || $auto_exec $command
		exit 0
	fi
done
