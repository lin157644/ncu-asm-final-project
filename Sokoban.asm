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
    invoke LoadIcon,hInstance,IDI_ICON
    mov wndclass.hIcon,         eax
    invoke LoadCursor,          NULL,IDC_ARROW
    mov wndclass.hCursor,       eax
    m2m wndclass.hbrBackground, COLOR_BTNFACE+1
    mov wndclass.lpszMenuName,  0
    mov wndclass.lpszClassName, OFFSET szClassName  ; 取用 Class 時的名稱
    mov wndclass.hIconSm,       0

    invoke RegisterClassEx, ADDR wndclass

    call SetAdjustedWndRect
    call InitWndPos

    ; Ex for extra style
    invoke  CreateWindowEx,
        WS_EX_LEFT or WS_EX_ACCEPTFILES,; dwExStyle
        ADDR szClassName,               ; lpClassName
        ADDR szDisplayName,             ; lpWindowName
        WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU,            ; dwStyle
        wndX,wndY,
        wndRect.right,
        wndRect.bottom,                 ; Initial position and size
        0,0,                            ; hWndParent hMenu
        hInstance,0                     ; hInstance lpParam
    mov hWnd,eax                        ; save the handle to hWnd

    invoke ShowWindow,hWnd, SW_SHOWNORMAL
    invoke UpdateWindow,hWnd

    mov frameCounter,0
    .WHILE  TRUE
        invoke  PeekMessage,offset msg,NULL,0,0,PM_REMOVE
        .IF eax
            .BREAK  .IF msg.message == WM_QUIT
            invoke  DispatchMessage,offset msg
        .ELSE
            call Gameloop
            invoke  Sleep,30
        .ENDIF
    .ENDW
    mov     eax,msg.wParam
    invoke ExitProcess,eax
Main ENDP

Gameloop PROC
    inc frameCounter
    .IF gameState == GSTATE_TRANS
        mov eax,frameCounter
        sub eax,transition_start
        .IF eax>TRANS_DUR
            mov gameState,GSTATE_LEVEL
        .ENDIF
    .ENDIF
    .IF gameState == GSTATE_LEVEL
        mov eax,frameCounter
        mov edx,eax ; eax=edx
        shr eax,2   ; eax/4
        shl eax,2   ; eax/4*4
        sub edx,eax

    .ENDIF
    invoke  InvalidateRect,hWnd,ADDR redrawRange,1
    ret
