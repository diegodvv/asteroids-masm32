; #########################################################################

;     include files
;     ~~~~~~~~~~~~~
      include \MASM32\INCLUDE\windows.inc
      include \MASM32\INCLUDE\masm32.inc
      include \MASM32\INCLUDE\gdi32.inc
      include \MASM32\INCLUDE\user32.inc
      include \MASM32\INCLUDE\kernel32.inc
      include \MASM32\INCLUDE\Comctl32.inc
      include \MASM32\INCLUDE\comdlg32.inc
      include \MASM32\INCLUDE\shell32.inc

      INCLUDE    \Masm32\Include\msimg32.inc
      INCLUDE    \Masm32\Include\oleaut32.inc
      INCLUDE    \Masm32\Macros\macros.asm



;     libraries
;     ~~~~~~~~~
      includelib \MASM32\LIB\masm32.lib

      includelib \MASM32\LIB\gdi32.lib
      includelib \MASM32\LIB\user32.lib
      includelib \MASM32\LIB\kernel32.lib
      includelib \MASM32\LIB\Comctl32.lib
      includelib \MASM32\LIB\comdlg32.lib
      includelib \MASM32\LIB\shell32.lib

      INCLUDELIB \Masm32\Lib\msimg32.lib
      INCLUDELIB \Masm32\Lib\oleaut32.lib
      INCLUDELIB \Masm32\Lib\msvcrt.lib
      INCLUDELIB \Masm32\Lib\masm32.lib

; #########################################################################

      ;=================
      ; Local prototypes
      ;=================
      WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
      WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
      TopXY PROTO   :DWORD,:DWORD
      FillBuffer   PROTO :DWORD,:DWORD,:BYTE
      Paint_Proc   PROTO :DWORD,:DWORD

      
      wsprintf equ PROTO C :DWORD,:VARARG

      ;=============
      ; Local macros
      ;=============

      szText MACRO Name, Text:VARARG
        LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
        ENDM

      m2m MACRO M1, M2
        push M2
        pop  M1
      ENDM

      return MACRO arg
        mov eax, arg
        ret
      ENDM
; ########################### Inserted modules ############################


; #########################################################################
