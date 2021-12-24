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

    invoke LoadMenu,hInstance,600
    invoke SetMenu,hWnd,eax

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
	.IF uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
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
		invoke DefWindowProc,hWndd,uMsg,wParam,lParam
		ret
	.ENDIF
	xor	eax,eax
	ret
WndProc ENDP

END Main