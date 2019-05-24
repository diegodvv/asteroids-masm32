; #########################################################################

.386
.model flat, stdcall  ; 32 bit memory model
option casemap :none  ; case sensitive

include Asteroids.inc    ; local includes for this file

ASTEROID STRUCT
    position POINT <>
    velocity POINT <>
    tam dd 0
ASTEROID ENDS

BODY STRUCT
    position POINT <>
    velocity POINT <>
    acceleration POINT <>
BODY ENDS

EXPLOSION STRUCT
    position POINT <>
    frame db -1
EXPLOSION ENDS

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
explosionBmpId equ 106

BLACK_COLOR equ 0000000h
WHITE_COLOR equ 0ffffffh

ASTEROIDS_INIT equ 20
ASTEROIDS_MAX equ ASTEROIDS_INIT * 3
EXPLOSIONS_MAX equ 15
EXPLOSION_FRAME_SIZE equ 26


PROJECTILE_VELOCITY equ 10
ASTEROID_MAX_VELOCITY equ 10
SHOOT_COOLDOWN equ 10
RESPAWN_COOLDOWN equ 30

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

  player_lives db 5
  randomnum  db  2 dup (?)

  ;shipSprites   POINT {0, 0}, {36, 0}, {72, 0}, {108, 0}
  shipSpritesIndex  dd 2
  ship BODY {{10, 10}, {0, 0}, {0, 0}}
  shipMaxVelocity POINT {10, 10}
  shipProjectiles BODY 30 dup ({{-1, 2}, {3, 4}, {-1, -1}})
  asteroids ASTEROID ASTEROIDS_MAX dup ({{-1, -1}, {1, 1}, 1})
  explosions EXPLOSION EXPLOSIONS_MAX dup ({{0, 0}, -1})
  UpdateThreadID dd 0
  left_down db 0
  right_down db 0
  space_down db 0
  up_down db 0
  down_down db 0
  ship_destroyed db 0
  
  respawn_counter dd 0
  last_shoot_counter dd 0
  shipBmp         dd ?
  space_backgroundBmp dd ?
  asteroid1Bmp dd ?
  asteroid2Bmp dd ?
  asteroid3Bmp dd ?
  projectileBmp dd ?
  explosionBmp dd ?

	ExitCode dd 0
	hThread dd 0
	hEventStart dd 0

  index dd 0
  points dd 0

  AppName  db "Our First Window",0
  MenuName db "FirstMenu",0
  Test_string db "You selected Test menu item",0
  error_string db "Error loading image",0
  strEqualNegativeOne db "Not equal to negative one",0
  buffer db 300 dup(?)
  header_format db "Number of asteroids: %d",0
  header_format_ship_destroyed db "BATEU",0
  header_format_explosion_frame db "explosions[0].frame: %d",0
  format_number_of_lives db "Lives: %d",0
  format_pointer db "Points: %d",0

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

      invoke LoadBitmap, hInstance, explosionBmpId
      mov explosionBmp, eax

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
        .WHILE edi < sizeof ASTEROID * ASTEROIDS_MAX
            invoke Sleep, 10
            invoke  GetTickCount
            invoke  nseed, eax
            invoke  nrandom, SCREEN_WIDTH
            mov asteroids[edi].position.x, eax

            invoke Sleep, 10
            invoke  GetTickCount
            invoke  nseed, eax
            invoke  nrandom, SCREEN_HEIGHT
            mov asteroids[edi].position.y, eax

            .IF edi < ASTEROIDS_INIT * sizeof ASTEROID
                invoke Sleep, 10
                invoke  GetTickCount
                invoke  nseed, eax
                invoke  nrandom, 3
                add eax, 1
                mov asteroids[edi].tam, eax
            .ELSE
                mov asteroids[edi].tam, 0
            .ENDIF

            invoke Sleep, 10   
            xor eax, eax
            invoke  GetTickCount
            invoke  nseed, eax
            invoke  nrandom, ASTEROID_MAX_VELOCITY
            add eax, -5
            mov asteroids[edi].velocity.x, eax

            invoke Sleep, 10   
            xor eax, eax
            invoke  GetTickCount
            invoke  nseed, eax
            invoke  nrandom, ASTEROID_MAX_VELOCITY
            add eax, -5
            mov asteroids[edi].velocity.y, eax

            add edi, sizeof ASTEROID
        .ENDW

        mov ship.position.x, 400 - 18
        mov ship.position.y, 300 - 18
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

