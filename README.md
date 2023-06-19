# DGLR - DOSBox (Games) Linux Runtime 
-06.06.2023-

  1. [General info](#1-general-info)
  2. 

## General info
### 1.1 The DOSBox and DOS application
There are many users who, like me, still like to use applications and programs originally designed for the DOS (Disk Operating System) operating system. One of the ways to use such software on today's modern systems is to use the services of the DOSBox emulator.

It has certain limitations. An application running under Dosbox works correctly most of the time, but it still behaves like on DOS, which was not multi-user for example, and applications wrote running data directly to the path from where it was started. Which was most often its own installation directory. Thus, the user (running) data was mixed with the program data itself and it was quite laborious and sometimes very complicated to separate these data from each other. Another unpleasant consequence of this is that if one application is shared by several users, they do not overwrite each other's data. Related to this are also problems with so-called multitasking, when running several different instances of the same DOS application can lead to access collisions, which these programs cannot resolve and act on, as well as to collisions regarding access rights, which can lead to very unpleasant crashes and eventually to damage to the application itself, in the worst case even to the system.

Another inconvenience can be the dosbox configuration, which is stored in non-confidential files with the extension '.conf' and can be lying around the system. The user then has to know their path and enter it when running the emulator. This is also related to the so called autoexec, i.e. the start-up load, which is performed when the program starts and for some programs it is absolutely necessary to deal with it. You can't avoid it even if you want to offer more possibilities to run a given program (or set of programs).

Finally, there is the possible question of where to actually store these programs. Especially if you want to share them between users on one system. Any ~? Or /usr/local/bin? /usr/share/*? considering that on the dos it was usual that programs had their own address structure, stored almost arbitrarily on disk, the solution for this is quite complex and the /opt directory seems to be the best starting point. Then you may want to automate the program execution and get it into the PATH, the environment value.

It would require some universal launcher, some wrapper around the DOS one, which would be able to somehow differentiate the run data from the original ones, store the run data in some pre-prepared place, make it easy to manage the dosbox configuration, generate a DOS(Box) trigger sequence for a specific program execution scenario, allow to call the program with a single command and with the convention that is common on Linux.

And it is exactly these problems that I am trying to offer a solution to with my Dosbox (Game) Linux Runtime (DGLR) project.

### 1.2 So what is DGLR?
DGLR is simply a collection of Bash scripts that create an environment for automating the startup and running of programs launched in the DOSBox emulator.

The main way it achieves this is by packaging the target program with startup scripts (and possibly other required tools) into one executable file (more precisely, a self-executing archive).

Another method is to use FUSE-OverlayFS to monitor the file system status of a DOS program. If the program makes any changes in its file system (in the directory of the DOS program), DGLR will enter it in the so-called "User's Data Storage". This is simply a compressed archive, stored in the home folder of a specific user, in which changed (or new) files and metadata are packed. At every startup, before starting DOSBox, DLGR checks whether such an archive exists and, if so, unpacks it into prepared folders and then connects it with the original data using OverlayFS. This allows the running program to see and process the changes from the previous run, without causing the original game data to be accidentally overwritten and mixed with user data, and gives the application the ability to function smoothly on a multi-user system.

DGLR is primarily focused on games, but in truth, any DOS application that can be run using the DOSBox emulator (note 1) can be run with it. DGLR can somewhat resemble container technology in its concept. However, the main difference is that the DOS program cannot be removed from the system. On the contrary, its first and main purpose is, in a certain direction, to increase the compatibility between the functioning of the DOS application and the principles of the host Linux system.

DGLR is designed as a template, which means that each individual game must be prepared separately with DGLR. Thus, a copy of DGLR is created, the contents of the game are copied to the specified address book, and the project settings are made. For most programs, the default state of DLGR will be enough, so only the name of the EXE or COM file to be executed is set, otherwise delayed modifications of individual scripts will be performed.

If the creation of a DEB package is required, the contents of the corresponding directory are modified. Some values, e.g. in DEBIAN/control such as package name or size, will be filled in automatically by the build script (more in the upcoming detailed documentation). Next, the build script is started, which compiles all the files and generates an executable file and possibly also an installation DEB package.

### 1.3 Quick feature overview
