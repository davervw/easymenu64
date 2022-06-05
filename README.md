# easymenu64

![Easymenu screen example](https://github.com/davervw/easymenu64/raw/master/easymenu.png)

Easymenu is a utility for Commodore 64 to display disk directory in a 2-up,
multi-page display allowing the user to select a program with curosr keys 
or joystick(#2).  It supports loading BASIC programs normally saved with
low byte offset 1, and machine language programs saved at other offsets.
If the program identifies as a cartridge with autostart, the system soft
resets JMP ($FFFC) and will then auto-start.

Easymenu resides at $C000-$C6FF temporarily using $C700 onward for directory
listings on demand.  If it is not overwritten, the user may return to a
directory listing using SYS 49152

Demo usage:

Mount easymenu.d64 disk

    LOAD"EASYMENU",8
    RUN
    
    or

    LOAD"EASYMENU",8,1
    NEW
    SYS 49152

Keyboard commands reference:

    Home        Go to top leftmost entry
    Cursor      Select file
    Enter       Load program
    Joystick#2  Select file
    Joy#2 fire  Load program
    F1          Background color cycle
    F3          Foreground color cycle
    F5          Border color cycle
    Ctrl+F      Write EASYMENU to current disk, with defaults
    1-4         Show directory of device 8-11
    Space       Restart EASYMENU
    Ctrl+C      Exit

Source code is 6502 assembler targeting Commodore 64

Requires bin/win/[acme.exe](https://sourceforge.net/projects/acme-crossass/) and bin/win/c1541.exe from [Vice](http://vice-emu.sourceforge.net/index.html#download)
and revise build.sh to use more Vice executables for building and launching

Also see [blog entry](https://techwithdave.davevw.com/2022/06/easymenu64-directory-and-program.html)