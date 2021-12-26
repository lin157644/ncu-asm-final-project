.386
.model  flat,stdcall
option casemap: none

INCLUDE Sokoban.inc

.code
Main PROC
    invoke GetModuleHandle, 0
    mov hInstance, eax

    ; Set window class attributes in WNDCLASSEX structure
    mov wndclass.cbSize,        sizeof WNDCLASSEX
    mov wndclass.style,         CS_BYTEALIGNCLIENT or CS_BYTEALIGNWINDOW
    ; mov wndclass.style,         CS_HREDRAW or CS_VREDRAW
    mov wndclass.lpfnWndProc,   OFFSET WndProc      ; 處理視窗事件的函式
    mov wndclass.cbClsExtra,    0
    mov wndclass.cbWndExtra,    0
    m2m wndclass.hInstance,     hInstance           ; push pop macro
    ; invoke LoadIcon,hInstance,500                 ; No ICON yet...
    mov wndclass.hIcon,         0
    invoke LoadCursor,          NULL,IDC_ARROW
    mov wndclass.hCursor,       eax
    m2m wndclass.hbrBackground, COLOR_BTNFACE+1
    mov wndclass.lpszMenuName,  0
    mov wndclass.lpszClassName, OFFSET szClassName  ; 取用 Class 時的名稱
    mov wndclass.hIconSm,       0

    invoke RegisterClassEx, ADDR wndclass

    ; Create the main window with an extended window style

    invoke CreateWindowEx,
        WS_EX_LEFT or WS_EX_ACCEPTFILES,; dwExStyle
        ADDR szClassName,               ; lpClassName
        ADDR szDisplayName,             ; lpWindowName
        WS_OVERLAPPEDWINDOW,            ; dwStyle
        WndX,WndY,WndWidth,WndHeight,   ; Initial position and size
        0,0,                            ; hWndParent hMenu
        hInstance,0                     ; hInstance lpParam
    mov hWnd,eax                        ; save the handle to hWnd

    ; invoke LoadMenu,hInstance,600
    ; invoke SetMenu,hWnd,eax

    ; Last param is for callback function.
    ; We use wm_timer here.
    invoke SetTimer,hWnd,IDT_SPRITE_TIMER,150,0

    invoke ShowWindow,hWnd, SW_SHOWNORMAL
    invoke UpdateWindow,hWnd

    .while  TRUE
            invoke  GetMessage,offset msg,NULL,0,0
    .break  .if     !eax
            invoke  DispatchMessage,offset msg
    .endw
            mov     eax,msg.wParam
            invoke  ExitProcess,eax

    ; call MsgLoop
    invoke ExitProcess,eax
Main ENDP

; MsgLoop proc

;     LOCAL msg:MSG

;     push ebx
;     lea ebx, msg
;     jmp getmsg

;   msgloop:
;     invoke TranslateMessage, ebx
;     invoke DispatchMessage,  ebx
;   getmsg:
;     invoke GetMessage,ebx,0,0,0
;     test eax, eax
;     jnz msgloop

;     pop ebx
;     ret

; MsgLoop endp