Gameloop ENDP

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

        invoke  CreateCompatibleBitmap,hdc,WINDOW_WIDTH,WINDOW_HEIGHT
        mov     hbmBuffer,eax

        invoke  SelectObject,hdcBuffer,hbmBuffer
        ; mov     hbmOldBuffer,eax

        .IF ! (gameState == GSTATE_LEVEL)
            jmp EndTilePaint
        .ENDIF

        ; Tile paint
        ; Same as MAKEROP4 macro
        mov dwRop, SRCCOPY  ; high-order-backgroud-1-black
        shl dwRop,8
        and dwRop,0FF000000h
        or  dwRop, SRCPAINT ; low-order-foreground-0-white

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
            xor edx,edx
            mov eax,frameCounter
            shr eax,2 ; eax/4 每四Frame換一個圖片
            mov ebx,6
            div ebx ; Not best practice
            shl edx,5   ; *32
            mov spriteOffsetX, edx
            invoke  SelectObject,hdcMem,hbmSlime
            invoke MaskBlt,hdcBuffer,drawPosX,drawPosY,32,32,
                        hdcMem,spriteOffsetX,0,
                        hbmSlimeMask,spriteOffsetX,0,
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
        .ELSE
            ; Draw Void basically nothing
        .endif

        .IF edi == cCharPosX && esi == cCharPosY
            ; Draw Charactor
            xor edx,edx
            mov eax,frameCounter
            shr eax,2 ; eax/4 每四Frame換一個圖片
            mov ebx,6
            div ebx ; Not best practice
            shl edx,5   ; *32
            mov spriteOffsetX, edx
            .IF charFacing
                add drawPosX,TILE_WIDTH
                invoke  SelectObject,hdcMem,hbmKnightMask
                invoke  StretchBlt,hdcBuffer,drawPosX,drawPosY,-TILE_WIDTH,TILE_HEIGHT,
                                    hdcMem,spriteOffsetX,0,TILE_WIDTH,TILE_HEIGHT,SRCAND
                invoke  SelectObject,hdcMem,hbmKnight
                invoke  StretchBlt,hdcBuffer,drawPosX,drawPosY,-TILE_WIDTH,TILE_HEIGHT,
                                    hdcMem,spriteOffsetX,0,TILE_WIDTH,TILE_HEIGHT,SRCPAINT
                sub drawPosX,TILE_WIDTH
            .ELSE
                invoke  SelectObject,hdcMem,hbmKnightMask
                invoke  StretchBlt,hdcBuffer,drawPosX,drawPosY,TILE_WIDTH,TILE_HEIGHT,
                                    hdcMem,spriteOffsetX,0,TILE_WIDTH,TILE_HEIGHT,SRCAND
                invoke  SelectObject,hdcMem,hbmKnight
                invoke  StretchBlt,hdcBuffer,drawPosX,drawPosY,TILE_WIDTH,TILE_HEIGHT,
                                    hdcMem,spriteOffsetX,0,TILE_WIDTH,TILE_HEIGHT,SRCPAINT
            .ENDIF
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

        .IF pushAnimFrame
            dec pushAnimFrame
            m2m spriteOffsetX,pushAnimFrame
            shr spriteOffsetX,1
            shl spriteOffsetX,5
            mov eax,96
            sub eax,spriteOffsetX
            mov spriteOffsetX,eax
            invoke  SelectObject,hdcMem,hbmPushAnimMask
            invoke  BitBlt,hdcBuffer,pushAnimPosX,pushAnimPosY,TILE_WIDTH,TILE_HEIGHT,hdcMem,
                    spriteOffsetX,0,SRCAND
            invoke  SelectObject,hdcMem,hbmPushAnim
            invoke  BitBlt,hdcBuffer,pushAnimPosX,pushAnimPosY,TILE_WIDTH,TILE_HEIGHT,hdcMem,
                    spriteOffsetX,0,SRCPAINT
        .ENDIF

    EndTilePaint:
        ; Change text property
        invoke  SetTextColor,hdcBuffer,0ffffffh
        invoke  SetBkColor,hdcBuffer,0
        .IF gameState==GSTATE_TITLE
            invoke  CreateFont,30,0,0,0,FW_BOLD,0,0,0,
                    ANSI_CHARSET,OUT_STRING_PRECIS,CLIP_CHARACTER_PRECIS,ANTIALIASED_QUALITY,FF_MODERN,NULL
            mov     hFont,eax
            ; Just in cast not to overwrite the old one.
            invoke  SelectObject,hdcBuffer,hFont
            mov     hTitleOld,eax
            invoke DrawText,hdcBuffer,ADDR titleStr,-1,ADDR redrawRange, DT_WORDBREAK or DT_CENTER or DT_VCENTER or DT_SINGLELINE
            invoke SelectObject,hdcBuffer,hTitleOld
            invoke DeleteDC,eax ; Recover old handle
            invoke DrawText,hdcBuffer,ADDR pressSpaceStr,-1,ADDR pressSpaceRect, DT_WORDBREAK or DT_CENTER or DT_VCENTER or DT_SINGLELINE
        .ELSEIF gameState==GSTATE_TUTORIAL
            invoke  CreateFont,18,0,0,0,FW_BOLD,0,0,0,
                    ANSI_CHARSET,OUT_STRING_PRECIS,CLIP_CHARACTER_PRECIS,ANTIALIASED_QUALITY,FF_MODERN,NULL
            mov     hFont,eax
            ; Just in cast not to overwrite the old one.
            invoke  SelectObject,hdcBuffer,hFont
            mov     hTitleOld,eax
            invoke DrawText,hdcBuffer,ADDR tutorialStr,-1,ADDR pressSpaceRect, DT_WORDBREAK or DT_CENTER
            invoke SelectObject,hdcBuffer,hTitleOld
            invoke DeleteDC,eax
        .ELSEIF gameState==GSTATE_TRANS
            mov  eax,currentLevel
            mov  transLevelStr[LENGTHOF transLevelStr-2],al
            add  transLevelStr[LENGTHOF transLevelStr-2],30h
            invoke DrawText,hdcBuffer,ADDR transLevelStr,-1,ADDR redrawRange, DT_WORDBREAK or DT_CENTER or DT_VCENTER or DT_SINGLELINE
        .ELSEIF gameState==GSTATE_LEVEL
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
            ; Draw level and move left text
            invoke  TextOut,hdcBuffer,0,TOTAL_ROWS*TILE_HEIGHT,ADDR currentLevelStr,LENGTHOF currentLevelStr-1
            invoke  TextOut,hdcBuffer,TOTAL_COLS*TILE_WIDTH/2,TOTAL_ROWS*TILE_HEIGHT,ADDR currentMovesStr,LENGTHOF currentMovesStr-1
        .ELSEIF gameState==GSTATE_WIN
            invoke DrawText,hdcBuffer,ADDR endingStr,-1,ADDR pressSpaceRect, DT_WORDBREAK or DT_CENTER ;or DT_VCENTER or DT_SINGLELINE
        .ENDIF

        ; FPS
        ; invoke RenderFPS,hdcBuffer

        ; Buffer to window (Double buffering)
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
        ; esi for Index param
        .IF wParam==52h ; R
            invoke ResetGame,currentLevel
            call StartLevelTrans
        .ELSEIF wParam==31h ; 1
            invoke ResetGame,1
            call StartLevelTrans
        .ELSEIF wParam==32h ; 2
            invoke ResetGame,2
            call StartLevelTrans
        .ELSEIF wParam==33h ; 3
            invoke ResetGame,3
            call StartLevelTrans
        .ELSEIF wParam==4dh ; M
            invoke PauseBGM
        .ELSEIF wParam==VK_SPACE && gameState==GSTATE_TITLE
            mov gameState,GSTATE_TUTORIAL
        .ELSEIF wParam==VK_SPACE && gameState==GSTATE_TUTORIAL
            call StartLevelTrans
        .ELSEIF (wParam==VK_SPACE && gameState==GSTATE_WIN) || wParam==VK_ESCAPE
            invoke PostQuitMessage,NULL
            xor eax,eax
            ret
        .ELSEIF wParam==VK_ESCAPE
            invoke PostQuitMessage,NULL
            xor eax,eax
            ret
        .ELSEIF gameState==GSTATE_LEVEL
            .IF wParam==VK_UP
                invoke ProcessMoveLogic,esi,0,-1
            .ELSEIF wParam==VK_DOWN
                invoke ProcessMoveLogic,esi,0,1
            .ELSEIF wParam==VK_LEFT
                mov charFacing,1
                invoke ProcessMoveLogic,esi,-1,0
            .ELSEIF wParam==VK_RIGHT
                mov charFacing,0
                invoke ProcessMoveLogic,esi,1,0
            .ENDIF
        .ENDIF
        ; If both parameters are NULL, the entire client area is added to the update region.
        ; invoke RedrawWindow,hWndd, 0, 0, RDW_INVALIDATE or RDW_UPDATENOW
    .ELSEIF uMsg==WM_COMMAND
    ; For menu, accelerator...etc. Pretty much useless in this project. 
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
    ; Load tiles
    invoke  LoadImage,hInstance,IDB_FLOOR,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmFloor,eax

    invoke  LoadImage,hInstance,IDB_WALL,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmWall,eax

    invoke  LoadImage,hInstance,IDB_BOX,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmBox,eax

    invoke  LoadImage,hInstance,IDB_SPIKE,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmSpike,eax

    invoke  LoadImage,hInstance,IDB_STAIR,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmStair,eax

    invoke  LoadImage,hInstance,IDB_SPIKE_BOX,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmSpikeBox,eax

    invoke  LoadImage,hInstance,IDB_KEY,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmKey,eax

    invoke  LoadImage,hInstance,IDB_DOOR,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmDoor,eax

    invoke  LoadImage,hInstance,IDB_KNIGHT,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmSlime,eax

    invoke  LoadImage,hInstance,IDB_KNIGHT_MASK,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmSlimeMask,eax

    invoke  LoadImage,hInstance,IDB_SLIME,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmKnight,eax

    invoke  LoadImage,hInstance,IDB_SLIME_MASK,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmKnightMask,eax

    invoke  LoadImage,hInstance,IDB_PUSH_ANIM,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmPushAnim,eax

    invoke  LoadImage,hInstance,IDB_PUSH_ANIM_MASK,IMAGE_BITMAP,0,0,
        LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
    mov hbmPushAnimMask,eax

    ret
