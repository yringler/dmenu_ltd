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

command=$(dmenu $@ < $ltd_menu)

# tries custom first - this allows to overide a command from auto
if [ "$command" ]; then
	$custom_dir/$command 2>&- || $auto_exec $command
fi
