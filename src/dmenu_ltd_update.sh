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

. /etc/dmenu_ltd.cfg
if [ ! -d $dmenu_ltd_dir ]; then mkdir $dmenu_ltd_dir; fi
if [ ! -d $custom_dir ]; then mkdir $custom_dir; fi
if [ ! -d $auto_dir ]; then mkdir $auto_dir; fi
if [ ! -e $dmenu_ltd_dir/destroy.txt ]; then 
	cp /usr/share/dmenu_ltd/destroy.txt $dmenu_ltd_dir
fi

# used througout the script
clear_path_desktop="-e s|.*/\(.*\)\.desktop|\1|"

## Example grep output:
 # /usr/share/applications/asunder.desktop:Exec=asunder

# I only need to do this for the menu items generated from $appinfo
# But the stuff in custom_dir: name of file = name of menu item = shell script
# (I think this explanation is pretty lousy...)
function gen_exec {
	cd $auto_dir
	echo -e "#!/bin/bash\n" > $auto_exec
	echo -e 'case $1 in' >> $auto_exec

	## the last two -e are for special cases: the first for ""%f"" or %t
	#  which are part of the .desktop specification, but I have no use for.
	## the second removes sh -c "<command>", leaving only <command>
	#  keeping it as is gave me poor behavior... I never did find out why.
	## custom_dir has nothing to do here - how to execute in file
	grep ^Exec $appinfo/*.desktop | 
		sed $clear_path_desktop -e "s/:Exec=/ /" \
			-e "s/\([^ ]*\) \(.*\)/\1) \2 ;;/" \
			-e 's/"*%[[:alpha:]]"*//' \
			-e 's/sh -c "\(.*\)"/\1/' >> $auto_exec
	echo esac >> $auto_exec

	chmod +x $auto_exec
}

function dmenu_ltd_update {
	# cd to avoid the path in ls custom_dir
	cd $custom_dir
	## (I use the /path/*.desktop for $appinfo because I'm nervous that some)
	#  distro may have some other stuff there, which might cause weird bugs.
	## if ls . and appinfo in one shot, get extra stuff dividing the folders
	( ls -1 . ; ls -1 $appinfo/*.desktop) | sed $clear_path_desktop \
	| sort | uniq > $ltd_menu
}

## Example grep output:
 # /usr/share/applications/asunder.desktop:Categories=AudioVideo,Video

function dmenu_ltd_cat_update {
	# my fear of rm is evident here
	rm -r $auto_dir/categories 2>&-
	mkdir $auto_dir/categories
	cd $auto_dir/categories

	## there are no spaces in category names. (yay!)

	## I can destroy .*/ with impunity, because there is no way 
	#  that it shows up anywhere except the path
	# (I only have to worry in gen_exec - the command could be anything)

	## Its needed because clear_path_desktop needs a .desktop match
	## Generalizing clear_path_desktop may lead to 
	#  strangeness += weird bugs = touch the script and it blows up
	#  but abandoning leads to repetition. What I have is (I think) a 
	#  reasonable compromise

	## the # is for custom_dir, contents of which are shell scripts, 
	# 	ergo Categories commented out
	## the [[:blank:]#]* is to avoid unneccesary restrictions on custom files
	## that little : over there follows file name in grep output (see above)

	## uses tee to write the program name to the category files
	# 	example: echo asunder | tee AudioVideo Audio
	grep Categories  $custom_dir/* $appinfo/* 2>&- \ | sed \
		$clear_path_desktop -e "s|.*/||" \
		-e "s/:[[:blank:]#]*Categories=/ /" -e "s/;/ /g" \
		-e "s/\(^[^ ]*\)/echo \1 | tee -a /" | sh >-
}

function sort_categories {
	# there has to be a cleaner way of doing this ...
	cd $auto_dir/categories
	tmp=`mktemp`
	for file in *; do
		# the uniq is for if a program is overwritten in custom_dir
		sort $file | uniq > $tmp 
		mv $tmp $file
	done
}

function remove_extra_categories {
	cd $auto_dir/categories
	rm -f `cat $dmenu_ltd_dir/destroy.txt`
}

# print name of any programs that have Category line in their .desktop file...
# but do not show up in categories.
function check_categories {
	cur_list=`mktemp`
	should_list=`mktemp`
	missing_list=`mktemp`

	cat $auto_dir/categories/* | sort | uniq > $cur_list
	grep -l Categories $appinfo/*desktop $auto_dir/categories/* \
		| sed $clear_path_desktop | sort | uniq \
		> $should_list
	diff $cur_list $should_list -U 0 > $missing_list

	if ! [ `wc -l $missing_list` -gt  3 ]; 
	then 
		mv $missing_list ~/${missing_list##.*/}
		echo Look in ~/${missing_list##.*/} for a list of programs that should show in dmenu_ltd_cat_run.sh but do not.
		echo $appinfo contains files that will tell you the categories programs belong to. Look in the appropriately named file there, in the line beggining Category, and remove at least one name in that list from $dmenu_ltd_dir/destroy.txt. Then run me again.
	fi
}

gen_exec
dmenu_ltd_update
dmenu_ltd_cat_update
sort_categories
remove_extra_categories
check_categories
