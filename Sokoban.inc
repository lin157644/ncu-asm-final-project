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

.data
szClassName     DB  "Main_App_Class",0
szDisplayName   DB  "Sokaban",0
bmpBoxName      DB  "bmpBox",0
bmpCharName      DB  "bmpChar",0
hInstance       DD  ?
hBitmap         DD  ?   ; todo:find its type name
hCharBitmap     DD  ?
WndX            DD  0
WndY            DD  0
WndWidth        DD  600
WndHeight       DD  400
hWnd            HWND    ?
wndclass        WNDCLASSEX <?>
msg             MSG         <?>
; 0:air 1:wall 2:box 3:char
bSokobanStates         BYTE    3, 63 dup(2)
cCharPosX       DD 0
cCharPosY       DD 0
redrawRange     RECT        <0,0,600,400>