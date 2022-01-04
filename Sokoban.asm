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
    mov wndclass.style,         CS_BYTEALIGNCLIENT or CS_BYTEALIGNWINDOW or CS_OWNDC
    mov wndclass.style,         CS_HREDRAW or CS_VREDRAW
    mov wndclass.lpfnWndProc,   OFFSET WndProc      ; 處理視窗事件的函式
    mov wndclass.cbClsExtra,    0
    mov wndclass.cbWndExtra,    0
    m2m wndclass.hInstance,     hInstance           ; m2m push pop macro
    invoke LoadIcon,hInstance,ADDR bmpIconName
    mov wndclass.hIcon,         eax
    invoke LoadCursor,          NULL,IDC_ARROW
    mov wndclass.hCursor,       eax
    m2m wndclass.hbrBackground, COLOR_BTNFACE+1
    mov wndclass.lpszMenuName,  0
    mov wndclass.lpszClassName, OFFSET szClassName  ; 取用 Class 時的名稱
    mov wndclass.hIconSm,       0

    invoke RegisterClassEx, ADDR wndclass

    ; Create the main window with an extended window style
    invoke  AdjustWindowRect,ADDR wndRect,WS_CAPTION or WS_SYSMENU or WS_VISIBLE,0
    mov eax,wndRect.right
    mov ebx,wndRect.left
    neg ebx
    add wndRect.right,ebx

    mov eax,wndRect.bottom
    mov ebx,wndRect.top
    neg ebx
    add wndRect.bottom,ebx
    ; Ex might not needed
    invoke  CreateWindowEx,
        WS_EX_LEFT or WS_EX_ACCEPTFILES,; dwExStyle
        ADDR szClassName,               ; lpClassName
        ADDR szDisplayName,             ; lpWindowName
        WS_OVERLAPPEDWINDOW,            ; dwStyle
        0,0,
        272,
        315,     ; Initial position and size
        0,0,                            ; hWndParent hMenu
        hInstance,0                     ; hInstance lpParam
    mov hWnd,eax                        ; save the handle to hWnd

    invoke ShowWindow,hWnd, SW_SHOWNORMAL
    invoke UpdateWindow,hWnd

    mov frameCounter,0
    .WHILE  TRUE
        invoke  PeekMessage,offset msg,NULL,0,0,PM_REMOVE
        .IF eax
            ; .BREAK  .IF msg.message == WM_QUIT
            .IF msg.message == WM_QUIT
            jmp Quit
            .ENDIF
            invoke  DispatchMessage,offset msg
        .ELSE
            call Gameloop
            invoke  Sleep,30
        .ENDIF
    .ENDW
Quit:
    mov     eax,msg.wParam
    invoke  ExitProcess,eax
    invoke ExitProcess,eax
Main ENDP

Gameloop PROC
    inc frameCounter
    .IF gameState == 1
        mov eax,frameCounter
        sub eax,transition_start
        .IF eax>TRANSITION_DURATION
            mov gameState,2
        .ENDIF
    .ENDIF
    .IF gameState == 2
        ; ; mod 5
        ; mov eax,frameCounter
        ; mov edx,-1717986918 ; edx = 2^33/5
        ; mul edx ; Dest EDX:EAX
        ; ; Only take the edx part
        ; mov ecx,edx
        ; shl ecx,2   ; i/5*4
        ; add edx,ecx ; edx = i/5*5
        ; sub eax,edx ; eax -= edx
        ; shr edx,2   ; edx = frameCounter/4
        mov eax,frameCounter
        mov edx,eax ; eax=edx
        shr eax,2   ; eax/4
        shl eax,2   ; eax/4*4
        sub edx,eax
        .IF !edx    ; If edx = 0
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
        .ENDIF

    .ENDIF
    invoke  InvalidateRect,hWnd,ADDR redrawRange,1
    ret