WndProc PROC hWndd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL paintStruct:PAINTSTRUCT
    LOCAL hdc:HDC,  hdcBuffer:HDC, hbmBuffer:HBITMAP, hdcMem:HDC
    LOCAL row:DWORD, col:DWORD
    LOCAL drawPosX:DWORD, drawPosY:DWORD
    LOCAL dwRop:DWORD

    .IF uMsg==WM_DESTROY
        invoke PostQuitMessage,NULL

    .ELSEIF uMsg==WM_CREATE
        call LoadBitmapHandlers
        invoke  ResetGame,currnetLevel
        invoke  UpdateWindow,hWndd

    .ELSEIF uMsg==WM_PAINT
        invoke  BeginPaint,hWndd,ADDR paintStruct
        mov hdc,eax ; The destination device context
        ; Bitmaps can only be selected into memory DC's.
        ; A single bitmap cannot be selected into more than one DC at the same time.
        invoke  CreateCompatibleDC,hdc ; A memory DC for Buffer
        mov     hdcBuffer,eax
        invoke  CreateCompatibleDC,hdc ; A memory DC for Bitmap
        mov     hdcMem,eax

        invoke  CreateCompatibleBitmap,hdc,512,512
        mov     hbmBuffer,eax

        invoke  SelectObject,hdcBuffer,hbmBuffer
        ; mov     hbmOldBuffer,eax

        ; MAKEROP4
        mov dwRop, SRCCOPY ; high-order-backgroud-1-black
        shl dwRop,8
        and dwRop,0FF000000h
        or dwRop, SRCAND ; low-order-foreground-0-white

        mov ecx, 8
        mov drawPosY,0
        xor esi,esi
    DrawRow:
        push ecx
        mov ecx, 8
        xor edi,edi
        mov drawPosX, 0

    DrawCol:
        push ecx

        mov al,[bSokobanStates+esi*8+edi]

        .IF al == 0
            ; Draw Floor
            invoke  SelectObject,hdcMem,hbmFloor
            invoke  BitBlt,hdcBuffer,drawPosX,drawPosY,32,32,hdcMem,
                    0,0,SRCCOPY

        .ELSEIF al == 1
            ; Draw Wall
            invoke  SelectObject,hdcMem,hbmWall
            invoke  BitBlt,hdcBuffer,drawPosX,drawPosY,32,32,hdcMem,
                    0,0,SRCCOPY

        .ELSEIF al == 2
            ; Draw Box
            invoke  SelectObject,hdcMem,hbmBox
            invoke  BitBlt,hdcBuffer,drawPosX,drawPosY,32,32,hdcMem,
                    0,0,SRCCOPY

        .ELSEIF al == 3
            ; Draw Spike
            invoke  SelectObject,hdcMem,hbmSpike
            invoke  BitBlt,hdcBuffer,drawPosX,drawPosY,32,32,hdcMem,
                    0,0,SRCPAINT
        .ELSEIF al == 4
            invoke  SelectObject,hdcMem,hbmFloor
            invoke  BitBlt,hdcBuffer,drawPosX,drawPosY,32,32,hdcMem,
                    0,0,SRCCOPY
            invoke  SelectObject,hdcMem,hbmEnemy
            invoke MaskBlt,hdcBuffer,drawPosX,drawPosY,32,32,
                        hdcMem,0,0,
                        hbmEnemyMask,0,0,
                        dwRop
        .ELSEIF al == 5
            ; Draw Stair
            invoke  SelectObject,hdcMem,hbmStair
            invoke  BitBlt,hdcBuffer,drawPosX,drawPosY,32,32,hdcMem,
                    0,0,SRCCOPY

        .ELSEIF al == 6
            ; Draw Spike with box
            invoke  SelectObject,hdcMem,hbmSpikeBox
            invoke  BitBlt,hdcBuffer,drawPosX,drawPosY,32,32,hdcMem,
                    0,0,SRCCOPY
        .ELSE
            ; Draw Void
            ; invoke  SelectObject,hdcMem,hbmBox
            ; invoke  BitBlt,hdcBuffer,drawPosX,drawPosY,32,32,hdcMem,
            ;         0,0,SRCCOPY
        .endif

        .IF edi == cCharPosX && esi == cCharPosY
            ; Draw Charactor
            invoke  SelectObject,hdcMem,hbmChar
            invoke MaskBlt,hdcBuffer,drawPosX,drawPosY,TILE_WIDTH,TILE_HEIGHT,
                        hdcMem,0,0,
                        hbmCharMask,0,0,
                        dwRop
        .ENDIF

        inc edi
        add drawPosX,32

        pop ecx
        dec ecx
        jnz DrawCol

        inc esi
        add drawPosY,32

        pop ecx
        dec ecx
        jnz DrawRow

        ; Draw move left text
        ; invoke TextOut hdcBuffer, TOTAL_COLS*TILE_WIDTH, TOTAL_ROWS*TILE_HEIGHT,
        invoke DrawText,hdc,ADDR currnetMovesStr,-1,ADDR currnetMovesRet, DT_WORDBREAK or DT_LEFT

        ; Buffer to window
        invoke  BitBlt,hdc,0,0,WINDOW_WIDTH,WINDOW_HEIGHT,hdcBuffer,
                    0,0,SRCCOPY

        invoke  DeleteDC,hdcMem
        invoke  DeleteDC,hdcBuffer
        invoke  EndPaint,hWndd,ADDR paintStruct

        invoke DefWindowProc,hWndd,uMsg,wParam,lParam

    .ELSEIF uMsg==WM_KEYUP
        mov esi,cCharPosY
        shl esi,3
        add esi,cCharPosX
        ; esi for index param
        .IF wParam==VK_UP
            invoke ProcessMoveLogic,-8,0,-1
        .ELSEIF wParam==VK_DOWN
            invoke ProcessMoveLogic,8,0,1
        .ELSEIF wParam==VK_LEFT
            invoke ProcessMoveLogic,-1,-1,0
        .ELSEIF wParam==VK_RIGHT
            invoke ProcessMoveLogic,1,1,0
        .ELSEIF wParam==52h
            invoke ResetGame,currnetLevel
        .ENDIF
        ; If both parameters are NULL, the entire client area is added to the update region.
        ; invoke RedrawWindow,hWndd, 0, 0, RDW_INVALIDATE or RDW_UPDATENOW
        invoke  InvalidateRect,hWndd,ADDR redrawRange,1
        invoke  UpdateWindow,hWndd

    .ELSEIF uMsg==WM_TIMER
        .IF wParam == IDT_SPRITE_TIMER
            inc bmpEnemyName[8]
            .IF bmpEnemyName[8] == 36h
                mov bmpEnemyName[8],30h
                mov bmpEnemyMaskName[12],30h
                invoke  LoadImage,hInstance,ADDR bmpEnemyMaskName,IMAGE_BITMAP,0,0,
                    LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
                mov hbmEnemyMask,eax
            .ELSEIF bmpEnemyName[8] == 34h || bmpEnemyName[8] == 35h
                mov bmpEnemyMaskName[12],31h
                invoke  LoadImage,hInstance,ADDR bmpEnemyMaskName,IMAGE_BITMAP,0,0,
                    LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
                mov hbmEnemyMask,eax
            .ENDIF
            invoke  LoadImage,hInstance,ADDR bmpEnemyName,IMAGE_BITMAP,0,0,
                LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
            mov hbmEnemy,eax
            invoke  InvalidateRect,hWndd,ADDR redrawRange,1
            invoke UpdateWindow,hWndd
        .ENDIF

    .ELSEIF uMsg==WM_COMMAND
        mov eax,wParam
        .IF lParam==0
            ; Process messages, else...
            invoke DestroyWindow,hWndd
        .ELSE
            mov edx,wParam
            shr edx,16
            ; Process messages here
        .ENDIF
    .ELSE
        ; DefWindowProc function does nothing with nonsystem keystroke
        invoke DefWindowProc,hWndd,uMsg,wParam,lParam
        ret
    .ENDIF

    xor eax,eax
    ret