LoadBitmapHandlers ENDP

ProcessMoveLogic PROC USES eax esi,
    currentIndex:DWORD ,xOffset:SDWORD, yOffset:SDWORD

    m2m eax,yOffset
    shl eax,3
    add eax,xOffset
    mov esi,currentIndex
    add esi,eax
    .IF bSokobanStates[esi] == 0 || bSokobanStates[esi] == 3
        ; Knight movement
        mov eax,xOffset
        add cCharPosX,eax
        mov eax,yOffset
        add cCharPosY,eax
    .ELSEIF bSokobanStates[esi] == 1
        ; PUNCH THE WALLLLLL!!!!!!!!
        invoke RenderPushAnim,xOffset,yOffset
    .ELSEIF bSokobanStates[esi] == 2
        ; Barrel
        .IF bSokobanStates[esi+eax] == 0; If movable
            mov bSokobanStates[esi],0
            mov bSokobanStates[esi+eax],2
        .ELSEIF  bSokobanStates[esi+eax] == 3
            mov bSokobanStates[esi],6
            mov bSokobanStates[esi+eax],2
        .ENDIF
        invoke RenderPushAnim,xOffset,yOffset
    .ELSEIF bSokobanStates[esi] == 4
        ; Move or Kill Enemy
        .IF bSokobanStates[esi+eax] == 0
            mov bSokobanStates[esi],0
            mov bSokobanStates[esi+eax],4
        .ELSEIF bSokobanStates[esi+eax] == 1 || bSokobanStates[esi+eax] == 2 || bSokobanStates[esi+eax] == 3
            mov bSokobanStates[esi],0
        .ENDIF
        invoke RenderPushAnim,xOffset,yOffset
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
        invoke RenderPushAnim,xOffset,yOffset
    .ELSEIF bSokobanStates[esi] == 7
        ; Key
        mov eax,xOffset
        add cCharPosX,eax
        mov eax,yOffset
        add cCharPosY,eax
        mov hasKeyState,1
        mov bSokobanStates[esi],0
        invoke PlaySound,IDR_WAVE_GET_KEY,NULL,SND_ASYNC or SND_RESOURCE or SND_NODEFAULT
    .ELSEIF bSokobanStates[esi] == 8
        ; Door
        .IF hasKeyState==1
            mov bSokobanStates[esi],0
            invoke PlaySound,IDR_WAVE_GET_KEY,NULL,SND_ASYNC or SND_RESOURCE or SND_NODEFAULT
        .ENDIF
    .ENDIF

    ; Caculate the moves
    dec currentMoves
    ; Take one extra move if on spike when end
    .IF bSokobanStates[esi] == 3
        ;Spike
        dec currentMoves
        invoke PlaySound,IDR_WAVE_ON_SPIKE,NULL,SND_ASYNC or SND_RESOURCE or SND_NODEFAULT
    .ENDIF
    ; Check moves left
    .IF currentMoves <= 0
        invoke ResetGame,currentLevel
        mov gameState,GSTATE_TRANS
        push frameCounter
        pop transition_start
    .ENDIF

    ; Go to next level?
    .IF bSokobanStates[esi] == 5
        ; Stair
        inc currentLevel
        mov gameState,GSTATE_TRANS
        push frameCounter
        pop transition_start
        invoke ResetGame,currentLevel
    .ENDIF

    ret
