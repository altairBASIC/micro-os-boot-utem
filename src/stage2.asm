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
; El modo de texto estandar es 80 columnas x 25 filas. Cada celda ocupa
; 2 bytes consecutivos en memoria: el primero es el codigo de caracter
; (CP437) y el segundo es el atributo de color (nibble alto = color de
; fondo, nibble bajo = color de texto). Escribir en 0xB8000 es como un SO
; real maneja la consola de texto: sin llamar al BIOS, tratando el video
; como un arreglo plano de 4000 bytes.
; =============================================================================

BITS 16
ORG  0x7E00             ; Direccion donde la etapa 1 cargo este codigo

stage2_start:
    ; -------------------------------------------------------------------------
    ; Apuntar ES al segmento del framebuffer de texto.
    ; 0xB800 * 16 = 0xB8000 (direccion fisica de inicio del video en modo texto).
    ; -------------------------------------------------------------------------
    mov ax, 0xB800
    mov es, ax

    ; -------------------------------------------------------------------------
    ; Limpiar las 2000 celdas (80*25) con espacio gris sobre fondo negro.
    ; rep stosw escribe AX en [ES:DI] CX veces, autoincrementando DI.
    ; -------------------------------------------------------------------------
    xor di, di
    mov cx, 2000
    mov ax, 0x0720      ; AH=0x07 atributo gris, AL=0x20 caracter espacio
    rep stosw

    ; -------------------------------------------------------------------------
    ; Recorrer la tabla de descriptores. Cada entrada describe una cadena:
    ;   db fila, columna, color   +   dw puntero_a_cadena   = 5 bytes
    ; El centinela fila=0xFF marca el fin de la tabla.
    ; -------------------------------------------------------------------------
    mov si, tabla
.fila:
    mov al, [si]            ; AL = fila
    cmp al, 0xFF            ; ¿Fin de la tabla?
    je  halt_loop
    mov ah, 0
    mov cx, 80
    mul cx                  ; AX = fila * 80
    mov bl, [si+1]          ; BL = columna
    mov bh, 0
    add ax, bx              ; AX = fila*80 + columna  (indice de celda)
    shl ax, 1               ; *2 porque cada celda son 2 bytes
    mov di, ax              ; DI = offset destino en el framebuffer
    mov dl, [si+2]          ; DL = atributo de color de esta linea
    mov bx, [si+3]          ; BX = puntero a la cadena
.car:
    mov al, [bx]            ; Caracter actual de la cadena
    cmp al, 0               ; ¿Terminador nulo?
    je  .siguiente
    mov ah, dl              ; AH = atributo de color
    mov [es:di], ax         ; Escribir [caracter|color] en la celda de video
    inc bx
    add di, 2               ; Avanzar a la siguiente celda
    jmp .car
.siguiente:
    add si, 5               ; Avanzar al siguiente descriptor (5 bytes)
    jmp .fila

    ; -------------------------------------------------------------------------
    ; Halt loop. Un sistema operativo real cargaria aqui su kernel desde el
    ; disco y le cederia el control. Este programa solo detiene la CPU
    ; porque su proposito es exclusivamente didactico.
    ; -------------------------------------------------------------------------
halt_loop:
    cli
    hlt
    jmp halt_loop

; =============================================================================
; TABLA DE DESCRIPTORES: db fila, columna, color  +  dw puntero
; Colores VGA usados: 0x0A verde, 0x0F blanco, 0x0B cian, 0x0E amarillo,
; 0x09 azul, 0x07 gris. (Institucionales UTEM: verde, azul, blanco.)
; =============================================================================
tabla:
    db 1, 27, 0x0A
    dw b1
    db 2, 27, 0x0A
    dw b2
    db 3, 27, 0x0A
    dw b3
    db 4, 27, 0x0A
    dw b4
    db 5, 27, 0x0A
    dw b5
    db 7, 18, 0x0F
    dw l_univ
    db 8, 18, 0x0B
    dw l_curso
    db 9, 18, 0x0E
    dw l_carrera
    db 10, 23, 0x0F
    dw l_grupo
    db 12, 9, 0x09
    dw l_sep
    db 14, 9, 0x07
    dw e1
    db 15, 9, 0x07
    dw e2
    db 16, 9, 0x07
    dw e3
    db 17, 9, 0x07
    dw e4
    db 18, 9, 0x07
    dw e5
    db 20, 9, 0x09
    dw l_sep
    db 22, 20, 0x0A
    dw l_ok
    db 0xFF                 ; Centinela de fin de tabla

; =============================================================================
; DATOS: Banner ASCII art "U T E M" con bloque solido CP437 (0xDB)
; En el framebuffer VGA el byte 0xDB se renderiza como un rectangulo lleno.
; =============================================================================
; Letras U T E M en rejilla 5x5, separadas por 2 espacios (ancho total 26).
; Bytes generados con grilla para garantizar alineacion exacta de columnas.
b1 db 0xDB,' ',' ',' ',0xDB,' ',' ',0xDB,0xDB,0xDB,0xDB,0xDB,' ',' ',0xDB,0xDB,0xDB,0xDB,0xDB,' ',' ',0xDB,' ',' ',' ',0xDB,0
b2 db 0xDB,' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,' ',' ',' ',' ',' ',' ',0xDB,0xDB,' ',0xDB,0xDB,0
b3 db 0xDB,' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,0xDB,0xDB,0xDB,' ',' ',' ',0xDB,' ',0xDB,' ',0xDB,0
b4 db 0xDB,' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,' ',' ',' ',' ',' ',' ',0xDB,' ',' ',' ',0xDB,0
b5 db ' ',0xDB,0xDB,0xDB,' ',' ',' ',' ',' ',0xDB,' ',' ',' ',' ',0xDB,0xDB,0xDB,0xDB,0xDB,' ',' ',0xDB,' ',' ',' ',0xDB,0

; =============================================================================
; DATOS: Lineas institucionales y explicativas
; =============================================================================
l_univ    db "Universidad Tecnologica Metropolitana - UTEM",0
l_curso   db "INFB6074 - Infraestructura para Ciencia de Datos",0
l_carrera db "Ingenieria Civil en Ciencia de Datos",0
l_grupo   db "Grupo: I.Ramirez  C.Vergara  F.Provoste",0
l_sep     db "----------------------------------------------------------------",0

; --- 5 lineas explicativas sobre arquitectura (el enunciado pide al menos 3) ---
e1 db "[CPU]  El procesador arranca en modo real x86 de 16 bits.",0
e2 db "[MEM]  El BIOS carga el boot sector en la direccion 0x7C00.",0
e3 db "[BOOT] Bootloader de 2 etapas: stage1 (512 B) carga stage2.",0
e4 db "[VGA]  El texto se escribe directo al framebuffer 0xB8000.",0
e5 db "[SO]   La firma 0xAA55 marca el primer sector como arrancable.",0

l_ok db ">> Boot exitoso en dos etapas. CPU detenido con hlt. <<",0

; =============================================================================
; RELLENO DE LA ETAPA 2
; Se rellena hasta completar un numero entero de sectores (4 sectores =
; 2048 bytes) para que la lectura de disco de la etapa 1 sea consistente.
; =============================================================================
times 2048-($-$$) db 0
