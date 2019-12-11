#!/bin/bash

# Author: Alex Assante
# Linux Project

arg_num=$#
arg1=$1
arg2=$2
arg3=$3
arg4=$4
args=$@

# initializes, checks for arguments and counts completed items
init () {
	check_directories "todo" "todo_completed"
	check_stdin
	count_incomplete
	count_completed

	if [ $arg_num -ne 0  ]; then
		menu_mode=0
		use_args
	else
		menu_mode=1
		display_menu
	fi
}


check_stdin () { # checks if user is piping information in and reads if so
	if [ -p /dev/stdin ]; then
		PIPE_IN=$( cat )
	else
		PIPE_IN=""
	fi
}

# checks if directory for to do and todo_completed exist, if not makes them
check_directories () {
	if [ ! -d "$1" ]; then
		mkdir "$1"
	fi
	if [ ! -d "$2" ]; then
		mkdir "$2"
	fi
}

# checks if directory is empty and if not then counts
count_incomplete () {
	if [ "$(ls -A todo)" ]; then
		COUNT=0
		for t in todo/*.txt
		do
			COUNT=$((COUNT+1))
		done
	fi
}

# checks if empty then if not counts
count_completed () {
	if [ "$(ls -A todo_completed)" ]; then
		C_ITEM_COUNT=0
		for t in todo_completed/*.txt
		do
			C_ITEM_COUNT=$((C_ITEM_COUNT+1))
		done
	fi
}

use_args () {
	if [[ "$arg1" == "list" ]]; then
		if [[ "$arg2" == "completed" ]]; then
			list_items "todo_completed"
		else
			list_items "todo"
		fi
	elif [[ "$arg1" == "complete" ]]; then
		complete_item $((arg2))
	elif [[ "$arg1" == "add" ]]; then
		add_item "$arg2" "$PIPE_IN"
	elif [[ "$arg1" == "info" ]]; then
		more_info "$arg2"
	else
		display_help
	fi
}


display_help () {
	echo -e "-----------------------\n"
	echo -e "Commands:\n"
	echo "help: displays help message"
	echo "list: lists all uncompleted items"
	echo "complete [number]: completes item of the chosen number"
	echo "list completed: lists all items in the completed todo list"
	echo "add [title]: adds item with the title to the todo list"
	echo "add [title] cont.: information piped in becomes the description"
	echo "info [number]: displays the title and description of the item"
	echo -e "\n-----------------------\n"
}

list_items () {
	echo -e "----------------------"	
	echo "Current items in list:"
	if [ "$(ls -A $1)" ]; then
	COUNT=0
		for t in $1/*
		do
			COUNT=$((COUNT+1))
		# head -n 1 $t means the first line in the current file (title)
			echo "$COUNT. $(head -n 1 $t)"	
		done
	else
		COUNT=0
		echo "The list is empty."
	fi
}

# all menu options (Menu Mode)
list_options () {
	echo -e "\nWhat would you like to do?"
	# COUNT is a global variable by default
	echo "1-$COUNT. See more info for this item"
	echo "A. Mark item as complete"
	echo "B. Add new item"
	echo -e "C. See completed items\n"
	echo -e "Q. Quit\n"
}

# take user input (Menu Mode)
read_input () {
	read -p "Enter your choice: " CHOICE
}

# continue prompt (Menu Mode)
cont () {	
	echo -e "----------------------"
	read -p "Continue? (Y/N) " CONT 
	if [ $CONT == 'Y' ]; then
		display_menu
	else
		quit
	fi
}

# moves the item into todo_completed and adjusted filenames of remaining files
complete_item () {
	# COMPLETE AN ITEM
	C=$1
	# If argument, C, is a number, less than or equal to the amount of items in list, and greater than 0
	if [[ $((C)) == $C ]] && [[ $C -le $COUNT ]] && [[ $C -gt 0 ]]; then
		C_ITEM_COUNT=$((C_ITEM_COUNT+1))
		COUNT=$((COUNT-1))
		cd todo
		i=0
		for f in *.txt; 
		do
			i=$((i+1))
			# If current file number is the choice, move it
			if [[ $((i)) == $((C)) ]]; then
				mv "$C.txt" "../todo_completed/$C_ITEM_COUNT.txt"
# If the current file number is greater than the choice, move it forward by 1
			elif [[ $i -gt $C ]]; then
				if [ $((i)) == 1 ]; then
					# j is the new filename value
					j=$((i))
				else
					j=$((i-1))
				fi
				# rename current file to new 'j' filename
				mv "$f" "$j.txt"
			fi	
		done
		cd ../
		if [[ $menu_mode == 1 ]]; then
			display_menu	
		fi
	else
		no_option_error
	fi
}


# adds an item to the todo list plus permissions
# $1 is title and $2 is description
add_item () {
	COUNT=$((COUNT+1))
	cd todo
	touch $COUNT.txt
	chmod 700 $COUNT.txt
	echo "$1" >> "$COUNT.txt"
	echo "------" >> "$COUNT.txt"
	echo "$2" >> "$COUNT.txt"	
	cd ../
	if [[ $menu_mode == 1 ]]; then
		display_menu
	fi
}

# outputs all file contents
# $1 is file that is read
more_info () {
	if [[ $1 -gt 0 ]] && [[ $1 -le $COUNT ]]; then
		while IFS= read -r line
		do
			echo "$line"
		done < "todo/$1.txt"
		if [[ $menu_mode == 1 ]]; then
			cont
		fi
	elif [ $((COUNT)) == 0 ]; then
		list_empty_error
	else
		no_option_error
	fi
}

# user $CHOICE (processing) (Menu Mode)
use_input () {
	if [ $CHOICE == 'A' ]; then
		# COMPLETE AN ITEM
		if [ $((COUNT)) -gt 0 ]; then
			list_items "todo"
			read -p "Which number? (1-$COUNT) " C
			complete_item $C
		else
			list_empty_error
		fi
	elif [ $CHOICE == 'B' ]; then
		# ADD ITEM
		read -p "Title? " TITLE
		read -p "Description? " DESC
		add_item "$TITLE" "$DESC"
	elif [ $CHOICE == 'C' ]; then
		# SHOW COMPLETED
		list_items "todo_completed"
		cont
	elif [ $CHOICE == 'Q' ]; then
		# QUIT
		quit
	elif [ $((CHOICE)) == $CHOICE ]; then 
		# MORE INFO ON ITEM
	# If choice evaluates mathematically to itself, then it is a number value
		# if choice number is within range from count
		if [ $((CHOICE)) -le $COUNT ]; then
			more_info "$CHOICE"
		else
			no_option_error
		fi
	else
		# NO OPTION
		no_option_error
	fi
}

# Error for empty list
list_empty_error () {
	generic_error "list is empty"
}
# Error for invalid option selected
no_option_error () {
	generic_error "not an option"
}
# Formatting for error message and menu display
# Takes $1 as error message
generic_error () {
	echo -e "----------------------"		
	echo -e "\nERROR: $1\n"
	if [[ $menu_mode == 1 ]]; then
		display_menu
	else
		display_help
	fi
}

# exits
quit () {
	exit 1
}

# display the menu and process it (Menu Mode)
display_menu () {
	list_items "todo" 
	list_options
	read_input
	use_input
}

# initialize the program
init

