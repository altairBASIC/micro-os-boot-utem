; =============================================================================
; stage2.asm - Etapa 2 del bootloader (contenido institucional)
; Evaluacion Integradora 1 - INFB6074 - Infraestructura para C. de Datos
; Universidad Tecnologica Metropolitana (UTEM)
; Ingenieria Civil en Ciencia de Datos
; Autores: Ignacio Ramirez, Cristian Vergara y Francisco Provoste
;
; PROPOSITO DE ESTA ETAPA:
; La etapa 1 (boot sector) ya cargo este codigo en memoria (0x0000:0x7E00)
; y salto aqui. Liberada de la restriccion de 512 bytes, esta etapa dibuja
; la pantalla institucional completa escribiendo DIRECTAMENTE al framebuffer
; de texto VGA en la direccion fisica 0xB8000.
;
; FRAMEBUFFER DE TEXTO VGA:
; Modo texto 80x25. Cada celda son 2 bytes: [caracter CP437][atributo color]
; (nibble alto = fondo, bajo = texto). Escribir aqui es como un SO real
; gestiona la consola: sin llamar al BIOS, tratando el video como un arreglo.
;
; EMBLEMA INSTITUCIONAL:
; Se dibuja el ESCUDO de la UTEM en arte ASCII (bloque solido CP437 0xDB).
; El escudo se renderiza completo en azul institucional; el cuadro verde
; caracteristico se superpone encima como cadenas verdes cortas.
; A la derecha del escudo se imprime el texto "UTEM" y debajo la
; identificacion academica y las lineas explicativas.
; =============================================================================

BITS 16
ORG  0x7E00             ; Direccion donde la etapa 1 cargo este codigo

stage2_start:
    mov ax, 0xB800
    mov es, ax          ; ES -> framebuffer de texto VGA (0xB8000)

    ; Limpiar 2000 celdas (80*25) con espacio gris sobre negro
    xor di, di
    mov cx, 2000
    mov ax, 0x0720      ; AH=0x07 atributo, AL=0x20 espacio
    rep stosw

    ; Recorrer la tabla de descriptores e imprimir cada cadena
    mov si, tabla
.fila:
    mov al, [si]            ; AL = fila
    cmp al, 0xFF            ; ¿Centinela de fin de tabla?
    je  halt_loop
    mov ah, 0
    mov cx, 80
    mul cx                  ; AX = fila * 80
    mov bl, [si+1]          ; BL = columna
    mov bh, 0
    add ax, bx              ; AX = fila*80 + columna
    shl ax, 1               ; *2 (2 bytes por celda)
    mov di, ax              ; DI = offset destino en framebuffer
    mov dl, [si+2]          ; DL = atributo de color
    mov bx, [si+3]          ; BX = puntero a la cadena
.car:
    mov al, [bx]            ; Caracter actual
    cmp al, 0               ; ¿Fin de cadena?
    je  .siguiente
    mov ah, dl              ; AH = atributo de color
    mov [es:di], ax         ; Escribir [caracter|color] en celda
    inc bx
    add di, 2
    jmp .car
.siguiente:
    add si, 5               ; Avanzar al siguiente descriptor (5 bytes)
    jmp .fila

    ; Halt: un SO real cargaria aqui un kernel; este programa solo detiene
    ; la CPU porque su proposito es didactico.
halt_loop:
    cli
    hlt
    jmp halt_loop

; =============================================================================
; TABLA DE DESCRIPTORES: db fila, columna, color + dw puntero
; Colores: 0x0A verde, 0x09 azul, 0x0F blanco, 0x0B cian, 0x0E amarillo,
;          0x07 gris.  Centinela de fin = fila 0xFF.
; =============================================================================
COL_ESC equ 6              ; Columna donde inicia el escudo

tabla:
    ; --- Escudo UTEM en azul (14 filas, filas 0..13) ---
    db 0, COL_ESC, 0x09
    dw sh00
    db 1, COL_ESC, 0x09
    dw sh01
    db 2, COL_ESC, 0x09
    dw sh02
    db 3, COL_ESC, 0x09
    dw sh03
    db 4, COL_ESC, 0x09
    dw sh04
    db 5, COL_ESC, 0x09
    dw sh05
    db 6, COL_ESC, 0x09
    dw sh06
    db 7, COL_ESC, 0x09
    dw sh07
    db 8, COL_ESC, 0x09
    dw sh08
    db 9, COL_ESC, 0x09
    dw sh09
    db 10, COL_ESC, 0x09
    dw sh10
    db 11, COL_ESC, 0x09
    dw sh11
    db 12, COL_ESC, 0x09
    dw sh12
    db 13, COL_ESC, 0x09
    dw sh13
    ; --- Cuadro verde superpuesto (filas 2..5, col = COL_ESC+13) ---
    db 2, COL_ESC+13, 0x0A
    dw grn3
    db 3, COL_ESC+13, 0x0A
    dw grn3
    db 4, COL_ESC+13, 0x0A
    dw grn1
    db 5, COL_ESC+13, 0x0A
    dw grn3
    ; --- Texto "UTEM" grande a la derecha del escudo ---
    db 3, 34, 0x0F
    dw u1
    db 4, 34, 0x0F
    dw u2
    db 5, 34, 0x0F
    dw u3
    db 6, 34, 0x0F
    dw u4
    db 7, 34, 0x0F
    dw u5
    ; --- Identificacion academica ---
    db 15, 8, 0x0F
    dw l_univ
    db 16, 8, 0x0B
    dw l_curso
    db 17, 8, 0x0E
    dw l_carrera
    db 18, 8, 0x0F
    dw l_grupo
    db 19, 8, 0x09
    dw l_sep
    ; --- Lineas explicativas (el enunciado pide al menos 3; ponemos 4) ---
    db 20, 8, 0x07
    dw e1
    db 21, 8, 0x07
    dw e2
    db 22, 8, 0x07
    dw e3
    db 23, 8, 0x07
    dw e4
    db 0xFF                 ; Centinela de fin de tabla

