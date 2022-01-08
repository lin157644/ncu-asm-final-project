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

; Resource.inc enums the identifier of bitmaps
include Resource.inc

; Constants and enums
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

; A convenient macro for moving data from memory to memory.
m2m MACRO M1, M2
    push M2
    pop  M1
ENDM

; Prototypes
WndProc PROTO hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
ProcessMoveLogic PROTO,currentIndex:DWORD, xOffset:SDWORD, yOffset:SDWORD
RenderPushAnim PROTO, xPushOffset:SDWORD, yPushOffset:SDWORD
ResetGame PROTO, level:DWORD
RenderFPS PROTO, hdcBuf:HDC
Gameloop PROTO
PlayBGM PROTO
PauseBGM PROTO

.data
szClassName     BYTE    "Main_App_Class",0
szDisplayName   BYTE    "DungeonTaker",0

; Bitmap handles
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

; Window attributes
wndclass        WNDCLASSEX  <?>
wndX            DWORD   ?
wndY            DWORD   ?
wndWidth        DWORD   ? ; unused
wndHeight       DWORD   ? ; unused
wndRect         RECT    <0,0,WINDOW_WIDTH,WINDOW_HEIGHT>

;
hWnd            HWND    ?
msg             MSG     <?>
redrawRange     RECT    <0,0,WINDOW_WIDTH,WINDOW_HEIGHT>

;
cCharPosX       DWORD   ?    ; in tiles
cCharPosY       DWORD   ?
CharOffsetX     SDWORD  ?   ; in pixel
CharOffsetY     SDWORD  ?
maxMoves        SDWORD  0,23,24,28
currentMoves    SDWORD  ?
currentLevel    DWORD   1


hFont           HFONT   ?
pressSpaceRect  RECT    <0,WINDOW_HEIGHT/2,WINDOW_WIDTH,WINDOW_HEIGHT>
; Strings
currentMovesStr BYTE    "Moves left: 00",0
currentLevelStr BYTE    "current level: 0",0
transLevelStr   BYTE    "Level 0",0
titleStr        BYTE    "DungeonTaker",0
pressSpaceStr   BYTE    "Press space to start",0
tutorialStr     BYTE    "Use arrow keys to move",0dh,0ah
                BYTE    "ESC to exit",0dh,0ah
                BYTE    "R to restart",0dh,0ah
                BYTE    "M to mute BGM",0
endingStr       BYTE    "You Win!",0dh,0ah
                BYTE    "Thank you for playing.",0dh,0ah
                BYTE    "Press ESC to exit.",0
fpsStr          BYTE    2 dup(?),0

; Animetion related variables
frameCounter    DWORD   ?
transition_start DWORD  ?
charFacing      DWORD   FACING_LEFT
spriteOffsetX   DWORD   ?
pushAnimFrame   DWORD   ?
pushAnimPosX    DWORD   ?
pushAnimPosY    DWORD   ?

; Game state 0:menu 1:Show Level 2:Gaming 3:Win
; Tile state 0:floor 1:wall 2:box 3:spike 4:enemy 5:stair 6:box&spike 7:key 8:door
gameState       BYTE    GSTATE_TITLE
hasKeyState     BYTE    ?
bTileStates  BYTE    TOTAL_COLS*TOTAL_ROWS dup(?)
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

; BGM player and sound effects related
playerId        DWORD   0
playerType      BYTE    "MPEGVideo",0
playerAlias     BYTE    "BGMPlayer",0
bgmPath         BYTE    "bgmusic.mp3",0
hitSoundFilePath BYTE   "PUSH_SOUND.wav",0
getKeyFilePath  BYTE    "get_key.wav",0
onSpikeFilePath BYTE    "on_spike.wav",0

