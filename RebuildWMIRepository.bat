﻿@ECHO OFF
sc config winmgmt start= disabled
net stop winmgmt /y
%systemdrive%
cd %windir%\system32\webm
for /f %%s in ('dir /b *.dll') do regsvr32 /s %%s
wmiprvse /regserver
winmgmt /regserver 
sc config winmgmt start= auto
net start winmgmt
for /f %%s in ('dir /s /b *.mof *.mfl') do mofcomp %%s