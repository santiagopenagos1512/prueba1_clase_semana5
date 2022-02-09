
PROCESSOR 16F887
    
    
; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_CLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>

  
RESET_TMR0  MACRO TMR_VAR
    BANKSEL TMR0	; Cambiamos de banco
    MOVLW   TMR_VAR		; Previamente calculado con una simple ecuacion
    MOVWF   TMR0	; 50ms de retardo
    BCF	    T0IF	; Limpieza bandera de interrupcion
    ENDM

PSECT udata_shr		; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1

PSECT resVect, class=CODE, abs, delta=2
ORG 00h	    ; posicion 000h para el reset
; ----------- VECTOR RESET ------------
resVect:
    PAGESEL MAIN    ; Cambio de pagina
    GOTO    MAIN
    
PSECT intVect, class=CODE, abs, delta=2
ORG 04h
PUSH:
    MOVWF   W_TEMP	;Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	;Guardamos STATUS
ISR:
    ;BTFSC   T0IF
    ;CALL    INT_TMR0
    RESET_TMR0 61
    INCF    PORTD
    
    ;BTFSC   RBIF
    ;CALL    INT_PORTB
POP:
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F	;
    SWAPF   W_TEMP, W	;
    
    
PSECT code, delta=2, abs
ORG 100h    ; posicion 100h para el codigo
; --------- CONFIGURACION -------------
MAIN:
    CALL CONFIG_IO
    CALL CONFIG_RELOJ
    CALL CONFIG_TMR0
    CALL CONFIG_INT
    BANKSEL PORTD
    
LOOP:
    ;BTFSS T0IF		; Verificar interrupcion de TMR0
    GOTO  LOOP
    
    ;---- Se programa lo que el uC haga luego del retardo
    /*CALL RESET_TMR0
    INCF PORTD
    GOTO LOOP*/
    ;... RESTO DE INSTRUCCIONES
    

;-------------SUBRUTINAS--------------
CONFIG_RELOJ:
    BANKSEL OSCCON	; cambiamos a banco 1
    BSF OSCCON, 0	; SCS -> 1, usamos reloj interno
    BSF OSCCON, 6
    BSF OSCCON, 5	
    BSF OSCCON, 4	; IRCF<2:0> 110 son de 4Mhz
    return 

CONFIG_TMR0:
    BANKSEL OPTION_REG	; cambiamos de banco
    BCF T0CS		; TMR0 como temporarizador
    BCF PSA		; prescalar a TMR0
    BSF PS2		 
    BSF PS1
    BSF PS0		; PS<2:0> -> 111 prescaler 1 : 256
    
    BANKSEL TMR0	; Cambiamos de banco
    MOVLW   61		; Previamente calculado con una simple ecuacion
    MOVWF   TMR0	; 50ms de retardo
    BCF	    T0IF	; Limpieza bandera de interrupcion
    return

/*RESET_TMR0:
    BANKSEL TMR0	; Cambiamos de banco
    MOVLW   61		; Previamente calculado con una simple ecuacion
    MOVWF   TMR0	; 50ms de retardo
    BCF	    T0IF	; Limpieza bandera de interrupcion
    return*/

CONFIG_IO:
    BANKSEL ANSEL 
    CLRF    ANSEL
    CLRF    ANSELH	; Se definen I/O como digitales
    BANKSEL TRISD	; ENTRADA O SALIDA
    CLRF    TRISD	; Como salida (PORTD)
    BANKSEL PORTD
    CLRF    PORTD	; Apagar PORTD
    return

CONFIG_INT:
    BANKSEL INTCON
    BSF	    GIE		; Habilitamos interrupciones
    BSF	    T0IE	; Habilitamos interrupcion TMR0 
    BCF	    T0IF	; Buena practica siempre limpiarla
    return
    