; =============================================================================
; DATOS: Escudo UTEM en azul. Bloque solido CP437 = 0xDB.
; Rejilla de 20 columnas de ancho generada para alineacion exacta.
; =============================================================================
sh00 db ' ',' ',0xDB,0xDB,0xDB,0xDB,0xDB,0xDB,0xDB,0xDB,0xDB,0xDB,0xDB,0xDB,0xDB,0xDB,' ',' ',' ',' ',0
sh01 db ' ',0xDB,0xDB,' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',0xDB,0xDB,' ',' ',' ',0
sh02 db ' ',0xDB,' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,' ',' ',0xDB,0xDB,0xDB,' ',0xDB,' ',' ',0
sh03 db ' ',0xDB,' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,' ',' ',0xDB,0xDB,0xDB,' ',0xDB,' ',' ',0
sh04 db ' ',0xDB,' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,' ',' ',0xDB,0xDB,0xDB,' ',0xDB,' ',' ',0
sh05 db ' ',0xDB,' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,' ',' ',0xDB,0xDB,0xDB,' ',0xDB,' ',' ',0
sh06 db ' ',0xDB,' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,' ',' ',' ',' ',' ',' ',0xDB,' ',' ',0
sh07 db ' ',0xDB,' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,' ',' ',' ',0xDB,0xDB,' ',0xDB,' ',' ',0
sh08 db ' ',0xDB,' ',' ',' ',0xDB,0xDB,' ',' ',0xDB,0xDB,' ',' ',' ',0xDB,0xDB,' ',0xDB,' ',' ',0
sh09 db ' ',0xDB,' ',' ',' ',' ',0xDB,0xDB,0xDB,0xDB,' ',' ',' ',' ',' ',' ',' ',0xDB,' ',' ',0
sh10 db ' ',' ',0xDB,' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',0xDB,' ',' ',' ',' ',0
sh11 db ' ',' ',' ',0xDB,0xDB,' ',' ',' ',' ',' ',' ',' ',' ',0xDB,0xDB,' ',' ',' ',' ',' ',0
sh12 db ' ',' ',' ',' ',' ',0xDB,0xDB,' ',' ',' ',' ',0xDB,0xDB,' ',' ',' ',' ',' ',' ',' ',0
sh13 db ' ',' ',' ',' ',' ',' ',' ',0xDB,0xDB,0xDB,0xDB,' ',' ',' ',' ',' ',' ',' ',' ',' ',0

; --- Segmentos verdes para superponer el cuadro institucional ---
grn3 db 0xDB,0xDB,0xDB,0          ; bloque verde de 3 celdas
grn1 db 0xDB,' ',0xDB,0           ; fila central: hueco azul al medio

; =============================================================================
; DATOS: Texto "UTEM" grande (rejilla 5x5 por letra)
; =============================================================================
u1 db 0xDB,' ',' ',' ',0xDB,' ',0xDB,0xDB,0xDB,0xDB,0xDB,' ',0xDB,0xDB,0xDB,0xDB,0xDB,' ',0xDB,0xDB,' ',' ',0xDB,0xDB,0
u2 db 0xDB,' ',' ',' ',0xDB,' ',' ',' ',0xDB,' ',' ',' ',0xDB,' ',' ',' ',' ',' ',0xDB,' ',0xDB,' ',0xDB,0
u3 db 0xDB,' ',' ',' ',0xDB,' ',' ',' ',0xDB,' ',' ',' ',0xDB,0xDB,0xDB,' ',' ',' ',0xDB,' ',' ',' ',0xDB,0
u4 db 0xDB,' ',' ',' ',0xDB,' ',' ',' ',0xDB,' ',' ',' ',0xDB,' ',' ',' ',' ',' ',0xDB,' ',' ',' ',0xDB,0
u5 db ' ',0xDB,0xDB,0xDB,' ',' ',' ',' ',0xDB,' ',' ',' ',0xDB,0xDB,0xDB,0xDB,0xDB,' ',0xDB,' ',' ',' ',0xDB,0

; =============================================================================
; DATOS: Lineas institucionales y explicativas
; =============================================================================
l_univ    db "Universidad Tecnologica Metropolitana - UTEM",0
l_curso   db "INFB6074 - Infraestructura para Ciencia de Datos",0
l_carrera db "Ingenieria Civil en Ciencia de Datos",0
l_grupo   db "Grupo: I.Ramirez  C.Vergara  F.Provoste",0
l_sep     db "----------------------------------------------------------------",0
e1 db "[CPU]  El procesador arranca en modo real x86 de 16 bits.",0
e2 db "[MEM]  El BIOS carga el boot sector en la direccion 0x7C00.",0
e3 db "[BOOT] Arranque en 2 etapas: stage1 (512 B) carga stage2.",0
e4 db "[VGA]  Texto y emblema escritos directo al framebuffer 0xB8000.",0

; =============================================================================
; RELLENO DE LA ETAPA 2 (4 sectores = 2048 bytes)
; =============================================================================
times 2048-($-$$) db 0
