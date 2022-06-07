export PROGRAM=easymenu
export ACME=/c/Users/Dave/Downloads/acme0.96.4win/acme/ACME_Lib 
export VICE=/c/Users/Dave/Downloads/GTK3VICE-3.3-win32/GTK3VICE-3.3-win32-r35872
bin/win/acme -f cbm -l build/labels -o build/${PROGRAM}.prg code/${PROGRAM}.asm
[ $? -eq 0 ] || exit 1
[ $? -eq 0 ] && ${VICE}/c1541 << EOF
attach build/${PROGRAM}.d64
delete "${PROGRAM}"
delete "${PROGRAM}.asm"
delete license
write build/${PROGRAM}.prg "${PROGRAM}"
write code/${PROGRAM}.asm ${PROGRAM}.asm,s
write LICENSE license,s
EOF
[ $? -eq 0 ] && ${VICE}/x64.exe -moncommands build/labels build/${PROGRAM}.d64
