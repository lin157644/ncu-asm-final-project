include \masm32\INCLUDE\windows.inc
include \masm32\INCLUDE\gdi32.inc
include \masm32\INCLUDE\user32.inc
include \masm32\INCLUDE\kernel32.inc
include \masm32\INCLUDE\masm32.inc

includelib \masm32\LIB\gdi32.lib
includelib \masm32\LIB\user32.lib
includelib \masm32\LIB\kernel32.lib
includelib \masm32\LIB\masm32.lib

; For entertaining
include \masm32\include\winmm.inc
includelib \masm32\lib\winmm.lib

TOTAL_COLS  EQU 8
TOTAL_ROWS  EQU 8
TILE_WIDTH  EQU 32
TILE_HEIGHT EQU 32
TEXT_HEIGHT EQU 20
WINDOW_WIDTH    EQU TOTAL_ROWS*TILE_HEIGHT
WINDOW_HEIGHT   EQU TOTAL_ROWS*TILE_HEIGHT+TEXT_HEIGHT
IDT_SPRITE_TIMER        EQU 1
IDT_TRANSITION_TIMER    EQU 2
TRANSITION_DURATION     EQU 30

m2m MACRO M1, M2
    push M2
    pop  M1
ENDM

WndProc PROTO hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
ProcessMoveLogic PROTO, indexOffset:DWORD, xOffset:DWORD, yOffset:DWORD
ResetGame PROTO, level:DWORD
Gameloop PROTO
PlayBGM PROTO

.data
szClassName     BYTE    "Main_App_Class",0
szDisplayName   BYTE    "Sokaban",0
bmpCharName     BYTE    "bmpChar",0
bmpCharMaskName BYTE    "bmpCharMask",0
bmpWallName     BYTE    "bmpWall",0
bmpBoxName      BYTE    "bmpBox",0
bmpSpikeName    BYTE    "bmpSpike",0
bmpSpikeBoxName BYTE    "bmpSpikeBox",0
bmpEnemyName    BYTE    "bmpEnemy0",0
bmpEnemyMaskName BYTE   "bmpEnemyMask0",0
bmpFloorName    BYTE    "bmpFloor",0
bmpStairName    BYTE    "bmpStair",0
bmpIconName     BYTE    "bmpIcon",0
bmpKeyName      BYTE    "bmpKey",0
bmpDoorName     BYTE    "bmpDoor",0
hbmChar         HANDLE  ?
hbmCharMask     HANDLE  ?
hbmWall         HANDLE  ?
hbmBox          HANDLE  ?
hbmSpike        HANDLE  ?
hbmSpikeBox     HANDLE  ?
hbmEnemy        HANDLE  ?
hbmEnemyMask    HANDLE  ?
hbmFloor        HANDLE  ?
hbmStair        HANDLE  ?
hbmKey          HANDLE  ?
hbmDoor         HANDLE  ?
hBufferBitmap   HANDLE  ?
hTitleOld       HANDLE  ?
hInstance       HANDLE  ?
WndX            DWORD   0
WndY            DWORD   0
WndWidth        DWORD   WINDOW_WIDTH
WndHeight       DWORD   WINDOW_HEIGHT
hWnd            HWND    ?
wndclass        WNDCLASSEX  <?>
msg             MSG         <?>
cCharPosX       DWORD   ?
cCharPosY       DWORD   ?
wndRect         RECT    <0,0,WINDOW_WIDTH,WINDOW_HEIGHT>
redrawRange     RECT    <0,0,WINDOW_WIDTH,WINDOW_HEIGHT>
maxMoves        SDWORD  0,23,24,29
currentMoves    SDWORD  ?
currentMaxMoves SDWORD  ?
currentMovesStr BYTE    "Moves left: 00",0
; currentMovesRet RECT    <TOTAL_COLS*TILE_WIDTH,TOTAL_ROWS*TILE_HEIGHT,WINDOW_WIDTH,50>
bSokobanStates  BYTE    TOTAL_COLS*TOTAL_ROWS dup(?)
currentLevel    DWORD   1
currentLevelStr BYTE    "current level: 0",0
transLevelStr   BYTE    "Level 0",0
titleStr        BYTE    "Sokoban",0
pressSpaceStr   BYTE    "Press space to start",0
pressSpaceRect  RECT    <0,100,WINDOW_WIDTH,WINDOW_HEIGHT>
hFont           HFONT   ?
frameCounter    DWORD   ?
transition_start DWORD  ?
; Game state 0:menu 1:Show Level 2:Gaming 3:Win
gameState       BYTE 0
hasKeyState        BYTE 0
; 0:floor 1:wall 2:box 3:spike 4:enemy 5:stair 6:box&spike 7:key 8:door
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

playerId        DWORD 0
playerType      BYTE  "MPEGVideo",0
playerAlias     BYTE  "BGMPlayer", 0
filePath        BYTE  "C:\bgmusic.mp3", 0
ptPlgBlt        POINT <0,0>,<32,0>,<0,32>