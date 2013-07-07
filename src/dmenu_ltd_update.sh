#!/bin/sh
# Copyright 2013 Yehuda Ringler - GNU General Public License v3.
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
# ((note: if on some system the .desktop extension is missing...
#   but thats not likely enough to worry about))
clear_path_desktop="-e s|.*/\(.*\)\.desktop|\1|"

## Example grep output:
 # /usr/share/applications/asunder.desktop:Exec=asunder

# I only need to do this for the menu items generated from $appinfo
# But the stuff in custom_dir runs itself
gen_exec () {
	cd $auto_dir
	printf "#!/bin/sh\n" > $auto_exec
	printf 'case $1 in\n' >> $auto_exec

	## the last two -e are for special cases: the first for ""%f"" or %t
	#  which are part of the .desktop specification, but I have no use for.
	## the second removes sh -c "<command>", leaving only <command>
	#  keeping it as is gave me poor behavior... I never did find out why.
	## (I use the /path/*.desktop for $appinfo because I'm nervous that some
	#  distro may have some other stuff there, which might cause weird bugs.)
	grep ^Exec $appinfo/*.desktop | 
		sed $clear_path_desktop -e "s/:Exec=/ /" \
			-e "s/\([^ ]*\) \(.*\)/\1) \2 ;;/" \
			-e 's/"*%[[:alpha:]]"*//' \
			-e 's/sh -c "\(.*\)"/\1/' >> $auto_exec
	echo esac >> $auto_exec

	chmod +x $auto_exec
}

dmenu_ltd_update () {
	## if ls . and appinfo in one shot, extra stuff is printed 
	#  dividing the folders, which will end up in the menu
	(ls -1 $custom_dir; ls -1 $appinfo/*.desktop) \
		| sed $clear_path_desktop | sort | uniq > $ltd_menu
}

# (note:sort_categories ensures that an over-ride in custom_dir
# won't result in a menu-item being doubled)
dmenu_ltd_cat_update () {
	# my fear of rm is evident here
	rm -r $auto_dir/categories 2>&-
	mkdir $auto_dir/categories
	# this cd enables the simplicity of the sed generated tee below
	cd $auto_dir/categories

	## there are no spaces in category names. (yay!)

	## I can destroy .*/ with impunity, because there is no way 
	#  that it shows up anywhere except the path
	# (I only have to worry in gen_exec - the command could be anything)

	## Its needed because clear_path_desktop needs a .desktop match
	 # so it doesn't clear the path in custom_dir
	## Generalizing clear_path_desktop may lead to 
	#  strangeness = weird bugs = touch the script and it blows up
	#  but abandoning leads to repetition. What I have is (I think) a 
	#  reasonable compromise

	## the # is for custom_dir, contents of which are shell scripts, 
	# 	ergo Categories commented out
	## the [[:blank:]#]* is to avoid unneccesary restrictions on custom files
	## that little : over there follows file name in grep output (see below)

	## uses tee to write the program name to the category files
	# 	example: echo asunder | tee AudioVideo Audio

	## Example grep output:
	#  /usr/share/applications/asunder.desktop:Categories=AudioVideo;Video
	ls $auto_dir/categories
	grep Categories  $custom_dir/* $appinfo/* 2>&- \ | sed \
		$clear_path_desktop -e "s|.*/||" \
		-e "s/:[[:blank:]#]*Categories=/ /" -e "s/;/ /g" \
		-e "s/\(^[^ ]*\)/echo \1 | tee -a/" | sh >&-
}

remove_extra_categories () {
	cd $auto_dir/categories
	rm -f `cat $dmenu_ltd_dir/destroy.txt`
}

sort_categories () {
	# there has to be a cleaner way of doing this ...
	cd $auto_dir/categories
	tmp=`mktemp`
	# the uniq is for if a program is overwritten in custom_dir
	for file in *; do
		sort $file | uniq > $tmp 
		mv $tmp $file
	done
}

# print name of any programs that have a Category line in their .desktop file
# but do not show up in categories.
check_categories () {
	# list of all programs that currently appear in the menu
	cur_list=`mktemp`
	# list of those which *should* appear
	should_list=`mktemp`
	missing_list=`mktemp`

	cat $auto_dir/categories/* | sort | uniq > $cur_list
	# grep -l: print name of file, which is name of program
	# the -e clears path from customdir applications
	grep -l Categories $appinfo/*.desktop $custom_dir/* \
		| sed $clear_path_desktop -e "s/.*custom\///" | sort | uniq \
		> $should_list
	diff -U 0 $cur_list $should_list > $missing_list

	if [ $(wc -l $missing_list | cut -d ' ' -f 1) -gt  0 ]; 
	then 
		mv $missing_list ~/missing_list
		cat << EOF
Look in ~/missing_list for a list of programs that 
should show in dmenu_ltd_cat_run.sh but do not.
Example of how to correct: 
If firefox is shown as missing, open $appinfo/firefox.desktop
Go to the line beggining with the word Categories. 
Remove at least one word in the ; seperated list from the 
$dmenu_ltd_dir/destroy.txt
If you can't find the file in $appinfo (in this example thats unlikely 
in most circumstances) look for $custom_dir/firefox
Then run me again.
If its not there either, then theres a bug over here somewhere. Oops.
EOF
	fi
}

gen_exec
dmenu_ltd_update
dmenu_ltd_cat_update
remove_extra_categories
sort_categories
check_categories
