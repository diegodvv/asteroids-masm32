; #########################################################################

.386
.model flat, stdcall  ; 32 bit memory model
option casemap :none  ; case sensitive

include Asteroids.inc    ; local includes for this file

BODY STRUCT
    position POINT <>
    velocity POINT <>
    acceleration POINT <>
BODY ENDS

.const
SCREEN_WIDTH equ 800
SCREEN_HEIGHT equ 600
        
WM_FINISH equ WM_USER+100h

shipBmpId equ 100
space_backgroundBmpId equ 101
asteroid1BmpId equ 102
asteroid2BmpId equ 103
asteroid3BmpId equ 104
projectileBmpId equ 105

BLACK_COLOR equ 0000000h
WHITE_COLOR equ 0ffffffh

PROJECTILE_VELOCITY equ 10


CREF_TRANSPARENT  EQU 0FF00FFh
CREF_TRANSPARENT2 EQU 0FF0000h

.data
  szDisplayName db "Asteroids",0
  CommandLine   dd ?
  hWnd          dd ?
  hInstance     dd ?
  hIcon         dd ?
  hBmp          dd ?
  hFont         dd ?
  memDC2        dd 0 
  x		          dd 0
  trasp		      dd 0
  achou		      dd 0
  lRect         RECT <>
  hitpoint 	    POINT <>
  posicao       POINT <>
  randomnum  db  2 dup (?)

  ;shipSprites   POINT {0, 0}, {36, 0}, {72, 0}, {108, 0}
  shipSpritesIndex  dd 2
  ship BODY {{10, 10}, {0, 0}, {0, 0}}
  shipMaxVelocity POINT {10, 10}
  shipProjectiles BODY 30 dup ({{-1, 2}, {3, 4}, {5, 6}})
  asteroids BODY 10 dup ({{-1, -1}, {1, 1}, {1, 0}})
  UpdateThreadID dd 0
  left_down db 0
  right_down db 0
  space_down db 0
  up_down db 0
  down_down db 0

  shipBmp         dd ?
  space_backgroundBmp dd ?
  asteroid1Bmp dd ?
  asteroid2Bmp dd ?
  asteroid3Bmp dd ?
  projectileBmp dd ?

	ExitCode dd 0
	hThread dd 0
	hEventStart dd 0
        
  AppName  db "Our First Window",0
  MenuName db "FirstMenu",0
  Test_string db "You selected Test menu item",0
  error_string db "Error loading image",0
  strEqualNegativeOne db "Not equal to negative one",0
  buffer db 300 dup(?)
  header_format db "P1: x:%d y:%d",0

  EventStop BOOL FALSE
; #########################################################################

.code

start:
      invoke GetModuleHandle, NULL
      mov hInstance, eax
      
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

      invoke LoadBitmap,hInstance, projectileBmpId
      mov projectileBmp, eax

      ; Retrieve a handle to the variable stock font.  
      invoke GetStockObject, DEVICE_DEFAULT_FONT
      mov hFont, eax 
      
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

      mov Wwd, SCREEN_WIDTH
      mov Wht, SCREEN_HEIGHT
    
        mov edi, 0
        .WHILE edi < 240      
          .if asteroids[edi].position.x == -1
            invoke  GetTickCount
            invoke  nseed, eax
            invoke  nrandom, SCREEN_WIDTH
            mov asteroids[edi].position.x, eax

            invoke  GetTickCount
            invoke  nseed, eax
            invoke  nrandom, SCREEN_HEIGHT
            mov asteroids[edi].position.y, eax

            invoke  GetTickCount
            invoke  nseed, eax
            invoke  nrandom, 2
            add eax, 1
            mov asteroids[edi].acceleration.x, eax

            invoke  GetTickCount
            invoke  nseed, eax
            invoke  nrandom, 10
            add eax, -6
            mov asteroids[edi].velocity.y, eax

            invoke  GetTickCount
            invoke  nseed, eax
            invoke  nrandom, 10
            add eax, -6
            mov asteroids[edi].velocity.x, eax
          .endif
          add edi, 24
        .ENDW

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

