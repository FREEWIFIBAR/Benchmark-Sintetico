.model small
.stack 100h
.data

    cadena       db '0123456789**' 
    LONG_CADENA  equ 12
    
    tics_transcurridos dw 0
    puntero_antiguo_ip dw ?
    puntero_antiguo_cs dw ?
    
    msg_resultado db 'Benchmark finalizado.', 13, 10
                  db 'Tics de reloj (1/18.2s) consumidos: $'
    linea_nueva   db 13, 10, '$'

.code

; RUTINA DE SERVICIO DE INTERRUPCION (ISR)
rutina_reloj proc
    inc tics_transcurridos
    iret
rutina_reloj endp

inicio:

    mov ax, @data
    mov ds, ax

    ; CAPTURA DEL VECTOR DE INTERRUPCION (INT 1Ch)
    mov ax, 0
    mov es, ax
    
    mov bx, 1Ch * 4
    
    mov ax, es:[bx]
    mov puntero_antiguo_ip, ax
    mov ax, es:[bx + 2]
    mov puntero_antiguo_cs, ax
    
    cli
    mov word ptr es:[bx], offset rutina_reloj
    mov es:[bx + 2], cs
    sti

    ; CONFIGURACION DE PANTALLA (Modo Texto 03h - BIOS)
    mov al, 03h
    mov ah, 0
    int 10h

    ; CARGA DE TRABAJO PESADA (Escritura directa en VRAM)
    mov ax, 0B800h
    mov es, ax
    mov ah, 0Eh

    mov cx, 1000        

bucle_pantallas:
    push cx
    xor di, di
    xor si, si

escribe_pantalla:
    mov al, cadena[si]
    mov es:[di], ax
    add di, 2           
    
    inc si
    cmp si, LONG_CADENA
    jne continuar
    xor si, si

continuar:
    cmp di, 3998
    jbe escribe_pantalla

    pop cx
    loop bucle_pantallas

    ; RESTAURACION DEL VECTOR ORIGINAL (Limpieza del sistema)
    mov ax, 0
    mov es, ax
    
    mov bx, 1Ch * 4
    mov ax, puntero_antiguo_ip
    mov dx, puntero_antiguo_cs
    
    cli
    mov es:[bx], ax
    mov es:[bx + 2], dx
    sti

    ; IMPRESION DE RESULTADOS DEL BENCHMARK
    mov al, 03h
    mov ah, 0
    int 10h

    mov dx, offset msg_resultado
    mov ah, 09h
    int 21h

    mov ax, tics_transcurridos
    call imprimir_numero

    mov dx, offset linea_nueva
    mov ah, 09h
    int 21h

    mov ah, 4Ch
    int 21h

; RUTINA AUXILIAR: Conversor numerico rapido
imprimir_numero proc
    mov cx, 0
    mov bx, 10
descomponer:
    xor dx, dx
    div bx              
    push dx             
    inc cx
    cmp ax, 0
    jne descomponer
mostrar_digitos:
    pop dx              
    add dl, '0'         
    mov ah, 02h         
    int 21h
    loop mostrar_digitos
    ret
imprimir_numero endp

end inicio