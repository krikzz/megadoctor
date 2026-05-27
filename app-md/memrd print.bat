@echo off
set USB_TOOL=edlink.exe

%USB_TOOL% memrd --addr 0 --len 80 --print
pause