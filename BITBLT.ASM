; #########################################################################

      .386
      .model flat, stdcall  ; 32 bit memory model
      option casemap :none  ; case sensitive

      include bitblt.inc    ; local includes for this file

.const
IDM_TEST equ 1
IDM_HELLO equ 2
IDM_GOODBYE equ 3
IDM_EXIT equ 4
        
WM_FINISH equ WM_USER+100h

teste	equ		101
sweep   equ		102
shipBmpId equ 103
space_backgroundBmpId equ 104
asteroid1BmpId equ 105
asteroid2BmpId equ 106
asteroid3BmpId equ 107

BLACK_COLOR equ 0h
WHITE_COLOR equ 0ffffffh


CREF_TRANSPARENT  EQU 0FF00FFh
CREF_TRANSPARENT2 EQU 0FF0000h

.data
  szDisplayName db "Asteroids",0
  CommandLine   dd ?
  hWnd          dd ?
  hInstance     dd ?
  hIcon         dd ?
  hBmp          dd ?
  hBmp2         dd ?
  memDC2        dd 0 
  x		          dd 0
  trasp		      dd 0
  achou		      dd 0
  lRect         RECT <>
  hitpoint 	    POINT <>
  posicao       POINT <>
  shipPosition  POINT <10, 10>

  ;shipSprites   POINT {0, 0}, {36, 0}, {72, 0}, {108, 0}
  shipSpritesIndex  dd 2
  shipVelocity      POINT {10, 10}
  shipAcceleration  POINT {0, 0}

  ThreadID dd 0

  shipBmp         dd ?
  space_backgroundBmp dd ?
  asteroid1Bmp dd ?
  asteroid2Bmp dd ?
  asteroid3Bmp dd ?

	ExitCode dd 0
	hThread dd 0
	hEventStart dd 0
        
  AppName  db "Our First Window",0
  MenuName db "FirstMenu",0
  Test_string db "You selected Test menu item",0
  error_string db "Error loading image",0
  buffer db 300 dup(?)
  header_format db "%d",0

  EventStop BOOL FALSE
; #########################################################################

.code

start:
      invoke GetModuleHandle, NULL
      mov hInstance, eax
      jmp l1
	tes db 	'Alo PD ',0
l1:
      
      invoke LoadBitmap,hInstance, shipBmpId
      mov shipBmp, eax

      invoke LoadBitmap,hInstance, space_backgroundBmpId
      mov space_backgroundBmp, eax

      .if space_backgroundBmp == NULL
        invoke MessageBox, NULL, ADDR error_string, ADDR szDisplayName, MB_OK
      .endif

      invoke LoadBitmap,hInstance, asteroid1BmpId
      mov asteroid1Bmp, eax

      invoke LoadBitmap,hInstance, asteroid2BmpId
      mov asteroid2Bmp, eax

      invoke LoadBitmap,hInstance, asteroid3BmpId
      mov asteroid3Bmp, eax

      invoke LoadBitmap,hInstance, sweep
      mov hBmp2, eax

      
      invoke GetCommandLine
      mov CommandLine, eax

      invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
      invoke ExitProcess,eax

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

      ;====================
      ; Put LOCALs on stack
      ;====================

      LOCAL wc   :WNDCLASSEX
      LOCAL msg  :MSG
      LOCAL Wwd  :DWORD
      LOCAL Wht  :DWORD
      LOCAL Wtx  :DWORD
      LOCAL Wty  :DWORD

      ;==================================================
      ; Fill WNDCLASSEX structure with required variables
      ;==================================================

      invoke LoadIcon,hInst,500    ; icon ID
      mov hIcon, eax

      szText szClassName,"Project_Class"

      mov wc.cbSize,         sizeof WNDCLASSEX
      mov wc.style,          CS_BYTEALIGNWINDOW
      mov wc.lpfnWndProc,    offset WndProc
      mov wc.cbClsExtra,     NULL
      mov wc.cbWndExtra,     NULL
      m2m wc.hInstance,      hInst
      mov wc.hbrBackground,  COLOR_BTNFACE+1
      mov wc.lpszMenuName,  OFFSET MenuName
      mov wc.lpszClassName,  offset szClassName
      m2m wc.hIcon,          hIcon
        invoke LoadCursor,NULL,IDC_ARROW
      mov wc.hCursor,        eax
      m2m wc.hIconSm,        hIcon

      invoke RegisterClassEx, ADDR wc

      ;================================
      ; Centre window at following size
      ;================================

      mov Wwd, 500
      mov Wht, 350

      invoke GetSystemMetrics,SM_CXSCREEN
      invoke TopXY,Wwd,eax
      mov Wtx, eax

      invoke GetSystemMetrics,SM_CYSCREEN
      invoke TopXY,Wht,eax
      mov Wty, eax

      invoke CreateWindowEx,WS_EX_LEFT,
                            ADDR szClassName,
                            ADDR szDisplayName,
                            WS_OVERLAPPEDWINDOW,
                            Wtx,Wty,Wwd,Wht,
                            NULL,NULL,
                            hInst,NULL
      mov   hWnd,eax

      ;invoke LoadMenu,hInst,600  ; menu ID
      ;invoke SetMenu,hWnd,eax

      invoke ShowWindow,hWnd,SW_SHOWNORMAL
      invoke UpdateWindow,hWnd

      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0
      cmp eax, 0
      je ExitLoop
      invoke TranslateMessage, ADDR msg
      invoke DispatchMessage,  ADDR msg
      jmp StartLoop
    ExitLoop:

      return msg.wParam