UpdateThread PROC Param:DWORD
    invoke Sleep, 1000/21
    mov esi, -50

    .if left_down == 1
        .if shipSpritesIndex == 15
            mov shipSpritesIndex, 0
        .else
            inc shipSpritesIndex
        .endif
    .endif
    
    .if right_down == 1
        .if shipSpritesIndex == 0
            mov shipSpritesIndex, 15
        .else
            dec shipSpritesIndex
        .endif
    .endif

    .if up_down == 1
        .if shipSpritesIndex == 0
            dec ship.velocity.y
            dec ship.velocity.y
        .elseif shipSpritesIndex == 1
            dec ship.velocity.y
            dec ship.velocity.y
            dec ship.velocity.x
        .elseif shipSpritesIndex == 2
            dec ship.velocity.y
            dec ship.velocity.y
            dec ship.velocity.x
            dec ship.velocity.x
        .elseif shipSpritesIndex == 3
            dec ship.velocity.y
            dec ship.velocity.x
            dec ship.velocity.x
        .elseif shipSpritesIndex == 4
            dec ship.velocity.x
            dec ship.velocity.x
        .elseif shipSpritesIndex == 5
            inc ship.velocity.y
            dec ship.velocity.x
            dec ship.velocity.x
        .elseif shipSpritesIndex == 6
            inc ship.velocity.y
            inc ship.velocity.y
            dec ship.velocity.x
            dec ship.velocity.x
        .elseif shipSpritesIndex == 7
            inc ship.velocity.y
            inc ship.velocity.y
            dec ship.velocity.x
        .elseif shipSpritesIndex == 8
            inc ship.velocity.y
            inc ship.velocity.y
        .elseif shipSpritesIndex == 9
            inc ship.velocity.y
            inc ship.velocity.y
            inc ship.velocity.x
        .elseif shipSpritesIndex == 10
            inc ship.velocity.y
            inc ship.velocity.y
            inc ship.velocity.x
            inc ship.velocity.x
        .elseif shipSpritesIndex == 11
            inc ship.velocity.y
            inc ship.velocity.x
            inc ship.velocity.x
        .elseif shipSpritesIndex == 12
            inc ship.velocity.x
            inc ship.velocity.x
        .elseif shipSpritesIndex == 13
            dec ship.velocity.y
            inc ship.velocity.x
            inc ship.velocity.x
        .elseif shipSpritesIndex == 14
            dec ship.velocity.y
            dec ship.velocity.y
            inc ship.velocity.x
            inc ship.velocity.x
        .elseif shipSpritesIndex == 15
            dec ship.velocity.y
            dec ship.velocity.y
            inc ship.velocity.x
        .endif
    .endif

    .if down_down == 1
        .if shipSpritesIndex == 0
            inc ship.velocity.y
            inc ship.velocity.y
        .elseif shipSpritesIndex == 1
            inc ship.velocity.y
            inc ship.velocity.y
            inc ship.velocity.x
        .elseif shipSpritesIndex == 2
            inc ship.velocity.y
            inc ship.velocity.y
            inc ship.velocity.x
            inc ship.velocity.x
        .elseif shipSpritesIndex == 3
            inc ship.velocity.y
            inc ship.velocity.x
            inc ship.velocity.x
        .elseif shipSpritesIndex == 4
            inc ship.velocity.x
            inc ship.velocity.x
        .elseif shipSpritesIndex == 5
            dec ship.velocity.y
            inc ship.velocity.x
            inc ship.velocity.x
        .elseif shipSpritesIndex == 6
            dec ship.velocity.y
            dec ship.velocity.y
            inc ship.velocity.x
            inc ship.velocity.x
        .elseif shipSpritesIndex == 7
            dec ship.velocity.y
            dec ship.velocity.y
            inc ship.velocity.x
        .elseif shipSpritesIndex == 8
            dec ship.velocity.y
            dec ship.velocity.y
        .elseif shipSpritesIndex == 9
            dec ship.velocity.y
            dec ship.velocity.y
            dec ship.velocity.x
        .elseif shipSpritesIndex == 10
            dec ship.velocity.y
            dec ship.velocity.y
            dec ship.velocity.x
            dec ship.velocity.x
        .elseif shipSpritesIndex == 11
            dec ship.velocity.y
            dec ship.velocity.x
            dec ship.velocity.x
        .elseif shipSpritesIndex == 12
            dec ship.velocity.x
            dec ship.velocity.x
        .elseif shipSpritesIndex == 13
            inc ship.velocity.y
            dec ship.velocity.x
            dec ship.velocity.x
        .elseif shipSpritesIndex == 14
            inc ship.velocity.y
            inc ship.velocity.y
            dec ship.velocity.x
            dec ship.velocity.x
        .elseif shipSpritesIndex == 15
            inc ship.velocity.y
            inc ship.velocity.y
            dec ship.velocity.x
        .endif
    .endif
  
    .if space_down == 1
        mov edi, 0
        .WHILE shipProjectiles[edi].position.x != -1 ; Find an empty slot in the array
            add edi, 24
        .ENDW
        mov esi, PROJECTILE_VELOCITY

        .if shipSpritesIndex == 0
            mov eax, ship.position.x
            add eax, 17
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 5
            mov shipProjectiles[edi].position.y, eax

            mov eax, -2
            imul eax, PROJECTILE_VELOCITY

            ;invoke wsprintfA, ADDR buffer, ADDR header_format, eax
            ;invoke MessageBox, NULL, ADDR buffer, ADDR szDisplayName, MB_OK
            mov shipProjectiles[edi].velocity.y, eax
            mov shipProjectiles[edi].velocity.x, 0
            ;invoke wsprintfA, ADDR buffer, ADDR header_format, eax
            ;invoke MessageBox, NULL, ADDR buffer, ADDR szDisplayName, MB_OK
        .elseif shipSpritesIndex == 1
            mov eax, ship.position.x
            add eax, 12
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 5
            mov shipProjectiles[edi].position.y, eax
            mov eax, -2
            imul esi

            mov shipProjectiles[edi].velocity.y, eax

            mov eax, -1
            imul esi
            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 2
            mov eax, ship.position.x
            add eax, 9
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 8
            mov shipProjectiles[edi].position.y, eax
            mov eax, -2
            imul esi

            mov shipProjectiles[edi].velocity.y, eax

            mov eax, -2
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 3
            mov eax, ship.position.x
            add eax, 6
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 12
            mov shipProjectiles[edi].position.y, eax
            mov eax, -1
            imul esi
            mov shipProjectiles[edi].velocity.y, eax

            mov eax, -2
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 4
            mov eax, ship.position.x
            ;add eax, 0
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 17
            mov shipProjectiles[edi].position.y, eax
            mov shipProjectiles[edi].velocity.y, 0
            mov eax, -2
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 5
            mov eax, ship.position.x
            add eax, 6
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 23
            mov shipProjectiles[edi].position.y, eax
            mov eax, 1
            imul esi

            mov shipProjectiles[edi].velocity.y, eax

            mov eax, -2
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 6
            mov eax, ship.position.x
            add eax, 9
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 27
            mov shipProjectiles[edi].position.y, eax
            mov eax, 2
            imul esi

            mov shipProjectiles[edi].velocity.y, eax

            mov eax, -2
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 7
            mov eax, ship.position.x
            add eax, 12
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 30
            mov shipProjectiles[edi].position.y, eax
            mov eax, 2
            imul esi

            mov shipProjectiles[edi].velocity.y, eax

            mov eax, -1
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 8
            mov eax, ship.position.x
            add eax, 17
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 30
            mov shipProjectiles[edi].position.y, eax
            mov eax, 2
            imul esi

            mov shipProjectiles[edi].velocity.y, eax
            mov shipProjectiles[edi].velocity.x, 0
        .elseif shipSpritesIndex == 9
            mov eax, ship.position.x
            add eax, 24
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 30
            mov shipProjectiles[edi].position.y, eax
            mov eax, 2
            imul esi

            mov shipProjectiles[edi].velocity.y, eax

            mov eax, 1
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 10
            mov eax, ship.position.x
            add eax, 26
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 27
            mov shipProjectiles[edi].position.y, eax
            mov eax, 2
            imul esi

            mov shipProjectiles[edi].velocity.y, eax

            mov eax, 2
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 11
            mov eax, ship.position.x
            add eax, 29
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 23
            mov shipProjectiles[edi].position.y, eax
            mov eax, 1
            imul esi

            mov shipProjectiles[edi].velocity.y, eax

            mov eax, 2
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 12
            mov eax, ship.position.x
            add eax, 29
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 17
            mov shipProjectiles[edi].position.y, eax
            mov shipProjectiles[edi].velocity.y, 0

            mov eax, 2
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 13
            mov eax, ship.position.x
            add eax, 29
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 12
            mov shipProjectiles[edi].position.y, eax
            mov eax, -1
            imul esi

            mov shipProjectiles[edi].velocity.y, eax

            mov eax, 2
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 14
            mov eax, ship.position.x
            add eax, 26
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 8
            mov shipProjectiles[edi].position.y, eax
            mov eax, -2
            imul esi

            mov shipProjectiles[edi].velocity.y, eax

            mov eax, 2
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .elseif shipSpritesIndex == 15
            mov eax, ship.position.x
            add eax, 24                
            mov shipProjectiles[edi].position.x, eax
            mov eax, ship.position.y
            add eax, 5
            mov shipProjectiles[edi].position.y, eax
            mov eax, -2
            imul esi

            mov shipProjectiles[edi].velocity.y, eax

            mov eax, 1
            imul esi

            mov shipProjectiles[edi].velocity.x, eax
        .endif
    .endif

    mov ecx, ship.velocity.x
    mov eax, -1
    imul shipMaxVelocity.x
    .if SDWORD PTR ecx > shipMaxVelocity.x
        m2m ship.velocity.x, shipMaxVelocity.x
    .elseif SDWORD PTR ecx < SDWORD PTR eax
        m2m ship.velocity.x, eax
    .endif

    mov ecx, ship.velocity.y
    mov eax, -1
    imul shipMaxVelocity.y
    .if SDWORD PTR ecx > shipMaxVelocity.y
        m2m ship.velocity.y, shipMaxVelocity.y
    .elseif SDWORD PTR ecx < SDWORD PTR eax
        m2m ship.velocity.y, eax
    .endif

    mov eax, ship.velocity.x
    add ship.position.x, eax
    mov eax, ship.velocity.y
    add ship.position.y, eax

    mov ebx, ship.position.x
    add ebx, 36
    mov ecx, ship.position.x
    ;add ecx, 36
    .if SDWORD PTR ecx >= SCREEN_WIDTH
        ;mov eax, -1
        ;imul ship.velocity.x

        ;mov ship.velocity.x, eax

        mov ship.position.x, -36
    .elseif SDWORD PTR ebx <= 0
        ;mov eax, -1
        ;imul ship.velocity.x

        ;mov ship.velocity.x, eax
        mov ship.position.x, SCREEN_WIDTH
    .endif

    mov ebx, ship.position.y
    add ebx, 36
    mov ecx, ship.position.y
    ;add ecx, 36
    .if SDWORD PTR ecx >= SCREEN_HEIGHT
        ;mov eax, -1
        ;imul ship.velocity.y

        ;mov ship.velocity.y, eax
        mov ship.position.y, -36
    .elseif SDWORD PTR ebx <= 0
        ;mov eax, -1
        ;imul ship.velocity.y

        ;mov ship.velocity.y, eax
        mov ship.position.y, SCREEN_HEIGHT
    .endif

    mov edi, 0
    .WHILE shipProjectiles[edi].position.x != -1
      mov eax, shipProjectiles[edi].velocity.x
      add shipProjectiles[edi].position.x, eax

      mov eax, shipProjectiles[edi].velocity.y
      add shipProjectiles[edi].position.y, eax

      .if shipProjectiles[edi].position.x > SCREEN_WIDTH+50
          jmp clean_projectile
      .elseif shipProjectiles[edi].position.x < SDWORD PTR esi
          jmp clean_projectile
      .elseif shipProjectiles[edi].position.y > SCREEN_HEIGHT+50
          jmp clean_projectile
      .elseif shipProjectiles[edi].position.y < SDWORD PTR esi
          jmp clean_projectile
      .else 
          jmp end_of_loop
      .endif

    clean_projectile:
        mov shipProjectiles[edi].position.x, -1
        mov shipProjectiles[edi].position.y, -1
        mov shipProjectiles[edi].velocity.x, -1
        mov shipProjectiles[edi].velocity.y, -1
        mov shipProjectiles[edi].acceleration.x, -1
        mov shipProjectiles[edi].acceleration.y, -1

    end_of_loop:
        add edi, 24
    .ENDW

		mov edi, 0
    .WHILE edi < 240
      .if asteroids[edi].position.x != -1
        mov eax, asteroids[edi].velocity.x
        add asteroids[edi].position.x, eax

        mov eax, asteroids[edi].velocity.y
        add asteroids[edi].position.y, eax

        .if asteroids[edi].position.x > SCREEN_WIDTH
          mov asteroids[edi].position.x, 0
        .endif

        .if asteroids[edi].position.x < 0
          mov asteroids[edi].position.x, SCREEN_WIDTH
        .endif
        
        .if asteroids[edi].position.y > SCREEN_HEIGHT
          mov asteroids[edi].position.y, 0
        .endif

        .if asteroids[edi].position.y < 0
          mov asteroids[edi].position.y, SCREEN_HEIGHT
        .endif
      .endif
			add edi, 24
    .ENDW


    invoke InvalidateRect,hWnd,NULL,TRUE
    jmp UpdateThread
    ret