ProcessMoveLogic ENDP

ResetGame PROC USES eax ecx esi,
    level:DWORD
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
        inc currentMoves
        mov gameState,GSTATE_WIN
        ret
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

    m2m mciPlayParms.dwCallback, hWnd
    m2m mciOpenParms.lpstrDeviceType,OFFSET playerType
    m2m mciOpenParms.lpstrElementName,OFFSET bgmPath
    m2m mciOpenParms.lpstrAlias,OFFSET playerAlias
    invoke mciSendCommand, 0, MCI_OPEN,MCI_OPEN_TYPE or MCI_OPEN_ELEMENT, ADDR mciOpenParms
 
    m2m playerId, mciOpenParms.wDeviceID
    invoke mciSendCommand, playerId, MCI_PLAY, MCI_NOTIFY, ADDR mciPlayParms

    ret
PlayBGM ENDP

PauseBGM PROC USES eax
    LOCAL mciPlayParms:MCI_PLAY_PARMS, mciStatusParms:MCI_STATUS_PARMS

    mov mciStatusParms.dwItem,MCI_STATUS_MODE
    invoke mciSendCommand, playerId, MCI_STATUS, MCI_NOTIFY or MCI_STATUS_ITEM, ADDR mciStatusParms
    .IF eax!=0
        ret
    .ENDIF
    m2m mciPlayParms.dwCallback, hWnd
    .IF mciStatusParms.dwReturn == MCI_MODE_PLAY
        invoke mciSendCommand, playerId, MCI_PAUSE, MCI_NOTIFY, ADDR mciPlayParms
    .ELSE
        invoke mciSendCommand, playerId, MCI_PLAY, MCI_NOTIFY, ADDR mciPlayParms
    .ENDIF

    ret