Gameloop ENDP

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
        invoke  PlayBGM
        invoke  ResetGame,currentLevel
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

        .IF gameState == 0 || gameState == 1
            jmp EndTilePaint
        .ENDIF

        ; Tile paint
        ; Same as MAKEROP4 macro
        mov dwRop, SRCCOPY  ; high-order-backgroud-1-black
        shl dwRop,8
        and dwRop,0FF000000h
        or  dwRop, SRCAND   ; low-order-foreground-0-white

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
        .ELSEIF al == 7
            ; Draw Spike with box
            invoke  SelectObject,hdcMem,hbmKey
            invoke  BitBlt,hdcBuffer,drawPosX,drawPosY,32,32,hdcMem,
                    0,0,SRCCOPY
        .ELSEIF al == 8
            ; Draw Spike with box
            invoke  SelectObject,hdcMem,hbmDoor
            invoke  BitBlt,hdcBuffer,drawPosX,drawPosY,32,32,hdcMem,
                    0,0,SRCCOPY
        .ELSEIF al == 8
            ; Draw Spike with box
            invoke  SelectObject,hdcMem,hbmDoor
            invoke  BitBlt,hdcBuffer,drawPosX,drawPosY,32,32,hdcMem,
                    0,0,SRCCOPY
        .ELSE
            ; Draw Void basically nothing
            ; invoke  SelectObject,hdcMem,hbmBox
            ; invoke  BitBlt,hdcBuffer,drawPosX,drawPosY,32,32,hdcMem,
            ;         0,0,SRCCOPY
        .endif

        .IF edi == cCharPosX && esi == cCharPosY
            ; Draw Charactor
            invoke  SelectObject,hdcMem,hbmChar
            ; invoke  StretchBlt,hdcBuffer,32,32,-32,TILE_HEIGHT,
            ;                     hdcMem,0,0,32,TILE_HEIGHT,SRCAND
            ; invoke  StretchBlt,hdcMem,0,0,-32,TILE_HEIGHT,
            ;                     hdcMem,0,0,32,TILE_HEIGHT,SRCCOPY
            ; invoke  SelectObject,hdcMem,hbmCharMask
            ; invoke  StretchBlt,hdcBuffer,32,32,32,TILE_HEIGHT,
            ;                     hdcMem,0,0,32,TILE_HEIGHT,SRCCOPY
            invoke  MaskBlt,hdcBuffer,drawPosX,drawPosY,TILE_WIDTH,TILE_HEIGHT,
                        hdcMem,0,0,
                        hbmCharMask,0,0,
                        dwRop
            mov eax,drawPosX
            mov ebx,drawPosY
            mov ptPlgBlt[0].x,eax      ; upper-left corner
            mov ptPlgBlt[0].y,ebx
            mov ptPlgBlt[1*TYPE POINT].x,eax
            mov ptPlgBlt[1*TYPE POINT].y,ebx
            mov ptPlgBlt[2*TYPE POINT].x,eax
            mov ptPlgBlt[2*TYPE POINT].y,ebx
            add ptPlgBlt[1*TYPE POINT].x,TILE_WIDTH    ; upper-right corner
            dec ptPlgBlt[1*TYPE POINT].x
            add ptPlgBlt[2*TYPE POINT].y,TILE_HEIGHT   ; lower-left corner
            dec ptPlgBlt[2*TYPE POINT].y

            ; invoke PlgBlt,hdcBuffer,ADDR ptPlgBlt,hdcMem,0,0,TILE_WIDTH,TILE_HEIGHT,
            ;             hbmCharMask,0,0
            ; invoke TransparentBlt,hdcBuffer,drawPosX,drawPosY,32,32,
            ;         hdcMem,0,0,32,32,0ffffffffh
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

    EndTilePaint:
        ; Change text property
        invoke  SetTextColor,hdcBuffer,0ffffffh
        invoke  SetBkColor,hdcBuffer,0
        .IF gameState==0
            invoke  CreateFont,30,0,0,0,FW_BOLD,0,0,0,
                    ANSI_CHARSET,OUT_STRING_PRECIS,CLIP_CHARACTER_PRECIS,ANTIALIASED_QUALITY,FF_MODERN,NULL
            mov     hFont,eax
            ; Just in cast not to overwrite the old one.
            invoke  SelectObject,hdcBuffer,hFont
            mov     hTitleOld,eax
            invoke DrawText,hdcBuffer,ADDR titleStr,-1,ADDR redrawRange, DT_WORDBREAK or DT_CENTER or DT_VCENTER or DT_SINGLELINE
            invoke SelectObject,hdcBuffer,hTitleOld
            invoke DeleteDC,eax
            invoke DrawText,hdcBuffer,ADDR pressSpaceStr,-1,ADDR pressSpaceRect, DT_WORDBREAK or DT_CENTER or DT_VCENTER or DT_SINGLELINE

        .ELSEIF gameState==1
            mov  eax,currentLevel
            mov  transLevelStr[LENGTHOF transLevelStr-2],al
            add  transLevelStr[LENGTHOF transLevelStr-2],30h
            invoke DrawText,hdcBuffer,ADDR transLevelStr,-1,ADDR redrawRange, DT_WORDBREAK or DT_CENTER or DT_VCENTER or DT_SINGLELINE
        .ELSEIF gameState==2
            ; String process for gametime
            mov bl,10
            mov eax,currentMoves
            idiv bl
            .IF al == 0
                mov currentMovesStr[12],20h
            .ELSE
                add al,30h
                mov currentMovesStr[12],al
            .ENDIF
            add ah,30h
            mov currentMovesStr[13],ah
            mov  eax,currentLevel
            mov  currentLevelStr[LENGTHOF currentMovesStr],al
            add  currentLevelStr[LENGTHOF currentMovesStr],30h
            ; Draw move left text
            invoke  TextOut,hdcBuffer,0,TOTAL_ROWS*TILE_HEIGHT,ADDR currentLevelStr,LENGTHOF currentLevelStr-1
            invoke  TextOut,hdcBuffer,TOTAL_COLS*TILE_WIDTH/2,TOTAL_ROWS*TILE_HEIGHT,ADDR currentMovesStr,LENGTHOF currentMovesStr-1
        .ENDIF

        ; Buffer to window
        invoke  BitBlt,hdc,0,0,WINDOW_WIDTH,WINDOW_HEIGHT,hdcBuffer,
                    0,0,SRCCOPY

        invoke  DeleteDC,hdcMem
        invoke  DeleteDC,hdcBuffer
        invoke  EndPaint,hWndd,ADDR paintStruct

        invoke DefWindowProc,hWndd,uMsg,wParam,lParam

    .ELSEIF uMsg==WM_ERASEBKGND
        mov eax,1
        ret
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
            invoke ResetGame,currentLevel
        .ELSEIF wParam==31h
            invoke ResetGame,1
            mov gameState,1
            push frameCounter
            pop transition_start
        .ELSEIF wParam==32h
            invoke ResetGame,2
            mov gameState,1
            push frameCounter
            pop transition_start
        .ELSEIF wParam==33h
            invoke ResetGame,3
            mov gameState,1
            push frameCounter
            pop transition_start
        .ELSEIF wParam==VK_SPACE && gameState==0
            mov gameState,1
            push frameCounter
            pop transition_start
        .ELSEIF wParam==VK_ESCAPE
            invoke PostQuitMessage,NULL
            xor eax,eax
            ret
        .ENDIF
        ; If both parameters are NULL, the entire client area is added to the update region.
        ; invoke RedrawWindow,hWndd, 0, 0, RDW_INVALIDATE or RDW_UPDATENOW

    .ELSEIF uMsg==WM_TIMER

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

    ; Dynamic load transition if level increased
    ; invoke  LoadImage,hInstance,ADDR bmpCharName,IMAGE_BITMAP,0,0,
    ;     LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    ; mov hbmChar,eax

    ; invoke  LoadImage,hInstance,ADDR bmpCharName,IMAGE_BITMAP,0,0,
    ;     LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    ; mov hbmChar,eax

    ; Load tiles
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

    invoke  LoadImage,hInstance,ADDR bmpKeyName,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmKey,eax

    invoke  LoadImage,hInstance,ADDR bmpDoorName,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmDoor,eax

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
        ; Move or Kill Enemy
        .IF bSokobanStates[esi+eax] == 0
            mov bSokobanStates[esi],0
            mov bSokobanStates[esi+eax],4
        .ELSEIF bSokobanStates[esi+eax] == 1 || bSokobanStates[esi+eax] == 2 || bSokobanStates[esi+eax] == 3
            mov bSokobanStates[esi],0
        .ENDIF
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
    .ELSEIF bSokobanStates[esi] == 7
        mov eax,xOffset
        add cCharPosX,eax
        mov eax,yOffset
        add cCharPosY,eax
        mov hasKeyState,1
        mov bSokobanStates[esi],0
    .ELSEIF bSokobanStates[esi] == 8
        .IF hasKeyState==1
            mov bSokobanStates[esi],0
        .ENDIF
    .ENDIF
    dec currentMoves
    ; take one move if on spike when end
    .IF bSokobanStates[esi] == 3
        ;Spike
        dec currentMoves
    .ENDIF
    .IF currentMoves <= 0
        invoke ResetGame,currentLevel
    .ENDIF
    .IF bSokobanStates[esi] == 5
        ; Next Level
        inc currentLevel
        invoke ResetGame,currentLevel
    .ENDIF
    ret
