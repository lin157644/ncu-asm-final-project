include \masm32\INCLUDE\windows.inc
include \masm32\INCLUDE\gdi32.inc
include \masm32\INCLUDE\user32.inc
include \masm32\INCLUDE\kernel32.inc
include \masm32\INCLUDE\masm32.inc

includelib \masm32\LIB\gdi32.lib
includelib \masm32\LIB\user32.lib
includelib \masm32\LIB\kernel32.lib
includelib \masm32\LIB\masm32.lib

; For background music
include \masm32\include\winmm.inc
includelib \masm32\lib\winmm.lib

include Resource.inc

TOTAL_COLS      EQU 8
TOTAL_ROWS      EQU 8
TILE_WIDTH      EQU 32
TILE_HEIGHT     EQU 32
TEXT_HEIGHT     EQU 20
WINDOW_WIDTH    EQU TOTAL_ROWS*TILE_HEIGHT
WINDOW_HEIGHT   EQU TOTAL_ROWS*TILE_HEIGHT+TEXT_HEIGHT
TRANS_DUR       EQU 30
GSTATE_TITLE    EQU 0
GSTATE_TUTORIAL EQU 1
GSTATE_TRANS    EQU 2
GSTATE_LEVEL    EQU 3
GSTATE_WIN      EQU 4

FACING_LEFT     EQU 0
FACING_RIGHT    EQU 1

m2m MACRO M1, M2
    push M2
    pop  M1
ENDM

WndProc PROTO hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
ProcessMoveLogic PROTO, indexOffset:DWORD, xOffset:SDWORD, yOffset:SDWORD
ResetGame PROTO, level:DWORD
Gameloop PROTO
PlayBGM PROTO
RanderFPS PROTO, hdcBuf:HDC
PushAnimation PROTO, xPushOffset:SDWORD, yPushOffset:SDWORD

.data
szClassName     BYTE    "Main_App_Class",0
szDisplayName   BYTE    "DungeonTaker",0
hbmWall         HANDLE  ?
hbmBox          HANDLE  ?
hbmSpike        HANDLE  ?
hbmSpikeBox     HANDLE  ?
hbmFloor        HANDLE  ?
hbmStair        HANDLE  ?
hbmKey          HANDLE  ?
hbmDoor         HANDLE  ?
hbmSlime        HANDLE  ?
hbmSlimeMask    HANDLE  ?
hbmKnight       HANDLE  ?
hbmKnightMask   HANDLE  ?
hbmPushAnim     HANDLE  ?
hbmPushAnimMask HANDLE  ?
hTitleOld       HANDLE  ?
hInstance       HANDLE  ?
WndX            DWORD   0
WndY            DWORD   0
WndWidth        DWORD   WINDOW_WIDTH
WndHeight       DWORD   WINDOW_HEIGHT
hWnd            HWND    ?
wndclass        WNDCLASSEX  <?>
msg             MSG         <?>
cCharPosX       DWORD   ?   ; in tiles
cCharPosY       DWORD   ?
CharOffsetX     SDWORD   ?   ; in pixel
CharOffsetY     SDWORD   ?
wndRect         RECT    <0,0,WINDOW_WIDTH,WINDOW_HEIGHT>
redrawRange     RECT    <0,0,WINDOW_WIDTH,WINDOW_HEIGHT>
maxMoves        SDWORD  0,23,24,28
currentMoves    SDWORD  ?
currentMovesStr BYTE    "Moves left: 00",0
; currentMovesRet RECT    <TOTAL_COLS*TILE_WIDTH,TOTAL_ROWS*TILE_HEIGHT,WINDOW_WIDTH,50>
currentLevel    DWORD   1
currentLevelStr BYTE    "current level: 0",0
transLevelStr   BYTE    "Level 0",0
titleStr        BYTE    "DungeonTaker",0
pressSpaceStr   BYTE    "Press space to start",0
pressSpaceRect  RECT    <0,100,WINDOW_WIDTH,WINDOW_HEIGHT>
hFont           HFONT   ?
frameCounter    DWORD   ?
transition_start DWORD  ?
; Game state 0:menu 1:Show Level 2:Gaming 3:Win
gameState       BYTE GSTATE_TITLE
hasKeyState     BYTE 0
; 0:floor 1:wall 2:box 3:spike 4:enemy 5:stair 6:box&spike 7:key 8:door
bSokobanStates  BYTE    TOTAL_COLS*TOTAL_ROWS dup(?)
bLevelStates1   BYTE 1,1,1,1,1,1,1,1
                BYTE 1,1,1,1,1,0,0,1
                BYTE 1,1,0,0,4,0,3,1
                BYTE 1,1,0,4,0,4,1,1
                BYTE 1,0,0,1,1,1,1,1
                BYTE 1,0,2,0,0,2,0,1
                BYTE 1,0,2,0,2,0,5,1
                BYTE 1,1,1,1,1,1,1,1

bLevelStates2   BYTE 1,1,1,1,1,1,1,1
                BYTE 1,0,0,0,0,1,1,1
                BYTE 1,4,1,3,3,0,0,1
                BYTE 1,3,1,1,6,6,2,1
                BYTE 1,0,0,1,0,3,0,1
                BYTE 1,3,0,1,0,4,0,1
                BYTE 1,1,1,1,5,0,4,1
                BYTE 1,1,1,1,1,1,1,1

bLevelStates3   BYTE 1,1,1,1,1,1,5,1
                BYTE 1,1,1,1,1,1,8,1
                BYTE 1,1,0,3,3,0,0,1
                BYTE 1,1,3,1,3,1,0,1
                BYTE 1,1,0,0,4,3,3,1
                BYTE 1,1,3,1,3,1,0,1
                BYTE 1,7,0,0,0,4,0,1
                BYTE 1,1,1,1,1,1,1,1

playerId        DWORD   0
playerType      BYTE    "MPEGVideo",0
playerAlias     BYTE    "BGMPlayer",0
filePath        BYTE    "bgmusic.mp3",0
hitSoundFilePath BYTE   "push_sound.wav",0
getKeyFilePath  BYTE    "get_key.wav",0
onSpikeFilePath BYTE    "on_spike.wav",0
; ptPlgBlt        POINT <0,0>,<31,0>,<0,31>
charFacing      DWORD   FACING_LEFT
endingText      BYTE    "You Win!",0
FPSText         BYTE    2 dup(?),0
spriteIndex     DWORD   0
pushAnimFrame   DWORD   ?
pushAnimPosX    DWORD   ?
pushAnimPosY    DWORD   ?
tutorialStr     BYTE    "Use arrow keys to move",0dh,0ah,"ESC to exit",0dh,0ah,"R to restart",0dh,0ah,"M to mute",0