PauseBGM ENDP

RenderFPS PROC USES eax,
    hdcBuf:HDC
    mov eax,frameCounter
    mov fpsStr[0],ah
    mov fpsStr[1],al
    invoke  TextOut,hdcBuf,0,0,ADDR fpsStr,2
    ret
RenderFPS ENDP

RenderPushAnim PROC USES eax,
    xPushOffset:SDWORD, yPushOffset:SDWORD
    ; eight frame
    mov pushAnimFrame,8
    m2m pushAnimPosX,cCharPosX
    mov eax,xPushOffset
    add pushAnimPosX,eax
    ; Multiply by 32
    shl pushAnimPosX,5
    m2m pushAnimPosY,cCharPosY
    mov eax,yPushOffset
    add pushAnimPosY,eax
    shl pushAnimPosY,5
    ; PlaySound size limit 100K
    invoke PlaySound,IDR_WAVE_PUSH_SOUND,NULL,SND_ASYNC or SND_RESOURCE or SND_NODEFAULT
    ret
RenderPushAnim ENDP

InitWndPos PROC USES eax
    ; Initial window position
    ; Note: GetDeviceCaps hdcPrimaryMonitor, HORZRES/VERTRES also work.
    invoke GetSystemMetrics,SM_CXSCREEN
    shr eax,1
    sub eax,WINDOW_WIDTH/2
    mov wndX,eax
    invoke GetSystemMetrics,SM_CYSCREEN
    shr eax,1
    sub eax,WINDOW_HEIGHT/2
    mov wndY,eax
    ret
InitWndPos ENDP

SetAdjustedWndRect PROC USES eax
    ; Create the main window with an extended window style
    invoke  AdjustWindowRectEx,ADDR wndRect,WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU,0,0
    mov ebx,wndRect.left
    sub wndRect.right,ebx
    mov ebx,wndRect.top
    sub wndRect.bottom,ebx
    ret
SetAdjustedWndRect ENDP

StartLevelTrans PROC
    mov gameState,GSTATE_TRANS
    push frameCounter
    pop transition_start
    ret
StartLevelTrans ENDP

END Main