UpdateThread ENDP

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
		
    .elseif uMsg == WM_CREATE
	  	mov posicao.x,200
		mov posicao.y,0
		
		;invoke CreateEvent,NULL,FALSE,FALSE,NULL
		;mov    hEventStart,eax
		
		;mov    eax,OFFSET ThreadProc
		;invoke CreateThread,NULL,NULL,eax,\
		;                    NULL,NORMAL_PRIORITY_CLASS,\
		;                     ADDR ThreadID

		;mov    hThread,eax

        mov    eax, offset UpdateThread
        invoke CreateThread,NULL,NULL, eax,\
		                    NULL,NORMAL_PRIORITY_CLASS,\
		                     ADDR UpdateThreadID


		
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
          invoke Sleep, 10
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
   	;invoke PostMessage,hWnd,WM_FINISH,NULL,NULL
   	;invoke SetEvent,hEventStart

   .elseif uMsg == WM_KEYDOWN
        .if wParam == VK_SPACE
            mov space_down, 1
        .elseif wParam == VK_RIGHT
            mov right_down, 1
        .elseif wParam == VK_LEFT
            mov left_down, 1
        .elseif wParam == VK_UP
            mov up_down, 1
        .elseif wParam == VK_DOWN
            mov down_down, 1
        .endif
   	
    .elseif uMsg == WM_KEYUP
        .if wParam == VK_RIGHT
            mov right_down, 0
        .elseif wParam == VK_LEFT
            mov left_down, 0
        .elseif wParam == VK_SPACE
            mov space_down, 0
        .elseif wParam == VK_UP
            mov up_down, 0
        .elseif wParam == VK_DOWN
            mov down_down, 0
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

    

    ;invoke SelectObject,hDC,hOld
    
    invoke SelectObject,memDC,space_backgroundBmp ; select background
    invoke BitBlt,hDC,0,0,800,600,memDC,0,0,SRCCOPY

    invoke SelectObject,memDC,shipBmp  ; select ship image
    ;mov hOld, eax

    ;invoke wsprintfA, ADDR buffer, ADDR header_format, shipSprites[8].x
    ;invoke MessageBox, NULL, ADDR buffer, ADDR szDisplayName, MB_OK

    mov eax, 36
    mul shipSpritesIndex

    ; paint the ship
    invoke TransparentBlt,hDC, \
    ;paint point
    ship.position.x, ship.position.y, \
    ;ship size
    36,36, \
    memDC, \
    ;current_sprite
    eax, 0, \
    ;ship size
    36,36, \
    ;color to be ignored
    CREF_TRANSPARENT

    mov edi, 0
    .WHILE edi < 240
      .if asteroids[edi].position.x != -1
        .if asteroids[edi].acceleration.x == 1 ;TODO aceleracao.x = size
          invoke SelectObject,memDC,asteroid1Bmp
          mov esi, 40
        .elseif asteroids[edi].acceleration.x == 2
          invoke SelectObject,memDC,asteroid2Bmp
          mov esi, 20
        .else 
          invoke SelectObject,memDC,asteroid3Bmp
          mov esi, 10
        .endif
        invoke TransparentBlt,hDC, \
        ;paint point
        asteroids[edi].position.x, asteroids[edi].position.y, \
        ;asteroid size
        esi, esi, \
        memDC, \
        ;current_sprite
        0, 0, \
        ;asteroid size
        esi, esi, \
        ;color to be ignored
        BLACK_COLOR
      .endif  
			add edi, 24
    .ENDW

    ; TODO percorrer todos os projeteis
    invoke SelectObject,memDC,projectileBmp ; select projectile image
    mov edi, 0
    .WHILE shipProjectiles[edi].position.x != -1
        ; paint the ship
        invoke TransparentBlt,hDC, \
        ;paint point
        shipProjectiles[edi].position.x, shipProjectiles[edi].position.y, \
        ;proj size
        5,5, \
        memDC, \
        ;current_sprite
        0, 0, \
        ;proj size
        5,5, \
        ;color to be ignored
        BLACK_COLOR

        add edi, 24
    .ENDW

    invoke SelectObject,memDC,asteroid1Bmp
    ;invoke BitBlt, hDC, 0, 0, 10, 10, memDC, 0, 0, SRCCOPY
    ;invoke TransparentBlt, hDC, 0, 0, 50, 50, memDC, 0, 0, 50, 50, CREF_TRANSPARENT
    
    ;invoke SelectObject,memDC,hBmp2  ; selecionei o novo bitmap
    ;mov hOld, eax
          
    ;invoke BitBlt,hDC,50,250,32,32,memDC,0,0,SRCCOPY
    ;invoke BitBlt,hDC,90,250,32,32,memDC,0,416,SRCCOPY
    ;invoke BitBlt,hDC,140,250,32,32,memDC,0,416,SRCCOPY
    
    ;INVOKE  TransparentBlt,hDC,190,250,32,32,memDC,0,256,32,32,CREF_TRANSPARENT
    
    ;INVOKE  TransparentBlt,hDC,240,250,32,32,memDC,0,512,32,32,CREF_TRANSPARENT

    invoke SetTextColor, memDC, WHITE_COLOR
    invoke SetBkColor, memDC, BLACK_COLOR
    invoke SelectObject, memDC, hFont

    invoke wsprintfA, ADDR buffer, ADDR header_format, shipProjectiles[0].position.x, shipProjectiles[0].position.y
    
    invoke ExtTextOutA, hDC,100, 100, ETO_CLIPPED, NULL, ADDR buffer, eax, NULL
    ;invoke TextOutA, hDC, 100, 100, ADDR buffer, eax

    invoke DeleteDC,memDC
    return 0

Paint_Proc endp

; ########################################################################

end start
