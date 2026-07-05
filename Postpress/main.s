.global     _main

_main:
    sub     sp,     sp,     #4096                   // Approximately 4 KB
    add     X19,    sp,     #2048                   // Approximately 2 KB
    mov     X20,    #0
    // open compressed file - dna_1.fgh
    adr     X0,     filename_1
    mov     X1,     #0x0000                         // read only
    mov     X2,     #0x0644
    mov     X16,    #5
    svc     0
    mov     X21,    X0                              // file descriptor
    // read into input buffer
    mov     X0,     X21
    mov     X1,     sp
    mov     X2,     #2048
    mov     X16,    #3
    svc     0
    mov     X22,    X0                              // actual bytes read
    mov     X1,     #1                              // overall counter - skip file header
    ldrb    W23,    [sp, #0]                        // load file header

_start:
    cmp     X1,     X22
    bge     _write
    mov     X2,     #0                              // bit decompression counter
    ldrb    W0,     [sp, X1]                        // current byte
    cmp     W0,     #64                             // ascii code for @
    beq     _handle_special_incident_2
    cmp     W0,     #10                             // ascii code for newline character
    beq     _handle_special_incident_1
    mov     W3,     #0b11000000
loop:
    cmp     X2,     #4                              // is program done with last bit
    bge     end_loop
    and     W4,     W0,     W3
    cmp     W4,     #0x00                           // then it is A
    beq     handle_A
    cmp     W4,     #0x40                           // then it is T
    beq     handle_T
    cmp     W4,     #0xC0                           // then it is G
    beq     handle_G
    cmp     W4,     #0x80                           // then it is C
    beq     handle_C
handle_A:
    mov     W4,     #65
    strb    W4,     [X19, X20]
    add     X20,    X20,    #1
    add     X2,     X2,     #1
    lsl     W0,     W0,     #2                      // shift by 2 bits
    b       loop
handle_T:
    cmp     W23,    #1                              // is RNA mode on
    beq     handle_U
    mov     W4,     #84
    strb    W4,     [X19, X20]
    add     X20,    X20,    #1
    add     X2,     X2,     #1
    lsl     W0,     W0,     #2                      // shift by 2 bits
    b       loop
handle_G:
    mov     W4,     #71
    strb    W4,     [X19, X20]
    add     X20,    X20,    #1
    add     X2,     X2,     #1
    lsl     W0,     W0,     #2                      // shift by 2 bits
    b       loop
handle_C:
    mov     W4,     #67
    strb    W4,     [X19, X20]
    add     X20,    X20,    #1
    add     X2,     X2,     #1
    lsl     W0,     W0,     #2                      // shift by 2 bits
    b       loop
handle_U:
    mov     W4,     #85
    strb    W4,     [X19, X20]
    add     X20,    X20,    #1
    add     X2,     X2,     #1
    lsl     W0,     W0,     #2                      // shift by 2 bits
    b       loop
end_loop:
    add     X1,     X1,     #1
    b       _start

_handle_special_char:
    strb    W0,     [X19, X20]                      // store special character
    add     X20,    X20,    #1
    add     X1,     X1,     #1
    b       _start
    
_handle_special_incident_1:
    // checking backward
    sub     X1,     X1,     #1
    cmp     X1,     #0
    blt     _write
    ldrb    W5,     [sp, X1]                        // load byte that is behind
    add     X1,     X1,     #1                      // reinstate overall counter - X1
    cmp     W5,     #64                             // @
    beq     _handle_special_char                    // allows newline char to appear infront
    // checking forward
    add     X1,     X1,     #1
    cmp     X1,     X22
    bge     _write
    ldrb    W5,     [sp, X1]                        // load byte that is ahead
    sub     X1,     X1,     #1                      // reinstate overall counter - X1
    cmp     W5,     #64                             // @
    bne     loop                                    // does not allow newline char to appear behind
    b       _handle_special_char                    // allows newline char to appear behind
    
_handle_special_incident_2:
    // checking forward
    add     X1,     X1,     #1
    cmp     X1,     X22
    bge     _write
    ldrb    W5,     [sp, X1]                        // load byte that is ahead
    sub     X1,     X1,     #1                      // reinstate overall counter - X1
    cmp     W5,     #10                             // newline character
    bne     loop                                    // does not allow @ char to appear behind
    b       _handle_special_char                    // allows @ char to appear behind

_write:
    // close old file - dna_1.fgh
    mov     X0,     X21
    mov     X16,    #6
    svc     0
    // open new file - dna_1.txt
    adr     X0,     filename_2
    mov     X1,     #0x0601                         // write or create or truncate
    mov     X2,     #0x0644
    mov     X16,    #5
    svc     0
    mov     X21,    X0                              // new file descriptor
    // write to new file
    mov     X0,     X21
    mov     X1,     X19
    mov     X2,     X20
    mov     X16,    #4
    svc     0
    // close new file
    mov     X0,     X21
    mov     X16,    #6
    svc     0
    
_exit:
    add     sp,     sp,     #4096                   // free memory
    mov     X0,     #0                              // no errors
    mov     X16,    #1
    svc     0
    
    
filename_1:         .asciz  "dna_1.fgh"
filename_2:         .asciz  "dna_1.txt"
