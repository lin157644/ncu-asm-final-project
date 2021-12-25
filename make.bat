@echo off
: -------------------------------
: if resources exist, build them
: -------------------------------
if not exist SokobanRes.rc goto over1
\masm32\BIN\Rc.exe /v SokobanRes.rc
\masm32\BIN\Cvtres.exe /machine:ix86 SokobanRes.res
:over1

if exist %1.obj del Sokoban.obj
if exist %1.exe del Sokoban.exe

: -----------------------------------------
: assemble template.asm into an OBJ file
: -----------------------------------------
\masm32\BIN\Ml.exe /c /coff /Zi /Fl Sokoban.asm
if errorlevel 1 goto errasm

if not exist SokobanRes.obj goto nores

: --------------------------------------------------
: link the main OBJ file with the resource OBJ file
: --------------------------------------------------
\masm32\BIN\Link.exe /SUBSYSTEM:WINDOWS Sokoban.obj SokobanRes.obj
if errorlevel 1 goto errlink
dir Sokoban.*
goto TheEnd

:nores
: -----------------------
: link the main OBJ file
: -----------------------
\masm32\BIN\Link.exe /SUBSYSTEM:WINDOWS Sokoban.obj
if errorlevel 1 goto errlink
dir Sokoban.*
goto TheEnd

:errlink
: ----------------------------------------------------
: display message if there is an error during linking
: ----------------------------------------------------
echo.
echo There has been an error while linking this project.
echo.
goto TheEnd

:errasm
: -----------------------------------------------------
: display message if there is an error during assembly
: -----------------------------------------------------
echo.
echo There has been an error while assembling this project.
echo.
goto TheEnd

:TheEnd

pause