; // MARK : UpdateThread
UpdateThread PROC Param:DWORD
    invoke Sleep, 1000/24
    mov esi, -50

    .IF last_shoot_counter < SHOOT_COOLDOWN
        inc last_shoot_counter
    .ENDIF

    .IF ship_destroyed
        .IF respawn_counter < RESPAWN_COOLDOWN
            inc respawn_counter
        .ELSE
            mov respawn_counter, 0
            mov ship.position.x, (SCREEN_WIDTH/2) - 18
            mov ship.position.y, (SCREEN_HEIGHT/2) - 18
            mov ship.velocity.x, 0
            mov ship.velocity.y, 0
            mov ship_destroyed, 0
        .ENDIF
    .ENDIF

    ; // TODO: Spawn random asteroids --- check
    ; // TODO: If lives gets to 0, gameover screen
    ; // TODO: add point score counter --- check
    ; // TODO: splash screen
    ; // TODO: ship explosion whe collision happens
    ; // TODO: fix collision with non existing objects --- check
    ; // TODO: fix shooting even when is dead --- check
    ; // TODO: set rotation to up when spawning and respawning --- check
    ; // TODO: be immortal for a few seconds when respawning
    ; // TODO: fix shot freeze in the air --- check
    ; // TODO: Make newer asteroids when wave ends
    ; // TODO: Prevent rotating when dead

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
        .IF last_shoot_counter == SHOOT_COOLDOWN && !ship_destroyed
            mov last_shoot_counter, 0
            
            begin_thing:
            mov edi, 0
            .WHILE shipProjectiles[edi].acceleration.x != -1 ; Find an empty slot in the array
                .IF edi == 24 * 30
                    jmp begin_thing
                .ENDIF
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

            mov shipProjectiles[edi].acceleration.x, 1
        .ENDIF
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
    .WHILE edi < ASTEROIDS_MAX * sizeof ASTEROID
        .IF asteroids[edi].tam > 0 && asteroids[edi].tam < 4
            mov eax, asteroids[edi].velocity.x
            add asteroids[edi].position.x, eax

            mov eax, asteroids[edi].velocity.y
            add asteroids[edi].position.y, eax

            mov ebx, asteroids[edi].position.x
            .if SDWORD PTR ebx > 800
            mov asteroids[edi].position.x, -10
            .elseif SDWORD PTR ebx <= -30
            mov asteroids[edi].position.x, 800
            .endif
            
            mov ebx, asteroids[edi].position.y
            .if SDWORD PTR ebx > 600
            mov asteroids[edi].position.y, -30
            .elseif SDWORD PTR ebx <= -40
            mov asteroids[edi].position.y, 600
            .endif

            .if asteroids[edi].tam == 1
                mov esi, 40
            .elseif asteroids[edi].tam == 2
                mov esi, 20
            .elseif asteroids[edi].tam == 3
                mov esi, 10
            .endif
            
            ; collision ship asteroids
            .IF !ship_destroyed
                mov ebx, asteroids[edi].position.x
                add ebx, esi
                add ebx, -4
                mov eax, ship.position.x
                .IF SDWORD PTR ebx > SDWORD PTR eax
                    mov ebx, asteroids[edi].position.x
                    mov eax, ship.position.x
                    add eax, 32
                    .IF SDWORD PTR ebx < SDWORD PTR eax
                        mov ebx, asteroids[edi].position.y
                        add ebx, esi
                        add ebx, -4
                        mov eax, ship.position.y
                        .IF SDWORD PTR ebx > SDWORD PTR eax
                            mov ebx, asteroids[edi].position.y
                            mov eax, ship.position.y
                            add eax, 32
                            .IF SDWORD PTR ebx < SDWORD PTR eax
                                mov ship_destroyed, 1
                                mov shipSpritesIndex, 0
                                dec player_lives

                                ; add explosion
                                mov esi, 0
                                .WHILE explosions[esi].frame < 39 && explosions[esi].frame != -1
                                    add esi, sizeof EXPLOSION
                                .ENDW

                                mov eax, ship.position.x
                                add eax, 36/2 - EXPLOSION_FRAME_SIZE/2
                                mov explosions[esi].position.x, eax ; 
                                mov eax, ship.position.y
                                add eax, 36/2 - EXPLOSION_FRAME_SIZE/2
                                mov explosions[esi].position.y, eax
                                mov explosions[esi].frame, 0
                            .ENDIF
                        .ENDIF
                    .ENDIF
                .ENDIF
            .ENDIF
            
        .ENDIF
        add edi, sizeof ASTEROID
    .ENDW
    ; Bx + Bw > Ax &&
    ; Bx < Ax + Aw &&
    ; By + Bh > Ay && 
    ; By < Ay + Ah

    mov edi, 0
    .WHILE edi < 24 * 30
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

    ; Collision of asteroids with projectiles
    mov edi, 0        
    .WHILE edi < ASTEROIDS_MAX * sizeof ASTEROID
        .IF asteroids[edi].tam > 0 && asteroids[edi].tam < 4

            .if asteroids[edi].tam == 1
                mov esi, 40
            .elseif asteroids[edi].tam == 2
                mov esi, 20
            .elseif asteroids[edi].tam == 3
                mov esi, 10
            .endif
            
            mov ecx, 0
            .WHILE ecx != sizeof BODY * 30
                mov ebx, asteroids[edi].position.x
                add ebx, esi
                add ebx, -4
                ; check collision only if projectile is alive
                .IF shipProjectiles[ecx].acceleration.x != -1
                    mov eax, shipProjectiles[ecx].position.x
                    .IF SDWORD PTR ebx > SDWORD PTR eax
                        mov ebx, asteroids[edi].position.x
                        mov eax, shipProjectiles[ecx].position.x
                        add eax, 32
                        .IF SDWORD PTR ebx < SDWORD PTR eax
                            mov ebx, asteroids[edi].position.y
                            add ebx, esi
                            add ebx, -4
                            mov eax, shipProjectiles[ecx].position.y
                            .IF SDWORD PTR ebx > SDWORD PTR eax
                                mov ebx, asteroids[edi].position.y
                                mov eax, shipProjectiles[ecx].position.y
                                add eax, 32
                                .IF SDWORD PTR ebx < SDWORD PTR eax
                                    mov eax, asteroids[edi].tam
                                    add points, eax
                                    add points, eax
                                    add points, eax
                                    add points, eax
                                    add points, eax
                                    add points, eax
                                    add points, eax
                                    add points, eax
                                    add points, eax
                                    add points, eax
                                    ; we ran out of registers, so this is 10 times the size of the asteroid

                                    inc asteroids[edi].tam

                                    ; add explosion
                                    mov esi, 0
                                    .WHILE explosions[esi].frame < 39 && explosions[esi].frame != -1
                                        add esi, sizeof EXPLOSION
                                    .ENDW

                                    m2m explosions[esi].position.x, asteroids[edi].position.x
                                    m2m explosions[esi].position.y, asteroids[edi].position.y
                                    mov explosions[esi].frame, 0

                                    mov shipProjectiles[ecx].position.x, -1
                                    mov shipProjectiles[ecx].position.y, -1
                                    mov shipProjectiles[ecx].velocity.x, -1
                                    mov shipProjectiles[ecx].velocity.y, -1
                                    mov shipProjectiles[ecx].acceleration.x, -1
                                    mov shipProjectiles[ecx].acceleration.y, -1

                                    mov esi, 0
                                    .WHILE asteroids[esi].tam > 0 && asteroids[esi].tam < 4
                                        .IF esi == ASTEROIDS_MAX * sizeof ASTEROID
                                            jmp end_of_asteroids_projectiles_collision_loop
                                        .ENDIF
                                        add esi, sizeof ASTEROID
                                    .ENDW

                                    invoke Sleep, 5
                                    invoke  GetTickCount
                                    invoke  nseed, eax
                                    invoke  nrandom, ASTEROID_MAX_VELOCITY
                                    sub eax, 5
                                    mov asteroids[edi].velocity.x, eax

                                    invoke Sleep, 5
                                    invoke  GetTickCount
                                    invoke  nseed, eax
                                    invoke  nrandom, ASTEROID_MAX_VELOCITY
                                    sub eax, 5
                                    mov asteroids[edi].velocity.y, eax
                                
                                    invoke Sleep, 5
                                    invoke  GetTickCount
                                    invoke  nseed, eax
                                    invoke  nrandom, ASTEROID_MAX_VELOCITY
                                    sub eax, 5
                                    mov asteroids[esi].velocity.x, eax

                                    invoke Sleep, 5
                                    invoke  GetTickCount
                                    invoke  nseed, eax
                                    ;invoke  nrandom, ASTEROID_MAX_VELOCITY ; for some reason this random doesnt work but its effect is unnoticeble
                                    sub eax, 5
                                    mov asteroids[esi].velocity.y, 1

                                    mov eax, 0

                                    mov ebx, asteroids[edi].position.x
                                    mov asteroids[esi].position.x, ebx

                                    mov ebx, asteroids[edi].position.y
                                    mov asteroids[esi].position.y, ebx  
                                    
                                    m2m asteroids[esi].tam, asteroids[edi].tam
                                    
                                    jmp end_of_asteroids_projectiles_collision_loop2                           
                                .ENDIF
                            .ENDIF
                        .ENDIF
                    .ENDIF
                .ENDIF
                end_of_asteroids_projectiles_collision_loop2:
                add ecx, sizeof BODY
            .ENDW
        .ENDIF
        end_of_asteroids_projectiles_collision_loop:
        add edi, sizeof ASTEROID
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
    
    .elseif uMsg == WM_LBUTTONDOWN

    .elseif uMsg == WM_PAINT
        invoke BeginPaint,hWin,ADDR Ps
          mov hDC, eax
          invoke Paint_Proc,hWin,hDC
          invoke Sleep, 10
        invoke EndPaint,hWin,ADDR Ps
        return 0

    .elseif uMsg == WM_CLOSE
    
    .elseif uMsg == WM_CHAR

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
; // MARK: Paint_Proc
Paint_Proc proc hWin:DWORD, hDC:DWORD

    LOCAL hOld:DWORD
    LOCAL memDC :DWORD
 
    
    invoke CreateCompatibleDC,hDC
    mov memDC, eax
    
    ;invoke SelectObject,memDC,hBmp
    ;mov hOld, eax

    ;invoke SelectObject,hDC,hOld
    
    invoke SelectObject,memDC,space_backgroundBmp ; select background
    invoke BitBlt,hDC,0,0,800,600,memDC,0,0,SRCCOPY

    invoke SelectObject,memDC,shipBmp  ; select ship image
    ;mov hOld, eax

    ;invoke wsprintfA, ADDR buffer, ADDR header_format, shipSprites[8].x
    ;invoke MessageBox, NULL, ADDR buffer, ADDR szDisplayName, MB_OK

    mov eax, 36
    mul shipSpritesIndex

    ; paint the ship if it's not destroyed
    .IF !ship_destroyed
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
    .ENDIF

    mov edi, 0
    .WHILE edi < ASTEROIDS_MAX * sizeof ASTEROID
        .IF asteroids[edi].tam > 0
            .IF asteroids[edi].tam < 4
                .if asteroids[edi].tam == 1
                    invoke SelectObject,memDC,asteroid1Bmp
                    mov esi, 40
                .elseif asteroids[edi].tam == 3
                    invoke SelectObject,memDC,asteroid3Bmp
                    mov esi, 10
                .elseif asteroids[edi].tam == 2
                    invoke SelectObject,memDC,asteroid2Bmp
                    mov esi, 20
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
            .ENDIF
        .ENDIF
        add edi, sizeof ASTEROID
    .ENDW

    invoke SelectObject,memDC,projectileBmp ; select projectile image
    mov edi, 0
    .WHILE edi < 30 * sizeof BODY
        .IF shipProjectiles[edi].acceleration.x != -1
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
        .ENDIF
        add edi, sizeof BODY
    .ENDW

    ; explosions
    invoke SelectObject, memDC, explosionBmp

    mov esi, 0
    .WHILE esi < EXPLOSIONS_MAX * sizeof EXPLOSION
        .IF explosions[esi].frame < 39
            ; paint the explosion
            mov eax, EXPLOSION_FRAME_SIZE
            mul explosions[esi].frame


            invoke TransparentBlt,hDC, \
            ;paint point
            explosions[esi].position.x, explosions[esi].position.y, \
            ;explosion size
            EXPLOSION_FRAME_SIZE,EXPLOSION_FRAME_SIZE, \
            memDC, \
            ;current_sprite
            eax, 0, \
            ;explosion size
            EXPLOSION_FRAME_SIZE,EXPLOSION_FRAME_SIZE, \
            ;color to be ignored
            CREF_TRANSPARENT

            ;mov eax, offset explosions
            ;add eax, edi
            ;add eax, 8
            ;add byte ptr [eax], 1
            mov al, explosions[esi].frame
            inc al
            mov explosions[esi].frame, al
        .ENDIF

        add esi, sizeof EXPLOSION
    .ENDW
    
    invoke wsprintfA, ADDR buffer, ADDR format_number_of_lives, player_lives
    invoke ExtTextOutA, hDC,0, 0, ETO_CLIPPED, NULL, ADDR buffer, eax, NULL

    invoke wsprintfA, ADDR buffer, ADDR format_pointer, points
    invoke ExtTextOutA, hDC,0, 17, ETO_CLIPPED, NULL, ADDR buffer, eax, NULL

    ; debug
    invoke SetTextColor, memDC, WHITE_COLOR
    invoke SetBkColor, memDC, BLACK_COLOR
    invoke SelectObject, memDC, hFont

    mov eax, 0
    mov esi, 0
    .WHILE esi < sizeof ASTEROID * ASTEROIDS_MAX
        .IF asteroids[esi].tam < 4
            .IF asteroids[esi].tam > 0
                inc eax
            .ENDIF
        .ENDIF
        add esi, sizeof ASTEROID
    .ENDW

    invoke wsprintfA, ADDR buffer, ADDR header_format, eax
    invoke ExtTextOutA, hDC,100, 100, ETO_CLIPPED, NULL, ADDR buffer, eax, NULL

    invoke wsprintfA, ADDR buffer, ADDR header_format_explosion_frame, explosions[0].frame
    invoke ExtTextOutA, hDC,100, 150, ETO_CLIPPED, NULL, ADDR buffer, eax, NULL

    ;.IF !ship_destroyed
    ;    mov esi, ship.position.x
    ;    neg esi
    ;    add esi, SCREEN_WIDTH - 36

    ;    mov edi, ship.position.y
    ;    neg edi
    ;    add edi, SCREEN_WIDTH - 36
    ;    invoke wsprintfA, ADDR buffer, ADDR header_format, ship.position.x, esi, ship.position.y, edi
    ;    invoke ExtTextOutA, hDC,100, 100, ETO_CLIPPED, NULL, ADDR buffer, eax, NULL
    ;    ;invoke TextOutA, hDC, 100, 100, ADDR buffer, eax
    ;.ELSE
    ;    invoke wsprintfA, ADDR buffer, ADDR header_format_ship_destroyed
    ;    invoke ExtTextOutA, hDC,100, 100, ETO_CLIPPED, NULL, ADDR buffer, eax, NULL
    ;.ENDIF

    invoke DeleteDC,memDC
    return 0

Paint_Proc endp

; ########################################################################

end start
