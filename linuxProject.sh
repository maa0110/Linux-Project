#!/bin/bash

# Author: Alex Assante
# Linux Project

arg_num=$#
arg1=$1
arg2=$2
arg3=$3
arg4=$4
args=$@

initialize() {
	check_directories "todo" "todo_completed"
	check_stdin
	count_incomplete
	count_completed

	if [ $arg_num -ne 0 ]; then 
		menu_mode=0
		use_args
	else
		menu_mode=1
		display_menu
	fi
}