WndProc ENDP

LoadBitmapHandlers PROC

    invoke  LoadImage,hInstance,ADDR bmpCharName,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmChar,eax

    invoke  LoadImage,hInstance,ADDR bmpCharMaskName,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmCharMask,eax

    invoke  LoadImage,hInstance,ADDR bmpFloorName,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmFloor,eax

    invoke  LoadImage,hInstance,ADDR bmpWallName,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmWall,eax

    invoke  LoadImage,hInstance,ADDR bmpBoxName,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmBox,eax

    invoke  LoadImage,hInstance,ADDR bmpSpikeName,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmSpike,eax

    invoke  LoadImage,hInstance,ADDR bmpEnemyName,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmEnemy,eax

    invoke  LoadImage,hInstance,ADDR bmpEnemyMaskName,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmEnemyMask,eax

    invoke  LoadImage,hInstance,ADDR bmpStairName,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmStair,eax

    invoke  LoadImage,hInstance,ADDR bmpSpikeBoxName,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmSpikeBox,eax

    ret
LoadBitmapHandlers ENDP

ProcessMoveLogic PROC USES eax,
    indexOffset:DWORD, xOffset:DWORD, yOffset:DWORD
    mov eax,indexOffset
    add esi,eax
    .IF bSokobanStates[esi] == 0 || bSokobanStates[esi] == 3
        mov eax,xOffset
        add cCharPosX,eax
        mov eax,yOffset
        add cCharPosY,eax
        dec currnetMoves
        .IF bSokobanStates[esi-8] == 3
            ;Spike
            dec currnetMoves
        .ENDIF
    .ELSEIF bSokobanStates[esi] == 2
        ; Barrel
        .IF bSokobanStates[esi+eax] == 0; If movable
            mov bSokobanStates[esi],0
            mov bSokobanStates[esi+eax],2
        .ELSEIF  bSokobanStates[esi+eax] == 3
            mov bSokobanStates[esi],6
            mov bSokobanStates[esi+eax],2
        .ENDIF
    .ELSEIF bSokobanStates[esi] == 4
        ; Kill Enemy
        mov bSokobanStates[esi],0
    .ELSEIF bSokobanStates[esi] == 5
        ; Next Level
        inc currnetLevel
        invoke ResetGame,currnetLevel
    .ELSEIF bSokobanStates[esi] == 6
        ; Spike with Barrel
        .IF bSokobanStates[esi+eax] == 0 ; If movable
            mov bSokobanStates[esi],3
            mov bSokobanStates[esi+eax],2
        .ENDIF
        .IF bSokobanStates[esi+eax] == 3 ; If movable
            mov bSokobanStates[esi],3
            mov bSokobanStates[esi+eax],6
        .ENDIF
    .ENDIF

    ret
ProcessMoveLogic ENDP

ResetGame PROC USES eax ecx esi,
    level:DWORD
    ; Reset Charactor
    .IF level == 1
        mov cCharPosX,6
        mov cCharPosY,1
        mov esi,OFFSET bLevelStates1
    .ELSEIF level == 2
        mov cCharPosX,1
        mov cCharPosY,5
        mov esi,OFFSET bLevelStates2
    .ENDIF
    ; Reset tiles
    xor ecx,ecx
CopyLoop:
    mov al,BYTE PTR [esi+ecx]
    mov bSokobanStates[ecx],al
    inc ecx
    cmp ecx,TOTAL_COLS*TOTAL_ROWS+1
    jnz CopyLoop

    ret
ResetGame ENDP

END Main