WinMain endp

; #########################################################################

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

    LOCAL var    :DWORD
    LOCAL caW    :DWORD
    LOCAL caH    :DWORD
    LOCAL Rct    :RECT
    LOCAL hDC    :DWORD
    LOCAL Ps     :PAINTSTRUCT
    LOCAL buffer1[128]:BYTE  ; these are two spare buffers
    LOCAL buffer2[128]:BYTE  ; for text manipulation etc..

    .if uMsg == WM_COMMAND
    ;======== menu commands ========
		mov eax,wParam
		.IF ax==IDM_TEST
			invoke MessageBox,NULL,ADDR Test_string,OFFSET AppName,MB_OK
		.ELSE
			invoke DestroyWindow,hWnd
		.ENDIF    
    .elseif uMsg == WM_CREATE
	  	mov posicao.x,200
		mov posicao.y,0
		
		invoke CreateEvent,NULL,FALSE,FALSE,NULL
		mov    hEventStart,eax
		
		mov    eax,OFFSET ThreadProc
		invoke CreateThread,NULL,NULL,eax,\
		                    NULL,NORMAL_PRIORITY_CLASS,\
		                     ADDR ThreadID
		mov    hThread,eax

		
    .elseif uMsg == WM_SIZE
;    // obter o tamanho da janela
    
    .elseif uMsg == WM_MOUSEMOVE
    		mov eax,lParam
    		and eax,0ffffh
    		mov hitpoint.x,eax
    		mov eax,lParam
    		shr eax,16
    		mov hitpoint.y,eax
    		invoke InvalidateRect,hWnd,NULL,TRUE
    
    
    .elseif uMsg == WM_LBUTTONDOWN
		mov eax,lParam
		and eax,0ffffh
		mov hitpoint.x,eax
		mov eax,lParam
		shr eax,16
		mov hitpoint.y,eax
		
		mov eax, trasp 
		not	eax
		mov trasp, eax

		mov	achou,1
		mov 	eax,hitpoint.x
		cmp	eax,140
		jb	nao
		cmp	eax,172
		jg	nao
		mov 	ecx,hitpoint.y
		cmp	ecx,250
		jb	nao
		cmp	ecx,282
		jg	nao
		mov	achou,0
	nao:	
		invoke InvalidateRect,hWnd,NULL,TRUE

    .elseif uMsg == WM_PAINT
        invoke BeginPaint,hWin,ADDR Ps
          mov hDC, eax
          invoke Paint_Proc,hWin,hDC
        invoke EndPaint,hWin,ADDR Ps
        return 0

    .elseif uMsg == WM_CLOSE
    
    .elseif uMsg == WM_CHAR
	    inc	x
	    mov	eax,x
	    mov	lRect.left, eax
	    add	eax,168
	    mov	lRect.right, eax
	    mov	lRect.top,10
	    mov	lRect.bottom, 68
	    
	    invoke InvalidateRect, hWnd, addr lRect,TRUE

   .elseif uMsg == WM_RBUTTONDOWN
   	  ;  invoke PostMessage,hWnd,WM_FINISH,NULL,NULL
   	 ; invoke SetEvent,hEventStart
   	

   .elseif uMsg == WM_KEYDOWN
        .if wParam == VK_RIGHT
            .if shipSpritesIndex == 0
                mov shipSpritesIndex, 15
            .else
                dec shipSpritesIndex
            .endif
        .elseif wParam == VK_LEFT
            .if shipSpritesIndex == 15
                mov shipSpritesIndex, 0
            .else
                inc shipSpritesIndex
            .endif
        .elseif wParam == VK_UP
            .if shipSpritesIndex == 0
                dec shipAcceleration.y
                dec shipAcceleration.y
            .elseif shipSpritesIndex == 1
                dec shipAcceleration.y
                dec shipAcceleration.y
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 2
                dec shipAcceleration.y
                dec shipAcceleration.y
                dec shipAcceleration.x
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 3
                dec shipAcceleration.y
                dec shipAcceleration.x
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 4
                dec shipAcceleration.x
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 5
                inc shipAcceleration.y
                dec shipAcceleration.x
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 6
                inc shipAcceleration.y
                inc shipAcceleration.y
                dec shipAcceleration.x
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 7
                inc shipAcceleration.y
                inc shipAcceleration.y
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 8
                inc shipAcceleration.y
                inc shipAcceleration.y
            .elseif shipSpritesIndex == 9
                inc shipAcceleration.y
                inc shipAcceleration.y
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 10
                inc shipAcceleration.y
                inc shipAcceleration.y
                inc shipAcceleration.x
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 11
                inc shipAcceleration.y
                inc shipAcceleration.x
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 12
                inc shipAcceleration.x
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 13
                dec shipAcceleration.y
                inc shipAcceleration.x
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 14
                dec shipAcceleration.y
                dec shipAcceleration.y
                inc shipAcceleration.x
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 15
                dec shipAcceleration.y
                dec shipAcceleration.y
                inc shipAcceleration.x
            .endif
        .elseif wParam == VK_DOWN
            .if shipSpritesIndex == 0
                inc shipAcceleration.y
                inc shipAcceleration.y
            .elseif shipSpritesIndex == 1
                inc shipAcceleration.y
                inc shipAcceleration.y
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 2
                inc shipAcceleration.y
                inc shipAcceleration.y
                inc shipAcceleration.x
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 3
                inc shipAcceleration.y
                inc shipAcceleration.x
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 4
                inc shipAcceleration.x
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 5
                dec shipAcceleration.y
                inc shipAcceleration.x
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 6
                dec shipAcceleration.y
                dec shipAcceleration.y
                inc shipAcceleration.x
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 7
                dec shipAcceleration.y
                dec shipAcceleration.y
                inc shipAcceleration.x
            .elseif shipSpritesIndex == 8
                dec shipAcceleration.y
                dec shipAcceleration.y
            .elseif shipSpritesIndex == 9
                dec shipAcceleration.y
                dec shipAcceleration.y
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 10
                dec shipAcceleration.y
                dec shipAcceleration.y
                dec shipAcceleration.x
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 11
                dec shipAcceleration.y
                dec shipAcceleration.x
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 12
                dec shipAcceleration.x
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 13
                inc shipAcceleration.y
                dec shipAcceleration.x
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 14
                inc shipAcceleration.y
                inc shipAcceleration.y
                dec shipAcceleration.x
                dec shipAcceleration.x
            .elseif shipSpritesIndex == 15
                inc shipAcceleration.y
                inc shipAcceleration.y
                dec shipAcceleration.x
            .endif
        .endif
   .elseif uMsg == WM_FINISH

	inc posicao.x
	inc posicao.y

	.if posicao.x > 400
	   mov posicao.x,0
	   mov posicao.y,0
	.endif 
	invoke InvalidateRect,hWnd,NULL,TRUE	     
    .elseif uMsg == WM_DESTROY
    	mov  EventStop,TRUE
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam

    ret

