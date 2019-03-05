#! /bin/bash

raw_input=`xclip -selection p -o`
execute='xdg'

for i in "$@"
do
case $i in
    -t|--terminal)
	    execute='terminal'
	    shift # past argument=value
	    ;;
    -w|--webfind)
	    execute='webfind'
	    shift # past argument=value
	    ;;
    -x|--xdg)
	    execute='xdg'
	    shift # past argument=value
	    ;;
    -h|--help)
	    echo '-p, --primary   	use primary selection instead of selection (default)'
	    echo '-c, --clipboard   use clipboard instead of selection'
	    echo '-x, --xdg      	open selection/clipboard by xdg-open (default) '
	    echo '-t, --terminal 	open selection/clipboard by terminal'
	    echo '-w, --webfind     open selection/clipboard in searchengine'
	    shift # past argument=value
	    ;;
    -c|--clipboard)
		raw_input=`xclip -selection c -o`
	    shift # past argument=value
	    ;;
    -p|--primary)
	    shift # past argument=value
	    ;;
esac
done

protocol=$(echo ${raw_input} | cut -d':' -f1)

# fix protocol if protocol contains a windows driveletter
case ${protocol} in
	j|J)
		# replace server and share
		target=$(echo "${raw_input}" | sed -r -e 's/\\/\//g;s#j:#smb://server/share#gi')
		protocol='smb'
	;;
	*)
		target=${raw_input}
	;;
esac

case ${protocol} in
	smb)
		#target=$(echo "${target}" | sed -r -e 's/\\/\//g')
		gio info "${target}" &> /dev/null || gio mount "${target}"
		if [[ "$?" != "0" ]]; then
			notify-send 'mounted' 'trying anonymous'
			gio mount -a "${target}"
			if [[ "$?" != "0" ]]; then
				zenity --error --text="${target}" --title='Cannot mount directory!'
				exit
			fi
		fi
		gio_info=$(gio info "${target}" | grep filesystem | cut -d':' -f4- | tr -d '[:space:]')
		path=$(echo "${target}" | cut -d'/' -f5-)
		mount_path="/run/user/`/usr/bin/id -u`/gvfs/${gio_info}/${path}"
	;;
	*)
		mount_path="${target}"
esac

case ${execute} in
	xdg)
		sleep 1
		xdg-open "${target}" &
		;;
	webfind)
		search=$(echo "${raw_input}" | sed -r -e 's/ /\+/g')
		xdg-open "https://www.google.com/search?q=${search}" &
		;;
	terminal)
		cd "${mount_path}"
		echo 'in here'
		pwd
		gnome-terminal &
		;;
esac
