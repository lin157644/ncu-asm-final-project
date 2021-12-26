include \masm32\INCLUDE\windows.inc
include \masm32\INCLUDE\gdi32.inc
include \masm32\INCLUDE\user32.inc
include \masm32\INCLUDE\kernel32.inc
include \masm32\INCLUDE\masm32.inc

includelib \masm32\LIB\gdi32.lib
includelib \masm32\LIB\user32.lib
includelib \masm32\LIB\kernel32.lib
includelib \masm32\LIB\masm32.lib

COL EQU 8
ROW EQU 8

m2m MACRO M1, M2
    push M2
    pop  M1
ENDM

WndProc PROTO hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
ProcessMoveLogic PROTO, indexSource:DWORD, indexOffset:DWORD

.data
szClassName     DB  "Main_App_Class",0
szDisplayName   DB  "Sokaban",0
bmpCharName     DB  "bmpChar",0
bmpWallName     DB  "bmpWall",0
bmpBoxName      DB  "bmpBox",0
bmpSpikeName     DB  "bmpSpike",0
bmpEnemyName     DB  "bmpEnemy",0
bmpFloorName     DB  "bmpFloor",0
hInstance       DD  ?
hbmChar         HANDLE  ?
hbmWall         HANDLE  ?
hbmBox          HANDLE  ?
hbmSpike        HANDLE  ?
hbmEnemy        HANDLE  ?
hbmFloor        HANDLE  ?
hBufferBitmap   HANDLE  ?
WndX            DD  0
WndY            DD  0
WndWidth        DD  512
WndHeight       DD  512
hWnd            HWND    ?
wndclass        WNDCLASSEX <?>
msg             MSG         <?>
; 0:floor 1:wall 2:box 3:spike 4:enemy 5:void
; bSokobanStates  BYTE    3,63 dup(2)
bSokobanStates  BYTE 1,1,1,1,1,1,1,1
                BYTE 1,1,1,1,1,0,0,1
                BYTE 1,1,0,0,4,0,0,1
                BYTE 1,1,0,4,0,4,1,1
                BYTE 1,0,0,1,1,1,1,1
                BYTE 1,0,2,0,0,2,0,1
                BYTE 1,0,2,0,2,0,0,1
                BYTE 1,1,1,1,1,1,1,1
cCharPosX       DD 6
cCharPosY       DD 1
redrawRange     RECT        <0,0,512,512>
maxMoves        SDWORD  23,24,32
currnetMoves    SDWORD  3 dup(?)
