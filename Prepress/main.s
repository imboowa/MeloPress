.global     _main

_main:
    sub     sp,     sp,     #4096                   // input buffer
    add     X19,    sp,     #2048                   // output buffer
    mov     X20,    #1                              // index for output buffer - space for file header
    // open uncompressed file - dna_1.txt
    adr     X0,     filename_1
    mov     X1,     #0x0000                         // read only
    mov     X2,     #0x0644
    mov     X16,    #5
    svc     0
    mov     X21,    X0                              // file descriptor
    // read dna_1.txt
    mov     X0,     X21
    mov     X1,     sp
    mov     X2,     #2048
    mov     X16,    #3
    svc     0
    mov     X22,    X0                              // bytes read
    mov     X24,    #0                              // last bytes were indivisible by 4
    
_start_loop:
    mov     X0,     #0                              // counter for every 4 bits
    mov     X1,     #0                              // packing byte
    mov     X5,     #0                              // overall counter
loop:
    cmp     X5,     X22                             // compare X5 to actual bytes read
    bge     _write
    cmp     X0,     #4                              // memcopy byte to output buffer
    beq     memcopier
    ldrb    W2,     [sp, X5]
    cmp     W2,     #65                             // A
    beq     for_A
    cmp     W2,     #84                             // T
    beq     for_T
    cmp     W2,     #67                             // C
    beq     for_C
    cmp     W2,     #71                             // G
    beq     for_G
    cmp     W2,     #85                             // U
    beq     for_U
    cmp     W2,     #64                             // @
    beq     _handle_special_character_2
    cmp     W2,     #10                             // newline character
    beq     _handle_special_character_1
    b       _handle_invalid_character               // exit if there is an invalid character
for_A:
    // untill 4 bytes are got the last bytes are indivisble by 4
    mov     X24,    #0
    lsl     X1,     X1,     #2                      // shift by 2 bits
    mov     X4,     #0b00000000
    orr     X1,     X1,     X4                      // put in the beginning 00 into the byte
    add     X0,     X0,     #1
    add     X5,     X5,     #1
    b       loop
for_T:
    // untill 4 bytes are got the last bytes are indivisble by 4
    mov     X24,    #0
    cmp     X23,    #1                              // is program already in RNA mode
    beq     _handle_mixed_modes
    mov     X23,    #0                              // update X23 flag to DNA mode
    lsl     X1,     X1,     #2
    mov     X4,     #0b00000001
    orr     X1,     X1,     X4
    add     X0,     X0,     #1
    add     X5,     X5,     #1
    b       loop
for_C:
    // untill 4 bytes are got the last bytes are indivisble by 4
    mov     X24,    #0
    lsl     X1,     X1,     #2
    mov     X4,     #0b00000010
    orr     X1,     X1,     X4
    add     X0,     X0,     #1
    add     X5,     X5,     #1
    b       loop
for_G:
    // untill 4 bytes are got the last bytes are indivisble by 4
    mov     X24,    #0
    lsl     X1,     X1,     #2
    mov     X4,     #0b00000011
    orr     X1,     X1,     X4
    add     X0,     X0,     #1
    add     X5,     X5,     #1
    b       loop
for_U:
    // untill 4 bytes are got the last bytes are indivisble by 4
    mov     X24,    #0
    cmp     X23,    #0                              // is program already in DNA mode
    beq     _handle_mixed_modes
    mov     X23,    #1                              // update X23 flag to RNA mode
    lsl     X1,     X1,     #2
    mov     X4,     #0b00000001
    orr     X1,     X1,     X4
    add     X0,     X0,     #1
    add     X5,     X5,     #1
    b       loop
memcopier:
    // 4 bytes are got now hence the last bytes are divisble by 4
    mov     X24,    #1
    strb    W1,     [X19, X20]                      // "write" to output buffer
    add     X20,    X20,    #1
    mov     X1,     #0                              // reset packing byte
    mov     X0,     #0                              // reset counter
    b       loop
    
_handle_special_character_1:
    strb    W2,     [X19, X20]                      // store special character
    add     X20,    X20,    #1
    mov     X1,     #0                              // reset packing byte
    mov     X0,     #0                              // reset counter
    add     X5,     X5,     #1
    b       loop

_write:
    cmp     X24,    #0                              // was the length of bytes indivisible by 4
    beq     _handle_indivisibility
    // close old file
    mov     X0,     X21
    mov     X16,    #6
    svc     0
    // insert file header
    strb    W23,    [X19, #0]
    // open dna_1.fgh
    adr     X0,     filename_2
    mov     X1,     #0x0401                         // write or truncate
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
    b       _exit
    
_handle_special_character_2:
    // @ is not considered for 2-bit compression hence no 4 bytes are needed
    mov     X24,    #1
    b       _handle_special_character_1
    

_handle_mixed_modes:
    // close old file - dna_1.txt
    mov     X0,     X21
    mov     X16,    #6
    svc     0
    // exit
    mov     X0,     #1                              // indicates a file contains a mix up of DNA and RNA
    add     sp,     sp,     #4096                   // free buffer
    mov     X16,    #1
    svc     0

_handle_invalid_character:
    // close old file - dna_1.txt
    mov     X0,     X21
    mov     X16,    #6
    svc     0
    // exit
    mov     X0,     #2                              // indicates a file contains invalid characters
    add     sp,     sp,     #4096                   // free buffer
    mov     X16,    #1
    svc     0
    
_handle_indivisibility:
    // close old file - dna_1.txt
    mov     X0,     X21
    mov     X16,    #6
    svc     0
    // exit
    mov     X0,     #3                              // a file's nucleotide length is indivisible by 4
    add     sp,     sp,     #4096                   // free buffer
    mov     X16,    #1
    svc     0

_exit:
    mov     X0,     #0                              // no errors
    add     sp,     sp,     #4096                   // free buffer
    mov     X16,    #1
    svc     0


filename_1:   .asciz  "dna_1.txt"
filename_2:   .asciz  "dna_1.fgh"
