.global     _main


_main:
    // Get User's Commandline Arguments
    mov     X10,    X0                              // argc - How Many Commandline Arguments
    cmp     X10,    #2
    bne     _commandline_argument_error
    // Skip argv[0] - Filename - Get User Requested File argv[1] Or [X1, #8]
    ldr     X9,    [X1, #8]                         // argv - (char **) Pointer To A String Array
    mov     X10,    X9
_is_file_compressed:
    sub     sp,     sp,     #16
    // Is File Compressed Or Uncompressed
    mov     X0,     X9
    mov     X1,     #0x0000                         // Read Only
    mov     X2,     #0
    mov     X16,    #5                              // open
    svc     0
    bcs     _file_error                             // Branch To _file_error If Carry Flag Is Set
    mov     X19,    X0                              // Store File Descriptor - Globally
    // X0 - Already Filled In As File Descriptor
    mov     X1,     sp
    mov     X2,     #4
    mov     X16,    #3                              // read
    svc     0
    bcs     _file_error
    cmp     X0,     #0                              // Empty File
    beq     _end_program                            // X0 Is Already 0 Hence Success In Program - Trick
    // Check Header
    ldrb    W0,     [sp, #0]                        // Expect #
    cmp     W0,     #0b00100011
    bne     continue_1
    ldrb    W1,     [sp, #1]                        // Expect H
    cmp     W1,     #0b01001000
    bne     continue_1
    ldrb    W2,     [sp, #2]                        // Expect 9
    cmp     W2,     #0b00111001
    bne     continue_1
    ldrb    W3,     [sp, #3]                        // File Header
    mov     W4,     #0b00000010
    and     W5,     W3,     W4
    cmp     W5,     #0b00000010                     // Is File Already Compressed
    beq     _already_compressed_error
    mov     W4,     #0b00000100                     // Reusage Of Variables = Overwriting
    and     W5,     W3,     W4
    cmp     W5,     #0b00000100                     // Is File A .fgh File
    bne     _not_fgh_file_error
continue_1:
    // Set File Pointer Back To Beginning - lseek - Because Of Read
    mov     X0,     X19
    mov     X1,     #0
    mov     X2,     #0
    mov     X16,    #199                            // lseek
    svc     0
    b       _start_1
_commandline_argument_error:
    mov     X0,     #1                              // CommandLine Argument Error
    b       _end_program
_file_error:
    mov     X0,     #2                              // File Error
    add     sp,     sp,     #16
    b       _end_program
_already_compressed_error:
    mov     X0,     #3                              // Already Compressed File
    add     sp,     sp,     #16
    b       _end_program
_not_fgh_file_error:
    mov     X0,     #4                              // Not A .fgh File
    add     sp,     sp,     #16
    b       _end_program


_start_1:
    mov     X0,     #0
x_1:
    cmp     X0,     #16
    bge     y_1
    mov     X1,     #0
    strb    W1,     [sp, X0]
    add     X0,     X0,     #1
    b       x_1
y_1:
    // Make Directory Where Compressed Chunks Are Stored
    mov     X0,     #0                              // Number Of Characters In The Foldername
    mov     X1,     #0
loop_A:
    cmp     X1,     #10                             // Capping Foldername To 10 Characters + 4 Chars (_fgh)
    bge     end_loop_A
    ldrb    W2,     [X9, X0]                        // Load Byte From Filename In X9
    cmp     W2,     #46                             // Stop At The Full Stop
    beq     end_loop_A
    strb    W2,     [sp, X1]
    add     X0,     X0,     #1
    add     X1,     X1,     #1
    b       loop_A
end_loop_A:
    mov     X2,     #95                             // Underscore - _
    strb    W2,     [sp, X1]
    add     X1,     X1,     #1
    mov     X2,     #102                            // f
    strb    W2,     [sp, X1]
    add     X1,     X1,     #1
    mov     X2,     #103                            // g
    strb    W2,     [sp, X1]
    add     X1,     X1,     #1
    mov     X2,     #104                            // h
    strb    W2,     [sp, X1]
    add     X1,     X1,     #1
    mov     X2,     #0                              // Null Terminator
    strb    W2,     [sp, X1]
    mov     X7,     X1                              // Store X1 In X7 - Used In empty_directory
open_directory:
    // Get File Descriptor For Directory
    mov     X0,     #-2                             // Current Directory On macOS Apple Silicon
    add     X1,     sp,     #0                      // Pointer To The Location Of The Foldername
    mov     X2,     #0x00100000                     // Opening A Directory On macOS Apple Silicon
    mov     X3,     #0
    mov     X16,    #463                            // openat
    svc     0
    bcs     make_new_directory
    mov     X20,    X0                              // Save Directory Descriptor
    // Make Sure Directory Is Empty
    b       empty_directory
make_new_directory:
    // Make The Directory
    add     X0,     sp,     #0                      // Pointer To Location Of The Foldername
    mov     X1,     #448                            // rwx - Owner Only And 0 For Group And Others
    mov     X16,    #136                            // mkdir
    svc     0
    bcs     _error_making_directory
    b       open_directory
empty_directory:
    mov     X1,     #1
    mov     X0,     #47                             // Insert "/"
    strb    W0,     [sp, X7]
    add     X7,     X7,     #1
    mov     X9,     X7                              // Store Beginning Of Reversed Filename
    mov     X27,    X7                              // Use Global Registers - Store Real Starting Point
part_A:
    mov     X7,     X27                             // Global Register - To This Function - With The Real Starting Point
    mov     X9,     X27
    ldr     X0,     =1000000
    cmp     X1,     X0                              // Check For All Possible Files - 1,000,000 Files
    bgt     end_removal
    mov     X2,     X1                              // Creates A Copy Of Counter
loop_B:
    // Converts Counter Into Ascii
    cmp     X2,     #0
    ble     temp_1
    mov     X4,     #10
    udiv    X5,     X2,     X4
    mul     X6,     X5,     X4
    sub     X4,     X2,     X6
    mov     X2,     X5
    add     X4,     X4,     #48
    strb    W4,     [sp, X7]
    add     X7,     X7,     #1
    mov     X6,     X7                              // Creates A Copy Of X7 - Used In Reversing Filename
    b       loop_B
temp_1:
    sub     X7,     X7,     #1                      // Subtract X7 To Prevent Out Of Bounds Error
    b       part_B
part_B:
    // Now Reverse The Filename To The Correct Order
    cmp     X9,     X7
    bge     end
    // Swap Values
    ldrb    W5,     [sp, X7]                        // Load Byte At The End
    ldrb    W4,     [sp, X9]                        // Load Byte At The Beginning
    strb    W5,     [sp, X9]                        // Store Byte (Was At The End) To The Beginning
    strb    W4,     [sp, X7]                        // Store Byte (Was At The Beginning) To The End
    sub     X7,     X7,     #1
    add     X9,     X9,     #1
    sub     X2,     X2,     #1
    b       part_B
end:
    mov     X0,     #46                             // Insert .
    strb    W0,     [sp, X6]
    add     X6,     X6,     #1
    mov     X0,     #102                            // Insert f
    strb    W0,     [sp, X6]
    add     X6,     X6,     #1
    mov     X0,     #103                            // Insert g
    strb    W0,     [sp, X6]
    add     X6,     X6,     #1
    mov     X0,     #104                            // Insert h
    strb    W0,     [sp, X6]
    add     X6,     X6,     #1
    mov     X0,     #0                              // Null Terminator
    strb    W0,     [sp, X6]
    mov     X3,     X1                              // Save X1 - Volatile Register
    // Remove File - unlink
    add     X0,     sp,     #0
    mov     X16,    #10                             // unlink
    svc     0
    bcs     end_removal
    mov     X1,     X3
    add     X1,     X1,     #1                      // Jump To Next File To Be Removed
    b       part_A
end_removal:
    add     sp,     sp,     #16
    b       _start_2
_error_making_directory:
    mov     X0,     #5                              // Error Making Directory
    add     sp,     sp,     #16
    b       _end_program


_start_2:
    mov     X7,     #0                              // Reset X7 To Reflect - There Are No Files Made Yet
    b       _start_compression
_make_file_1:
    mov     X6,     #1                              // Indicates Inside A File
    mov     X4,     X7                              // Copy Of Files Created Counter
    mov     X3,     #7                              // 7 Is The Longest Filename - 1000000.fgh
into_ascii:
    cmp     X3,     #0
    ble     make_file_2
    cmp     X4,     #0
    ble     make_file_2
    mov     X0,     #10
    udiv    X1,     X4,     X0
    mul     X2,     X1,     X0
    sub     X0,     X4,     X2                      // The Reminder
    mov     X4,     X1                              // Update X4 With "Cut Off" Portion
    add     X0,     X0,     #48                     // Getting The Ascii Version Of The Reminder
    strb    W0,     [sp, X3]
    sub     X3,     X3,     #1
    b       into_ascii
make_file_2:
    add     X3,     X3,     #1                      // Because X3 Was Pushed To Unknown Data (Garbage)
    // Prepare Filename Fully
    mov     X1,     #46                             // .
    strb    W1,     [sp, #8]
    mov     X1,     #102                            // f
    strb    W1,     [sp, #9]
    mov     X1,     #103                            // g
    strb    W1,     [sp, #10]
    mov     X1,     #104                            // h
    strb    W1,     [sp, #11]
    mov     X1,     #0                              // Null Terminator
    strb    W1,     [sp, #12]
    // openat This File To Foldername
    mov     X0,     X20
    add     X1,     sp,     X3                      // Pointer To The Location Of Filename Like 1.fgh
    mov     X2,     #0x020A                         // O_RDWR | O_CREAT | O_APPEND
    mov     X3,     #504                            // Owner - rwx And Group - rwx And Others - 0
    mov     X16,    #463                            // openat
    svc     0
    bcs     _error_making_file
    mov     X21,    X0                              // Save File Descriptor
    cmp     X23,    X5
    bge     loop_1
    b       loop_2
_error_making_file:
    mov     X0,     #6                              // Error Creating A Chunk File During Compression
    add     sp,     sp,     #16
    b       _end_program


_start_compression:
    // Pointers
    sub     sp,     sp,     #4096
    add     X22,    sp,     #16                     // Buffer For Uncompressed Data
    add     X24,    sp,     #2056                   // Buffer For Compressed Data
    // Persistent Variables
    // X3 Just Prevents The Procedure Of - Compressing Then Creating A File
    // Prepress Must Do - Create The File Then Compress
    // It Is Only Useful In The First Loop Of Compression
    // Since The Procedure Has Been Set - Prepress Follows That Procedure
    mov     X3,     #0                              // Is In A Read Index - "Boolean Variable"
    // X6 Prevents Writing To A File Twice
    // X6 Is Only Turned On When A New File Is Made
    // X6 Is Off When That New File Is Written To And Closed Hence No New File In That Current Loop
    mov     X6,     #0                              // Not Yet Inside A File
    mov     X11,    #0                              // No Calls To read Yet
    mov     X12,    #0                              // X11 Reviver
    mov     X26,    #2                              // Sequence Type Flag
    mov     X27,    #0                              // Temporarily Using X27 For Buffer Clean Up
x_2:
    cmp     X27,    #4096
    bge     loop_1
    mov     X0,     #0
    strb    W0,     [sp, X27]
    add     X27,    X27,    #1
    b       x_2
loop_1:
    // Read Continuously From Uncompressed Data File
    mov     X0,     X19
    mov     X1,     X22
    mov     X2,     #2040
    mov     X16,    #3                              // read
    svc     0
    bcs     _error_reading_uncompressed_data_file
    cmp     X0,     #0
    beq     _end_program_successfully
    mov     X5,     X0                              // Save Read Bytes
    mov     X11,    #1                              // read Has Been Called
    mov     X27,    #0                              // Packing Byte
    mov     X28,    #0                              // Counter For Every 4 Bits
    mov     X25,    #0                              // Index For Compressed Data
    mov     X23,    #0                              // Overall Counter - Index For Uncompressed Data
loop_2:
    cmp     X28,    #4                              // Memcopy Byte To Compressed Data Buffer
    beq     memcopier
    cmp     X23,    X5                              // Compare X23 To Read Bytes - X5
    bge     final_write                             // Do Not Reset X6 Here Because Program Could Still Be In A File
    ldrb    W2,     [X22, X23]
    add     X23,    X23,    #1
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
    cmp     W2,     #10                             // Newline - \n - Skip Newline
    beq     loop_2
    cmp     W2,     #64                             // @
    beq     _handle_read_index_marker
    b       loop_2                                  // Any Invalid Character Is Skipped
for_A:
    lsl     X27,    X27,    #2                      // Shift By 2 Bits
    mov     X2,     #0b00000000
    orr     X27,    X27,    X2                      // orr In The Byte
    add     X28,    X28,    #1
    b       loop_2
for_T:
    cmp     X26,    #1                              // Is Program Already In RNA Mode
    beq     _handle_mixed_modes
    mov     X26,    #0                              // Update X26 Flag To DNA Mode
    lsl     X27,    X27,    #2
    mov     X2,     #0b00000001
    orr     X27,    X27,    X2
    add     X28,    X28,    #1
    b       loop_2
for_C:
    lsl     X27,    X27,    #2
    mov     X2,     #0b00000010
    orr     X27,    X27,    X2
    add     X28,    X28,    #1
    b       loop_2
for_G:
    lsl     X27,    X27,    #2
    mov     X2,     #0b00000011
    orr     X27,    X27,    X2
    add     X28,    X28,    #1
    b       loop_2
for_U:
    cmp     X26,    #0                              // Is Program Already In DNA Mode
    beq     _handle_mixed_modes
    mov     X26,    #1                              // Update X26 Flag To RNA Mode
    lsl     X27,    X27,    #2
    mov     X2,     #0b00000001
    orr     X27,    X27,    X2
    add     X28,    X28,    #1
    b       loop_2
memcopier:
    strb    W27,    [X24, X25]                      // "Write" To Compressed Data Buffer
    add     X25,    X25,    #1
    mov     X27,    #0                              // Reset Packing Byte
    mov     X28,    #0                              // Reset Counter
    // Check Bounds
    cmp     X23,    X5                              // Compare X25 To Bytes Read - X5
    blt     loop_2
final_write:
    // In Case It Is The End Of Read Index - Add Partial Bytes Too
    cmp     X28,    #0
    bne     add_partial_bytes_1
continue_2:
    b       _write_file_header_1
add_partial_bytes_1:
    strb    W27,    [X24, X25]
    add     X25,    X25,    #1
    // Do Not Reset X28 And X27 So That _write_file_header Has A Chance To Reflect Indivisibility In File Header
    b       continue_2


_handle_read_index_marker:
    mov     X12,    #0                              // Toggle Off X11 Riviver
    mov     X6,     #0                              // Not Yet Inside A New File
    add     X7,     X7,     #1                      // Update Files Created
    cmp     X3,     #0                              // Is In Read Index Mode?
    beq     set_is_in_read_index
    // In Case It Is The End Of The Read Index - Add Partial Bytes Too
    cmp     X28,    #0
    bne     add_partial_bytes_2
continue_3:
    b       _write_file_header_1
set_is_in_read_index:
    mov     X11,    #0                              // Toggle Off Reads Made - Since The First Read Turns It On - Not Yet Needed By Prepress
    mov     X12,    #0
    mov     X3,     #1                              // Indicate That Were Are In A Read Index
    b       _prepare_make_file_1
add_partial_bytes_2:
    strb    W27,    [X24, X25]
    add     X25,    X25,    #1
    // Do Not Reset X28 And X27 So That _write_file_header Has A Chance To Reflect Indivisibility In File Header
    b       continue_3


_write_file_header_1:
    cmp     X12,    #1
    beq     temp_2
    b       continue_8
temp_2:
    // If Reviver (X12) Is Clocked In X11 (Revivee) Cannot Be Clocked In Too Maintain X12 Clocked Out While X11 Clocked In Not Both (Vice Versa)
    cmp     X11,    #0
    beq     continue_8
    mov     X11,    #1                              // Revive X11
continue_8:
    // Make File Magic
    mov     X0,     #0b00100011                     // #
    strb    W0,     [sp, #0]
    mov     X0,     #0b01001000                     // H
    strb    W0,     [sp, #1]
    mov     X0,     #0b00111001                     // 9
    strb    W0,     [sp, #2]
    // Make File Header
    cmp     X7,     #2                              // Is This The Head File - Added 1 Before This Part
    beq     walkaround_1
    cmp     X7,     #1                              // This Happens When The Head File Is Alone
    beq     write_file_header_2
    b       write_file_header_4
walkaround_1:
    // Files Like 2.fgh Or More (3.fgh, ...) Must Not Be Head File But Rather Tail Files
    cmp     X23,    X5
    bge     write_file_header_4
    b       write_file_header_2
// Head File
write_file_header_2:
    cmp     X26,    #0                              // Is This DNA
    beq     write_file_header_3
    // Else This Is RNA
    cmp     X28,    #0                              // Is This Head File Length Divisible By 4
    bne     write_file_header_2_1
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_4
    mov     X0,     #0b11000111
    b       write_1
continue_4:
    mov     X0,     #0b01000111
    b       write_1
write_file_header_2_1:
    // Since The File Has An Indivisible Length - Indicate In File Header How Many Bytes Are In The Partial Byte
    cmp     X28,    #1
    beq     write_file_header_2_1_a
    cmp     X28,    #2
    beq     write_file_header_2_1_b
    cmp     X28,    #3
    beq     write_file_header_2_1_c
write_file_header_2_1_a:
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_4_a
    mov     X0,     #0b11011111
    b       write_1
continue_4_a:
    mov     X0,     #0b01011111
    b       write_1
write_file_header_2_1_b:
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_4_b
    mov     X0,     #0b11101111
    b       write_1
continue_4_b:
    mov     X0,     #0b01101111
    b       write_1
write_file_header_2_1_c:
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_4_c
    mov     X0,     #0b11111111
    b       write_1
continue_4_c:
    mov     X0,     #0b01111111
    b       write_1
// Head File Is DNA
write_file_header_3:
    cmp     X28,    #0                              // Is This Head File Length Divisible by 4
    bne     write_file_header_3_1
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_6
    mov     X0,     #0b11000110
    b       write_1
continue_6:
    mov     X0,     #0b01000110
    b       write_1
write_file_header_3_1:
    // Since The File Has An Indivisible Length - Indicate In File Header How Many Bytes Are In The Partial Byte
    cmp     X28,    #1
    beq     write_file_header_3_1_a
    cmp     X28,    #2
    beq     write_file_header_3_1_b
    cmp     X28,    #3
    beq     write_file_header_3_1_c
write_file_header_3_1_a:
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_6_a
    mov     X0,     #0b11011110
    b       write_1
continue_6_a:
    mov     X0,     #0b01011110
    b       write_1
write_file_header_3_1_b:
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_6_b
    mov     X0,     #0b11101110
    b       write_1
continue_6_b:
    mov     X0,     #0b01101110
    b       write_1
write_file_header_3_1_c:
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_6_c
    mov     X0,     #0b11111110
    b       write_1
continue_6_c:
    mov     X0,     #0b01111110
    b       write_1
// For Tail Files - Files That Are Not The First File
write_file_header_4:
    cmp     X26,    #0                              // Is This DNA
    beq     write_file_header_5
    // Else This Is RNA
    cmp     X28,    #0                              // Is This Tail File Length Divisible By 4
    bne     write_file_header_4_1
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_5
    mov     X0,     #0b10000111
    b       write_1
continue_5:
    mov     X0,     #0b00000111                     // Else This Is RNA
    b       write_1
write_file_header_4_1:
    // Since The File Has An Indivisible Length - Indicate In File Header How Many Bytes Are In The Partial Byte
    cmp     X28,    #1
    beq     write_file_header_4_1_a
    cmp     X28,    #2
    beq     write_file_header_4_1_b
    cmp     X28,    #3
    beq     write_file_header_4_1_c
write_file_header_4_1_a:
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_5_a
    mov     X0,     #0b10011111
    b       write_1
continue_5_a:
    mov     X0,     #0b00011111
    b       write_1
write_file_header_4_1_b:
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_5_b
    mov     X0,     #0b10101111
    b       write_1
continue_5_b:
    mov     X0,     #0b00101111
    b       write_1
write_file_header_4_1_c:
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_5_c
    mov     X0,     #0b10111111
    b       write_1
continue_5_c:
    mov     X0,     #0b00111111
    b       write_1
write_file_header_5:
    cmp     X28,    #0                              // Is This Tail File Length Divisble By 4
    bne     write_file_header_5_1
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_7
    mov     X0,     #0b10000110
    b       write_1
continue_7:
    mov     X0,     #0b00000110
    b       write_1
write_file_header_5_1:
    // Since The File Has An Indivisible Length - Indicate In File Header How Many Bytes Are In The Partial Byte
    cmp     X28,    #1
    beq     write_file_header_5_1_a
    cmp     X28,    #2
    beq     write_file_header_5_1_b
    cmp     X28,    #3
    beq     write_file_header_5_1_c
write_file_header_5_1_a:
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_7_a
    mov     X0,     #0b10011110
    b       write_1
continue_7_a:
    mov     X0,     #0b00011110
    b       write_1
write_file_header_5_1_b:
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_7_b
    mov     X0,     #0b10101110
    b       write_1
continue_7_b:
    mov     X0,     #0b00101110
    b       write_1
write_file_header_5_1_c:
    cmp     X11,    #1                              // If In A Read Index Has Prepress Called read - During Reads Lies Read Index Segmentation
    bne     continue_7_c
    mov     X0,     #0b10111110
    b       write_1
continue_7_c:
    mov     X0,     #0b00111110
write_1:
    cmp     X11,    #1
    beq     temp_3
    b       continue_9
temp_3:
    mov     X11,    #0                              // Toggle Off Reads Made
    mov     X12,    #1                              // When X11 Clocks Out - X12 Clocks In Which Ensures That All N Segments Are Catered For
continue_9:
    mov     X11,    #0                              // For Safety In Case X11 Is A Value Not 1 Or 0
    strb    W0,     [sp, #3]
    mov     X0,     #0                              // Null Terminator
    strb    W0,     [sp, #4]
    // Set File Pointer To Start Of File - lseek
    mov     X0,     X21
    mov     X1,     #0
    mov     X2,     #0
    mov     X16,    #199                            // lseek
    // Write Header To File
    mov     X0,     X21
    add     X1,     sp,     #0
    mov     X2,     #4
    mov     X16,    #4
    svc     0
    // Write Bytes To File
    mov     X0,     X21
    mov     X1,     X24
    mov     X2,     X25
    mov     X16,    #4
    svc     0
    // Reset Variables That Are Used In A Current Read Index
    mov     X25,    #0
    mov     X28,    #0
    mov     X27,    #0
    cmp     X6,     #1                              // Make A New File With A New Name
    beq     temp_check_2
    b       _prepare_make_file_1
temp_check_2:
    add     X7,     X7,     #1
    b       _prepare_make_file_1
_prepare_make_file_1:
    // Skip Closing Previous File Because Prepress Is Just Getting Started
    cmp     X7,     #1
    beq     _make_file_1
    // Closes Previous Made File To Create Room For New File Descriptor
    mov     X0,     X21
    mov     X16,    #6                             // close
    svc     0
    b       _make_file_1
_error_reading_uncompressed_data_file:
    // Close Files
    mov     X0,     X19
    mov     X16,    #6                             // close
    svc     0
    mov     X0,     X21
    mov     X16,    #6                             // close
    svc     0
    // Close Directory
    mov     X0,     X20
    mov     X16,    #6                             // close
    svc     0
    add     sp,     sp,     #4096                  // Free _start_compression Stack
    mov     X22,    #0                             // Set Dangling Pointer To 0
    mov     X24,    #0                             // Set Dangling Pointer To 0
    mov     X0,     #7
    b       _end_program
_handle_mixed_modes:
    // Close Files
    mov     X0,     X19
    mov     X16,    #6                             // close
    svc     0
    mov     X0,     X21
    mov     X16,    #6                             // close
    svc     0
    // Close Directory
    mov     X0,     X20
    mov     X16,    #6                             // close
    svc     0
    add     sp,     sp,     #4096                  // Free _start_compression Stack
    mov     X22,    #0                             // Set Dangling Pointer To 0
    mov     X24,    #0                             // Set Dangling Pointer To 0
    mov     X0,     #8                             // File Contains RNA And DNA
    b       _end_program
_error_cleaning_up:
    // Close Directory
    mov     X0,     X20
    mov     X16,    #6
    svc     0
    add     sp,     sp,     #32                    // Free Stack
    mov     X0,     #9                             // Clean Up Was Not Finished
    b       _end_program
_end_program_successfully:
    // Close Files
    mov     X0,     X19
    mov     X16,    #6
    svc     0
    mov     X0,     X21
    mov     X16,    #6
    svc     0
    add     sp,     sp,     #4096                  // Free _start_compression Stack
    mov     X22,    #0                             // Set Dangling Pointer To 0
    mov     X24,    #0                             // Set Dangling Pointer To 0
    // Start With Directory Name
    mov     X9,     #3
    sub     sp,     sp,     #32
    mov     X0,     #46                            // .
    strb    W0,     [sp, X9]
    add     X9,     X9,     #1
    mov     X0,     #47                            // /
    strb    W0,     [sp, X9]
    add     X9,     X9,     #1
    mov     X23,    #0
get_directory_name:
    ldrb    W25,    [X10, X23]
    cmp     X23,    #14                            // Is The Maximum Directory Length Reached?
    bge     end_get_directory_name
    cmp     W25,    #46                            // .
    beq     end_get_directory_name
    strb    W25,    [sp, X9]
    add     X9,     X9,     #1
    add     X23,    X23,    #1
    b       get_directory_name
end_get_directory_name:
    mov     X0,     #95                            // _
    strb    W0,     [sp, X9]
    add     X9,     X9,     #1
    mov     X0,     #102                           // f
    strb    W0,     [sp, X9]
    add     X9,     X9,     #1
    mov     X0,     #103                           // g
    strb    W0,     [sp, X9]
    add     X9,     X9,     #1
    mov     X0,     #104                           // h
    strb    W0,     [sp, X9]
    add     X9,     X9,     #1
    mov     X0,     #47                            // /
    strb    W0,     [sp, X9]
    add     X9,     X9,     #1
loop_I:
    // Remove Last File
    mov     X1,     X7                             // Get The Last "Filename" In X7
    mov     X23,    #0
    mov     X25,    X9                             // Save The Start Of Filename
loop_II:
    cmp     X23,    #7                             // Filename Cannot Be Greater Than 1000000.fgh
    bge     end_loop_II
    cmp     X1,     #0
    ble     end_loop_II
    mov     X2,     #10
    udiv    X3,     X1,     X2
    mul     X4,     X3,     X2
    sub     X5,     X1,     X4
    add     X6,     X5,     #48
    strb    W6,     [sp, X9]
    add     X9,     X9,     #1
    add     X23,    X23,    #1
    mov     X1,     X3
    b       loop_II
end_loop_II:
    sub     X26,    X9,     #1                     // Save End Of Filename
    mov     X0,     #46                            // .
    strb    W0,     [sp, X9]
    add     X9,     X9,     #1
    mov     X0,     #102                           // f
    strb    W0,     [sp, X9]
    add     X9,     X9,     #1
    mov     X0,     #103                           // g
    strb    W0,     [sp, X9]
    add     X9,     X9,     #1
    mov     X0,     #104                           // h
    strb    W0,     [sp, X9]
    add     X9,     X9,     #1
    mov     X0,     #0                             // Null Terminator
    strb    W0,     [sp, X9]
reverse_filename:
    cmp     X25,    X26
    bge     end_reverse_filename
    ldrb    W27,    [sp, X25]                      // Load From The Beginning
    ldrb    W28,    [sp, X26]                      // Load From The End
    // Swap
    strb    W27,    [sp, X26]                      // Store Value At The Beginning To The End
    strb    W28,    [sp, X25]                      // Store Value At The End To The Beginning
    add     X25,    X25,    #1
    sub     X26,    X26,    #1
    b       reverse_filename
end_reverse_filename:
    // Remove File - unlink
    add     X0,     sp,     #3
    bl      _unlink
    bcs     _error_cleaning_up
    add     sp,     sp,     #32
    // Close Directory
    mov     X0,     X20
    mov     X16,    #6
    svc     0
    mov     X0,     #0                             // No Errors
_end_program:
    // Exits
    mov     X16,    #1
    svc     0