ProcessMoveLogic ENDP

ResetGame PROC USES eax ecx esi,
    level:DWORD
    invoke KillTimer,hWnd,IDT_SPRITE_TIMER
    mov hasKeyState,0
    m2m currentLevel,level
    ; Reset Charactor
    .IF level == 1
        mov cCharPosX,6
        mov cCharPosY,1
        push [maxMoves+1*TYPE SDWORD] ; 4
        pop currentMoves
        mov esi,OFFSET bLevelStates1
    .ELSEIF level == 2
        mov cCharPosX,2
        mov cCharPosY,5
        push [maxMoves+2*TYPE SDWORD] ; 8
        pop currentMoves
        mov esi,OFFSET bLevelStates2
    .ELSEIF level == 3
        mov cCharPosX,6
        mov cCharPosY,2
        push [maxMoves+3*TYPE SDWORD] ; 8
        pop currentMoves
        mov esi,OFFSET bLevelStates3
    .ELSEIF level == 4
        m2m currentLevel,3
        mov cCharPosX,6
        mov cCharPosY,2
        push [maxMoves+3*TYPE SDWORD] ; 8
        pop currentMoves
        mov esi,OFFSET bLevelStates3
    .ENDIF
    ; Reset tiles
    xor ecx,ecx
CopyLoop:
    mov al,BYTE PTR [esi+ecx]
    mov bSokobanStates[ecx],al
    inc ecx
    cmp ecx,TOTAL_COLS*TOTAL_ROWS
    jnz CopyLoop

    ret
ResetGame ENDP

PlayBGM PROC
	LOCAL mciOpenParms:MCI_OPEN_PARMS, mciPlayParms:MCI_PLAY_PARMS

	mov eax, hWnd
	mov mciPlayParms.dwCallback, eax

	mov eax, OFFSET playerType
	mov mciOpenParms.lpstrDeviceType, eax
	mov eax, OFFSET filePath
	mov mciOpenParms.lpstrElementName, eax
	mov eax, OFFSET playerAlias
	mov mciOpenParms.lpstrAlias, eax

 	invoke mciSendCommand, 0, MCI_OPEN,MCI_OPEN_TYPE or MCI_OPEN_ELEMENT, ADDR mciOpenParms

	mov eax, mciOpenParms.wDeviceID
	mov playerId, eax

	invoke mciSendCommand, playerId, MCI_PLAY, MCI_NOTIFY, ADDR mciPlayParms

	ret
PlayBGM ENDP

END Main