WndProc endp

; ########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp

; #########################################################################

Paint_Proc proc hWin:DWORD, hDC:DWORD

    LOCAL hOld:DWORD
    LOCAL memDC :DWORD
 
    
    invoke CreateCompatibleDC,hDC
    mov memDC, eax
    
    ;invoke SelectObject,memDC,hBmp
    ;mov hOld, eax

    ;invoke BitBlt,hDC,10,10,166,68,memDC,20,0,SRCCOPY
    ;invoke BitBlt,hDC, hitpoint.x,hitpoint.y,166,68,memDC,0,0,SRCCOPY
    ;invoke BitBlt,hDC,10,200,166,68,memDC,0,0,SRCCOPY

    invoke SelectObject,hDC,asteroid2Bmp ; select background
    invoke BitBlt,hDC,0,0,50,50,memDC,0,0,SRCCOPY

    invoke SelectObject,hDC,hOld
    
    invoke SelectObject,memDC,shipBmp  ; select ship image
    mov hOld, eax

    ;invoke wsprintfA, ADDR buffer, ADDR header_format, shipSprites[8].x
    ;invoke MessageBox, NULL, ADDR buffer, ADDR szDisplayName, MB_OK

    mov eax, 36
    mul shipSpritesIndex

    ; paint the ship
    invoke TransparentBlt,hDC, \
    ;paint point
    shipPosition.x, shipPosition.y, \
    ;ship size
    36,36, \
    memDC, \
    ;current_sprite
    eax, 0, \
    ;ship size
    36,36, \
    ;color to be ignored
    WHITE_COLOR

    invoke SelectObject,memDC,hBmp2  ; selecionei o novo bitmap
    mov hOld, eax
          
    invoke BitBlt,hDC,50,250,32,32,memDC,0,0,SRCCOPY
    invoke BitBlt,hDC,90,250,32,32,memDC,0,416,SRCCOPY
    invoke BitBlt,hDC,140,250,32,32,memDC,0,416,SRCCOPY
    
    INVOKE  TransparentBlt,hDC,190,250,32,32,memDC,0,256,32,32,CREF_TRANSPARENT
    
    INVOKE  TransparentBlt,hDC,240,250,32,32,memDC,0,512,32,32,CREF_TRANSPARENT
    
    cmp	trasp,0
    jne pula
    INVOKE  TransparentBlt,hDC,90,250,32,32,memDC,0,32,32,32,CREF_TRANSPARENT    

    cmp achou,0
    jne  pula
    INVOKE  TransparentBlt,hDC,140,250,32,32,memDC,0,256,32,32,CREF_TRANSPARENT
    
    
    
pula:

    
    INVOKE  TransparentBlt,hDC,posicao.x,posicao.y,32,32,memDC,0,256,32,32,CREF_TRANSPARENT
    
    
    invoke SelectObject,hDC,hOld
    invoke DeleteDC,memDC

    return 0

Paint_Proc endp

; ########################################################################


ThreadProc PROC USES ecx Param:DWORD

        invoke WaitForSingleObject,hEventStart,1000 ;INFINITE

	.IF eax == WAIT_TIMEOUT	
	           invoke PostMessage,hWnd,WM_FINISH,NULL,NULL
	           jmp   ThreadProc     
	.ELSEIF eax == WAIT_OBJECT_0	
	         invoke PostMessage,hWnd,WM_FINISH,NULL,NULL
	          jmp   ThreadProc
        .ENDIF
        
        jmp   ThreadProc
        
        ret
ThreadProc ENDP


end start
