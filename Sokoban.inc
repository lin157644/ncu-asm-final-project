include \masm32\INCLUDE\windows.inc
include \masm32\INCLUDE\gdi32.inc
include \masm32\INCLUDE\user32.inc
include \masm32\INCLUDE\kernel32.inc
include \masm32\INCLUDE\masm32.inc

includelib \masm32\LIB\gdi32.lib
includelib \masm32\LIB\user32.lib
includelib \masm32\LIB\kernel32.lib
includelib \masm32\LIB\masm32.lib

TOTAL_COLS  EQU 8
TOTAL_ROWS  EQU 8
TILE_WIDTH  EQU 32
TILE_HEIGHT EQU 32
WINDOW_WIDTH EQU 300
WINDOW_HEIGHT EQU 300

m2m MACRO M1, M2
    push M2
    pop  M1
ENDM

WndProc PROTO hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
ProcessMoveLogic PROTO, indexOffset:DWORD
ResetGame PROTO, level:DWORD

.data
szClassName     BYTE    "Main_App_Class",0
szDisplayName   BYTE    "Sokaban",0
bmpCharName     BYTE    "bmpChar",0
bmpCharMaskName BYTE    "bmpCharMask",0
bmpWallName     BYTE    "bmpWall",0
bmpBoxName      BYTE    "bmpBox",0
bmpSpikeName    BYTE    "bmpSpike",0
bmpEnemyName    BYTE    "bmpEnemy",0
bmpEnemyMaskName    BYTE    "bmpEnemyMask",0
bmpFloorName    BYTE    "bmpFloor",0
bmpStairName    BYTE    "bmpStair",0
hbmChar         HANDLE  ?
hbmCharMask     HANDLE  ?
hbmWall         HANDLE  ?
hbmBox          HANDLE  ?
hbmSpike        HANDLE  ?
hbmEnemy        HANDLE  ?
hbmEnemyMask        HANDLE  ?
hbmFloor        HANDLE  ?
hbmStair        HANDLE  ?
hBufferBitmap   HANDLE  ?
hInstance       DWORD   ?
WndX            DWORD   0
WndY            DWORD   0
WndWidth        DWORD   WINDOW_WIDTH
WndHeight       DWORD   WINDOW_HEIGHT
hWnd            HWND    ?
wndclass        WNDCLASSEX  <?>
msg             MSG         <?>
cCharPosX       DWORD   6
cCharPosY       DWORD   1
redrawRange     RECT    <0,0,WINDOW_WIDTH,WINDOW_HEIGHT>
maxMoves        SDWORD  23,24,32
currnetMoves    SDWORD  3 dup(?)
bSokobanStates  BYTE TOTAL_COLS*TOTAL_ROWS dup(?)
currnetLevel    DWORD 1
; 0:floor 1:wall 2:box 3:spike 4:enemy 5:stair
bLevelStates1   BYTE 1,1,1,1,1,1,1,1
                BYTE 1,1,1,1,1,0,0,1
                BYTE 1,1,0,0,4,0,3,1
                BYTE 1,1,0,4,0,4,1,1
                BYTE 1,0,0,1,1,1,1,1
                BYTE 1,0,2,0,0,2,0,1
                BYTE 1,0,2,0,2,0,5,1
                BYTE 1,1,1,1,1,1,1,1
