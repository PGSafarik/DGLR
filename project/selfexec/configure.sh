#! /bin/bash

##########################################################################
# Dosbox (Games) Linux Runtime - Selfexecutable game launcher            #
# Copyright (c) 2020 - 2023 D.A.Tiger <drakarax@seznam.cz>, GNU GPL v.3  #
#                                                                        #
# This program is free software: you can redistribute it and/or modify   #
# it under the terms of the GNU General Public License as published by   #
# the Free Software Foundation, either version 3 of the License, or      #
# (at your option) any later version.                                    #
#                                                                        #
# This program is distributed in the hope that it will be useful,        #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# GNU General Public License for more details.                           #
#                                                                        #
# You should have received a copy of the GNU General Public License      #
# along with this program.  If not, see <https://www.gnu.org/licenses/>. #
##########################################################################
# Items marked with the symbol :
# * - its required 
# @ - will be evaluated during the program

# GAME INFORMATIONS (Informace o hre)
GAME_ID=""                                                         # (*) Game codename (Kodovy nazev)
GAME_NAME="NAME[ VERSION]"                                         # (*) Game name (Nazev Hry) 
GAME_CATEGORY="Game;"                                              # System category (Systemova kategorie)
GAME_INFO="#2D #GENRE #Singleplyer #Multiplayer #DOS #RELEASE #EN" # Brief information of Game (Strucne informace o hre)
GAME_INFO_DIST="[YEAR ]DEVELOPER[/DISTRIBUTOR]"                    # Autor, distributor
GAME_INFO_FILE=""                                                  # A file with more detailed information about the game (Soubor s podrobnejsimi informacemi)  


# DIRECTORIES (Adresare)
BACK_DIR=$PWD       # The path from which the script is run. Return here during the termination phase
EXTRACT_DIR="/tmp"	# Cilo's address book, where the archive with the game data will be unpacked.
GAME_ROOT=""	    # (@) Root game folder (including VFS)
LOWER_DIR=".game"	# Directory with original data (content of game)
UPPER_DIR=".user"	# Directory with changes data (content of user's storage)
WORK_DIR=".work"	# Workdir required by OverlayFS
DRIVE_DIR="drive"	# The resulting view of the file system after overlaying - only in the space of 
                    # this address book will there be writing to files and creation of folders during 
                    # the game. Clean changes are then available in UPPER_DIR

# USER DATA STORAGE ( Uzivatelske uloziste - *.save )
STORAGE=""		    # (@) Full path with the name of the user data archive 
STORAGE_ACTIVE=1    # 0 Disable, 1 enable storage activation - including OverlayFS connection  
CLEAN_STORAGE=0     # 1 Indicates a request to delete the storage
STORAGE_LOAD_G=0	# A global variable indicating that the corresponding .save archive was found and successfully unpacked

# STATE (Stavove promenne)
PRINT_HELP=0       # Show helpu indicator
VERBROSE=0         # Verbrose mode indicator
AUTO_ANSWER=""     # Indicator of automatic response to launcher questions

# COMPONENTS
THIS="$0"                 # Primary launcher
LAUNCHER=".scripts/go.sh" # Secondary game launcher
