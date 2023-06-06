### Auxiliary tools ###############################
# Colorized echo
function colecho
{
  echo -e "\e[$1m$2\e[0m"
}

# Print the new line
function nl
{
  echo " "
}

# Print the blue line separator 
function pl
{
  echo " "
  colecho "34" "============================================================"
}

# message a "FATAL ERROR" - print report and exit  
function fatal
{
  colecho "31" "$@"
  colecho "31" "Nelze pokracovat - koncim"
  
  pl
  Quit 
  exit 1
}

# General message
function message
{
  colecho "1;37" "$@"
}

# Print mesege only if aplications is in verbose mode
function vmessage
{
  if [ $VERBROSE -eq 1 ]; then 
    colecho "1;37" "$@"
  fi
}

# Message "INFORMATION"
function info
{
  colecho "1;32" "$@"
}

# Print welcome informations
function PrintHead
{
  #clear
  colecho "31" "WARNING: Run a self execute LZMA (XZ) package!"
  pl
  message "             W E L C O M E !"
  message "       DOSBox (Games) Linux Runtime"
  message "Copyright 2020 - 2023 D.A.Tiger by GNU/GPL v3"
  pl
  message "  $GAME_NAME"
  [ "$GAME_INFO_DIST" ] && message "  $GAME_INFO_DIST"
  [ "$GAME_INFO" ] && message "  $GAME_INFO"
  if [ -e "$GAME_INFO_FILE" ]; then
    nl
    cat "$GAME_INFO_FILE"
  fi  
  pl
}

#
function question( )
{
   case $AUTO_ANSWER in 
   "y") RESH=1;;
   "n") RESH=0;;
   *) 
     colecho "95" "$@"
     colecho "95" "Press [y] and [ENTER] for 'YES' or only [ENTER] for 'NO'"
     RESH=0
   
     read INP
     if [ "$INP" = "y" ]; then
       RESH=1
     fi
   ;;  
   esac   
   
   return $RESH
}

# Print argument 2 if script run in verbrose mode, or argument 1
function Checkverb
{
  if [ $VERBROSE -eq 1 ]; then
    echo $2
  else 
    echo $1
  fi
}
