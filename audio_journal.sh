#!/bin/bash
# By logan
# version - now organised into year and month
# todo - archive functionality

# Function to record an audio entry
record_entry() {
  timestamp=$(date +%Y-%m-%d_%H-%M-%S)
  month=$(date +%m)
  year=$(date +%Y)
  entry_dir="entries/$year/$month"
  entry_file="$entry_dir/$timestamp.wav"
  title=$(whiptail --inputbox "Enter entry title" 10 30 3>&1 1>&2 2>&3)
  title_inputbox_status=$?

  if [ -z "$title" ]; then
    return
  elif [ $title_inputbox_status = 0 ]; then    
    title=$(echo "$title" | sed -E 's/^/   /')
    title=$(echo "$title" | sed -E 's/ /_/g')

    # truncate title to 28 chars long
    title=${title:0:28}

    mkdir -p "$entry_dir"
    echo "$title" > "$entry_dir/$timestamp.txt"
    arecord -d 600 -f cd -r 11025 "$entry_file"
    ffmpeg -i "$entry_file" "${entry_file%.wav}.mp3"
    rm "$entry_file"
    echo "Entry recorded as ${entry_file%.wav}.mp3 with title: $title"
  fi
}

# Function to list recorded entries
list_entries() {
  entries=$(find entries -type f -name "*.mp3" | sort -r)
  if [ -z "$entries" ]; then
    return 1
  fi
  options=""
  for entry in $entries; do
    title=$(cat "${entry%.mp3}.txt")
    options="$options $entry $title \n"
  done
  echo -e "$options"
}

# Function to navigate subfolders and select an entry
select_entry() {
  years=$(ls entries)
  selected_year=$(whiptail --title "Audio Journal" --menu "Select a year" 20 50 10 $(for year in $years; do echo "$year [Year]"; done) 3>&1 1>&2 2>&3)
  if [ $? != 0 ]; then
    return 1
  fi

  months=$(ls entries/$selected_year)
  selected_month=$(whiptail --title "Audio Journal" --menu "Select a month" 20 50 10 $(for month in $months; do echo "$month [Month]"; done) 3>&1 1>&2 2>&3)
  if [ $? != 0 ]; then
    return 1
  fi

  entries_pattern="entries/${selected_year}/${selected_month}/[^ ]+\.mp3 [^ ]+"
  entries=$(list_entries | grep -E "${entries_pattern}" | tr -d '\n')

  if [ -z "$entries" ]; then
    #whiptail --title "Audio Journal" --msgbox "No entries found." 10 30
    return 6
  fi

  selected=$(whiptail --title "Audio Journal" --menu "Select an entry" 20 80 10 $entries 3>&1 1>&2 2>&3)
  if [ $? != 0 ]; then
    return 1
  fi

  echo "$selected"
}

# Function to play a selected audio entry
play_entry() {
  selected_file=$(select_entry)
  select_entry_status=$?

  if [ $select_entry_status -eq 6 ]; then
    whiptail --title "Audio Journal" --msgbox "No entries found." 10 30
    return
  fi

  if [ $select_entry_status = 0 ]; then
    title=$(cat "${selected_file%.mp3}.txt")
    echo "Playing entry: $title"
    ffplay -nodisp -autoexit "$selected_file"
  fi
}

# Function to delete a selected audio entry
delete_entry() {
  selected_file=$(select_entry)
  select_entry_status=$?  

  if [ $select_entry_status -eq 6 ]; then
    whiptail --title "Audio Journal" --msgbox "No entries found." 10 30
    return
  fi

  if [ $select_entry_status = 0 ]; then
    title=$(cat "${selected_file%.mp3}.txt")
    whiptail --title "Audio Journal" --yesno "Delete entry $title?" 10 30
    if [ $? = 0 ]; then
      rm "$selected_file"
      rm "${selected_file%.mp3}.txt"
      echo "Entry deleted."
    fi
  fi
}

# Main menu
main_menu() {
  while true; do
    option=$(whiptail --title "Audio Journal" --menu "Choose an option" 20 50 6 "1" "Record Entry" "2" "Play Entry" "3" "Delete Entry" "4" "Quit" 3>&1 1>&2 2>&3)
    case $option in
      1) record_entry ;;
      2) play_entry ;;
      3) delete_entry ;;
      4) exit 0 ;;
      *) echo "Invalid option" ;;
    esac
  done
}

# Create entries directory if it doesn't exist
mkdir -p entries

main_menu

