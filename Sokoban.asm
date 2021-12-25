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
        WS_EX_LEFT or WS_EX_ACCEPTFILES,  ; dwExStyle
        ADDR szClassName,                 ; lpClassName
        ADDR szDisplayName,               ; lpWindowName
        WS_OVERLAPPEDWINDOW,              ; dwStyle
        WndX,WndY,WndWidth,WndHeight,                  ; Initial position and size
        0,0,                              ; hWndParent hMenu
        hInstance,0                       ; hInstance lpParam
    mov hWnd,eax    ; save the handle to hWnd

    ; invoke LoadMenu,hInstance,600
    ; invoke SetMenu,hWnd,eax

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
    LOCAL hdc:HDC,  hdcMem:HDC
    LOCAL row:DWORD, col:DWORD
    LOCAL drawPosX:DWORD, drawPosY:DWORD

    .IF uMsg==WM_DESTROY
        invoke PostQuitMessage,NULL

    .ELSEIF uMsg==WM_CREATE
        ; invoke  LoadBitmap,hInstance,ADDR bmpBoxName
        invoke  LoadImage,hInstance,ADDR bmpBoxName,IMAGE_BITMAP,0,0,
           LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
        mov hBitmap,eax
        invoke  LoadImage,hInstance,ADDR bmpCharName,IMAGE_BITMAP,0,0,
           LR_DEFAULTSIZE or LR_LOADTRANSPARENT or LR_LOADMAP3DCOLORS
        mov hCharBitmap,eax
        invoke  UpdateWindow,hWndd

    .ELSEIF uMsg==WM_PAINT
        invoke  BeginPaint,hWndd,ADDR paintStruct
        mov hdc,eax ; the destination device context
        ; Bitmaps can only be selected into memory DC's. A single bitmap cannot be selected into more than one DC at the same time.
        invoke  CreateCompatibleDC,eax ;turns into a memory DC
        mov     hdcMem,eax
        ; invoke  BitBlt,hdc,0,0,WndWidth,WndHeight,hdcMem,
        ;         0,0,SRCCOPY

        mov ecx, 8
        mov row,0
        mov drawPosY,0
        mov edi,0
    DrawRow:   
        push ecx
        mov ecx, 8
        mov col,0
        mov drawPosX, 0

    DrawCol:
        push ecx
        mov eax,col
        mov ebx,row
        .IF  ebx == cCharPosY && eax == cCharPosX
            ; Draw Box
            invoke  SelectObject,hdcMem,hCharBitmap
            invoke  BitBlt,hdc,drawPosX,drawPosY,32,32,hdcMem,
                    0,0,SRCCOPY
        .ELSE
            ; Draw Character
            invoke  SelectObject,hdcMem,hBitmap
            invoke  BitBlt,hdc,drawPosX,drawPosY,32,32,hdcMem,
                    0,0,SRCCOPY
        .endif
        inc edi
        inc col
        add drawPosX,32

        pop ecx
        dec ecx
        jnz DrawCol

        inc row
        add drawPosY,32

        pop ecx
        dec ecx
        jnz DrawRow

        invoke  DeleteDC,hdcMem
        invoke  EndPaint,hWndd,ADDR paintStruct

    .ELSEIF uMsg==WM_KEYUP
        .IF wParam==VK_UP
            dec cCharPosY
        .ELSEIF wParam==VK_DOWN
            inc cCharPosY
        .ELSEIF wParam==VK_LEFT
            dec cCharPosX
        .ELSEIF wParam==VK_RIGHT
            inc cCharPosX
        .ENDIF
        ; If both parameters are NULL, the entire client area is added to the update region.
        ; invoke RedrawWindow,hWndd, 0, 0, RDW_INVALIDATE or RDW_UPDATENOW
        invoke  InvalidateRect,hWndd,ADDR redrawRange,1
        invoke  UpdateWindow,hWndd
        
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

END Main