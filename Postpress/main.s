.global     _main


_main:
    // Get User's Commandline Arguments
    mov     X17,    X0                              // argc - How Many Commandline Arguments
    cmp     X17,    #3
    beq     _handle_standalone_decompression
    cmp     X17,    #2
    bne     _commandline_argument_error
    // No Errors - Proceed With Chunk Folder Decompression
    // Skip argv[0] - Filename - Get User Requested File argv[1] Or [X1, #8]
    ldr     X9,     [X1, #8]                        // argv - (char **) Pointer To A String Array
    mov     X8,     #1                              // Activates - Chunk Folder Decompression
    b       _check_file_header


_handle_standalone_decompression:
    mov     X8,     #0                              // Deactivates - Chunk Folder Decompression
    // Check Second Commandline Argument
    ldr     X9,     [X1, #8]
    ldrb    W2,     [X9, #0]                        // Expecting -
    ldrb    W3,     [X9, #1]                        // Expecting s
    cmp     W2,     #45                             // -
    bne     continue_checking_third_argument        // Try Checking The Third Argument
    cmp     W3,     #115                            // s
    beq     continue_with_standalone_decompression
    b       _standalone_decompression_error
    // Check Third Commandline Argument
continue_checking_third_argument:
    ldr     X9,     [X1, #16]
    ldrb    W2,     [X9, #0]                        // Expecting -
    ldrb    W3,     [X9, #1]                        // Expecting s
    cmp     W2,     #45                             // -
    bne     _standalone_decompression_error
    cmp     W3,     #115                            // s
    bne     _standalone_decompression_error
    ldr     X9,     [X1, #8]                        // If Third Argument Is The Flag Then Second Argument Is The Filename
    b       _check_file_header
continue_with_standalone_decompression:
    ldr     X9,     [X1, #16]                       // If Second Argument Is The Flag Then Third Argument Is The Filename
    b       _check_file_header
_commandline_argument_error:
    mov     X0,     #1                              // Error Receiving Commandline Arguments
    b       _end_program
_standalone_decompression_error:
    mov     X0,     #2                              // Standalone Decompression Error
    b       _end_program


_check_file_header:
    sub     sp,     sp,     #16
    // Is File Compressed Or Uncompressed
    mov     X0,     X9
    mov     X1,     #0x0000                         // Read Only
    mov     X2,     #0
    mov     X16,    #5                              // open
    svc     0                                       // X0 - Already Filled In As File Descriptor
    bcs     _file_error                             // Branch To _file_error If Carry Flag Is Set
    mov     X19,    X0                              // Store File Descriptor - Globally
    mov     X1,     sp
    mov     X2,     #4
    mov     X16,    #3                              // read
    svc     0
    bcs     _file_error
    cmp     X0,     #0                              // Empty File
    beq     _end_program                                   // X0 Is Already 0 Hence Success In Program - Trick
    // Check Header
    ldrb    W0,     [sp, #0]                        // Expect #
    cmp     W0,     #0b00100011
    bne     _not_compressed_error
    ldrb    W1,     [sp, #1]                        // Expect H
    cmp     W1,     #0b01001000
    bne     _not_compressed_error
    ldrb    W2,     [sp, #2]                        // Expect 9
    cmp     W2,     #0b00111001
    bne     _not_compressed_error
    ldrb    W3,     [sp, #3]                        // File Header
    mov     W28,    W3                              // Store File Header For Future Use Like Decompression
    mov     W4,     #0b00000010
    and     W5,     W3,     W4
    cmp     W5,     #0b00000010                     // Is File Already Compressed
    bne     _not_compressed_error
    mov     W4,     #0b00000100                     // Reusage Of Variables = Overwriting
    and     W5,     W3,     W4
    cmp     W5,     #0b00000100                     // Is File A .fgh File
    bne     _not_fgh_file_error
    cmp     X8,     #1                              // Is Postpress In Chunk Folder Decompression
    beq     check_head_file
    b       skip_1
check_head_file:
    // Do This Only In Chunk Folder Decompression
    mov     X4,     #0b01000000
    and     W5,     W3,     W4
    cmp     W5,     #0b01000000                     // Is File A Head File - First File To Be Compressed
    bne     _file_error
skip_1:
    // Set File Pointer Back To Beginning - lseek - Because Of Read
    // MeloPress Is Reading The File Header Here Too To Prevent Buffer Misalignment But MeloPress Will Skip The Header During Decompression
    mov     X0,     X19
    mov     X1,     #0
    mov     X2,     #0
    mov     X16,    #199                            // lseek
    svc     0
    b       _locate_folder
_file_error:
    mov     X0,     #3                              // Error Opening Or Reading Compressed File
    add     sp,     sp,     #16
    b       _end_program
_not_compressed_error:
    mov     X0,     #4                              // File Is Not Formatted For Decompression
    add     sp,     sp,     #16
    b       _end_program
_not_fgh_file_error:
    mov     X0,     #5                              // Not A .fgh File - User Could Just Change The File Extension
    add     sp,     sp,     #16
    b       _end_program

_locate_folder:
    add     sp,     sp,     #16
    sub     sp,     sp,     #32
    // Locate Directory Where Compressed Chunks Are Stored
    mov     X0,     #0                              // Number Of Characters In The Foldername
    mov     X1,     #0
    mov     X3,     #0                              // Boolean Value That Helps To Know If First / Has Been Skipped
loop_A:
    cmp     X1,     #16                             // Capping Foldername To 2 Characters (./) + 10 Characters + 4 Chars (_fgh)
    bge     open_directory
    ldrb    W2,     [X9, X0]                        // Load Byte From Filename In X9
    cmp     W2,     #47                             // /
    beq     check_index_position
continue_1:
    strb    W2,     [sp, X1]
    add     X0,     X0,     #1
    add     X1,     X1,     #1
    b       loop_A
check_index_position:
    cmp     X3,     #1
    beq     open_directory
    mov     X3,     #1                              // Update Index - X0 Position
    b       continue_1
open_directory:
    // Add Null Terminator At The End
    mov     X0,     #0
    strb    W0,     [sp, X1]
    // Open Directory With open To Get Directory FD
    add     X0,     sp,     #0
    mov     X1,     #0x0000                         // Read Only
    mov     X16,    #5                              // open
    svc     0
    bcs     _error_opening_directory
    mov     X20,    X0                              // Save Directory Descriptor - Globally
    cmp     X8,     #1                              // Is Postpress In Chunk Folder Decompression
    beq     start_chunk_folder_decompression
    b       _get_user_file_choice
start_chunk_folder_decompression:
    add     sp,     sp,     #32
    mov     X7,     #1                              // Set X7 To Start With First File - Presumably Head File
    b       _open_current_file
_error_opening_directory:
    mov     X0,     #6                              // Error Opening Directory
    add     sp,     sp,     #32
    b       _end_program


_get_user_file_choice:
    add     sp,     sp,     #32
    mov     X0,     #0
    mov     X3,     #0                              // Not Inside File Path
loop_I:
    ldrb    W1,     [X9, X0]
    cmp     W1,     #46                             // .
    beq     temp_1
continue_3:
    add     X0,     X0,     #1
    b       loop_I
temp_1:
    cmp     X3,     #0
    beq     sub_temp_1
    mov     X11,     #0                              // Will Store Final Number In Integer Form
    mov     X12,    #10
    mov     X13,    #1                              // Positional Weight (1, 10, 100 ... ) - Place Values
    b       backtrack_1
sub_temp_1:
    mov     X3,     #1                              // Inside File Path
    b       continue_3
backtrack_1:
    sub     X0,     X0,     #1
    ldrb    W1,     [X9, X0]
    cmp     W1,     #47                             // /
    beq     end_backtrack_1
    cmp     W1,     #48                             // 0
    blt     _error_getting_user_file_choice
    cmp     W1,     #57                             // 9
    bgt     _error_getting_user_file_choice
    sub     W1,     W1,     #48                     // To Get The Integer
    uxtw    X1,     W1                              // Pad 32-Bit Register With Zeroes
    mul     X1,     X1,     X13                     // Match Current Integer To The Place Value
    add     X11,    X11,    X1
    mul     X13,    X13,    X12                     // Move To Next Place Value
    b       backtrack_1
end_backtrack_1:
    mov     X7,     X11                             // Store Current File Into X7 To Be Opened Later And Decompressed
    b       _open_current_file
_error_getting_user_file_choice:
    mov     X0,     #7                              // Could Not Get User File Choice Error
    b       _end_program


_open_current_file:
    sub     sp,     sp,     #64
    cmp     X8,     #1                              // Is Chunk Folder Decompression On
    beq     end_decompression_2
    cmp     X7,     X6
    bgt     end_decompression_1
skip_2:
    mov     X4,     X7                              // Copy Of Files Created Counter
    mov     X3,     #7                              // 7 Is The Longest Filename - 1000000.fgh
number_into_ascii:
    cmp     X3,     #0
    ble     open_file_2
    cmp     X4,     #0
    ble     open_file_2
    mov     X0,     #10
    udiv    X1,     X4,     X0
    mul     X2,     X1,     X0
    sub     X0,     X4,     X2                      // The Reminder
    mov     X4,     X1                              // Update X4 With "Cut Off" Portion
    add     X0,     X0,     #48                     // Getting The Ascii Version Of The Reminder
    strb    W0,     [sp, X3]
    sub     X3,     X3,     #1
    b       number_into_ascii
open_file_2:
    add     X3,     X3,     #1                      // Because X3 Was Pushed To Unknown Data (Garbage)
    mov     X5,     X3                              // Save X3
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
    mov     X2,     #0x0000                         // O_RDONLY
    mov     X3,     #504                            // Owner - rwx And Group - rwx And Others - 0
    mov     X16,    #463                            // openat
    svc     0
    bcs     end_decompression_1
    mov     X21,    X0                              // Save File Descriptor
    // Skip Update Process Because When Decompressing One File - No Need To Update File Magic And File Header Info Since It Is Already Obtained
    cmp     X8,     #1
    bne     skip_3
    // Update File Magic And File Header
    add     X1,     sp,     #32
    mov     X2,     #4
    mov     X16,    #3                              // read
    svc     0
    bcs     _file_error
    cmp     X0,     #0                              // Empty File
    beq     _end_program                                   // X0 Is Already 0 Hence Success In Program - Trick
    // Check Header
    ldrb    W0,     [sp, #32]                       // Expect #
    cmp     W0,     #0b00100011
    bne     _not_compressed_error
    ldrb    W1,     [sp, #33]                       // Expect H
    cmp     W1,     #0b01001000
    bne     _not_compressed_error
    ldrb    W2,     [sp, #34]                       // Expect 9
    cmp     W2,     #0b00111001
    bne     _not_compressed_error
    ldrb    W3,     [sp, #35]                       // File Header
    mov     W28,    W3                              // Store File Header For Future Use Like Decompression
    mov     W4,     #0b00000010
    and     W5,     W3,     W4
    cmp     W5,     #0b00000010                     // Is File Already Compressed
    bne     _not_compressed_error
    mov     W4,     #0b00000100                     // Reusage Of Variables = Overwriting
    and     W5,     W3,     W4
    cmp     W5,     #0b00000100                     // Is File A .fgh File
    bne     _not_fgh_file_error
skip_3:
    // Set File Pointer Back To Beginning - lseek - Because Of Read
    // Postpress Is Reading The File Header Here Too To Prevent Buffer Misalignment But Postpress Will Skip The Header During Decompression
    mov     X0,     X21
    mov     X1,     #0
    mov     X2,     #0
    mov     X16,    #199                            // lseek
    svc     0
    cmp     X8,     #1                              // Is Postpress In Chunk Folder Decompression
    beq     _make_output_file_2
    b       _make_output_file_1
end_decompression_1:
    mov     X0,     #0                              // Standalone Decompression Was Successfull
    add     sp,     sp,     #64
    b       _end_program
end_decompression_2:
    ldr     X1,     =1000000
    cmp     X7,     X1
    ble     skip_2
    mov     X0,     #0                              // Chunk Folder Decompression Was Successfull
    add     sp,     sp,     #64
    b       _end_program


_make_output_file_1:
    // Prepare Output Filename Fully - Manipulate Current Filename
    mov     X1,     #46                             // .
    strb    W1,     [sp, #8]
    mov     X1,     #104                            // h
    strb    W1,     [sp, #9]
    mov     X1,     #103                            // g
    strb    W1,     [sp, #10]
    mov     X1,     #102                            // f
    strb    W1,     [sp, #11]
    mov     X1,     #0                              // Null Terminator
    strb    W1,     [sp, #12]
    // open Filename In Current Directory
    add     X0,     sp,     X5
    mov     X1,     #0x0602                         // O_RDWR | O_CREAT | O_TRUNC
    mov     X2,     #0744                           // Ownwer - rwx And Group - r And Others - r
    mov     X16,    #5
    svc     0
    bcs     _error_making_output_file
    mov     X22,    X0                              // Save Output File Descriptor
    add     sp,     sp,     #64
    b       _persistent_variables                   // Starts Decompression


_make_output_file_2:
    // Locate The Folder First
    mov     X0,     #0                              // Number Of Characters In The Foldername
    mov     X1,     #16
    mov     X3,     #0                              // Bool Value That Helps To Know If First / Has Been Skipped Hence Start Collecting Filename
loop_A_1:
    cmp     X1,     #26                             // Capping Foldername To 10 Characters - No _fgh
    bge     end_loop_A_1
    ldrb    W2,     [X9, X0]                        // Load Byte From Filename In X9
    cmp     W2,     #47                             // /
    beq     check_index_position_1
    cmp     W2,     #95                             // _
    beq     check_index_position_2
    cmp     X3,     #1
    bne     temp_2
    b       continue_5
temp_2:
    add     X0,     X0,     #1
    b       loop_A_1
continue_5:
    strb    W2,     [sp, X1]
    add     X0,     X0,     #1
    add     X1,     X1,     #1
    b       loop_A_1
check_index_position_1:
    mov     X3,     #1
    add     X0,     X0,     #1
    b       loop_A_1
check_index_position_2:
    add     X0,     X0,     #1
    ldrb    W2,     [X9, X0]
    cmp     W2,     #102                            // f
    beq     keep_going_1
    sub     X0,     X0,     #1                      // Reinstate X0
    ldrb    W2,     [X9, X0]
    b       continue_5
keep_going_1:
    add     X0,     X0,     #1
    ldrb    W2,     [X9, X0]
    cmp     W2,     #103                            // g
    beq     keep_going_2
    sub     X0,     X0,     #2                      // Reinstate X0
    ldrb    W2,     [X9, X0]
    b       continue_5
keep_going_2:
    add     X0,     X0,     #1
    ldrb    W2,     [X9, X0]
    cmp     W2,     #104                            // h
    beq     end_loop_A_1
    sub     X0,     X0,     #3
end_loop_A_1:
    // Prepare Filename
    mov     X2,     #46                             // .
    strb    W2,     [sp, X1]
    add     X1,     X1,     #1
    mov     X2,     #104                            // h
    strb    W2,     [sp, X1]
    add     X1,     X1,     #1
    mov     X2,     #103                            // g
    strb    W2,     [sp, X1]
    add     X1,     X1,     #1
    mov     X2,     #102                            // f
    strb    W2,     [sp, X1]
    add     X1,     X1,     #1
    mov     X2,     #0                              // Null Terminator
    strb    W2,     [sp, X1]
    // open Filename In Current Directory
    add     X0,     sp,     #16
    mov     X1,     #0x020A                         // O_RDWR | O_CREAT | O_APPEND
    mov     X2,     #0744                           // Ownwer - rwx And Group - r And Others - r
    mov     X16,    #5
    svc     0
    bcs     _error_making_output_file
    mov     X22,    X0                              // Save Output File Descriptor
    add     sp,     sp,     #64
    b       _persistent_variables                   // Starts Decompression
_error_making_output_file:
    mov     X0,     #8                              // Error Making Output File Or Error Closing Output File
    add     sp,     sp,     #64
    b       _end_program


_persistent_variables:
    mov     X6,     #0                              // Helps Postpress Know When To Format And Not To Format Data
    mov     X5,     #0b00000001
    and     W5,     W28,    W5                      // Get File Sequnce Type From File Header
    mov     X17,    #0b00001000
    and     W17,    W28,    W17                     // Is File Length Indivisible By 4
    // Make Sure File Pointer Is At The Start - lseek
    mov     X0,     X21
    mov     X1,     #0
    mov     X2,     #0
    mov     X16,    #10
    svc     0
_start_decompression:
    sub     sp,     sp,     #4096
    add     X23,    sp,     #0                      // Input Buffer
    mov     X24,    #4                              // Skip File Magic And File Header
    add     X25,    sp,     #2048                   // Output Buffer
    mov     X26,    #3                              // Reserve Memory For @@ And \n
_read_again:
    // Read Compressed Data
    mov     X0,     X21
    mov     X1,     X23
    mov     X2,     #2047                           // \n At The End
    mov     X16,    #3
    svc     0
    bcs     _reading_input_file_error
    cmp     X0,     #0
    ble     _prepare_exit
    mov     X27,    X0                              // Bytes Read
_start:
    cmp     X24,    X27
    bge     continue_2
    mov     X2,     #0                              // Bit Decompression Counter
    ldrb    W0,     [X23, X24]                      // Current Byte
    mov     W3,     #0b11000000                     // Bit Mask
loop:
    cmp     X2,     #4                              // Is Program Done With last Bit
    bge     end_loop
    and     W4,     W0,     W3
    cmp     W4,     #0x00                           // Then It Is A
    beq     handle_A
    cmp     W4,     #0x40                           // Then It Is T
    beq     handle_T
    cmp     W4,     #0xC0                           // Then It Is G
    beq     handle_G
    cmp     W4,     #0x80                           // Then It Is C
    beq     handle_C
    b       end_loop                                // Implicitly Skips Invalid Characters - Just In Case - Not Needed
handle_A:
    mov     W4,     #65
    // Check Indivisibility
    cmp     W17,    #0b00001000
    beq     _handle_indivisibility
    b       _write_to_buffer
handle_T:
    cmp     W5,     #1                              // Is RNA Mode On
    beq     handle_U
    mov     W4,     #84
    b       _write_to_buffer
handle_G:
    mov     W4,     #71
    b       _write_to_buffer
handle_C:
    mov     W4,     #67
    b       _write_to_buffer
handle_U:
    mov     W4,     #85
    b       _write_to_buffer
end_loop:
    add     X24,    X24,    #1
    b       _start
_write_to_buffer:
    strb    W4,     [X25, X26]
    add     X26,    X26,    #1
    add     X2,     X2,     #1                     // Increment Bit Decompression Counter By 1
    lsl     W0,     W0,     #2                     // Shift The Current Byte By 2 Bits
    mov     X18,    #4
    sub     X1,     X27,    #4
    mul     X1,     X1,     X18
    mov     X18,    X26
    sub     X18,    X18,    #3
    cmp     X18,    X1                             // Check Bounds
    blt     loop
continue_2:
    cmp     X8,     #1
    beq     _finalize_current_decompression_state
    cmp     X6,     #1
    beq     write_1
    b       _finalize_current_decompression_state
_finalize_current_decompression_state:
    // Get The Bit That Indicates A Segment File
    mov     X0,     #0b10000000
    and     W3,     W28,    W0
    cmp     W3,     #0b10000000
    beq     _append_decompressed_data
    // Format Decompressed Data
    mov     X0,     #64                            // @
    mov     X1,     #10                            // Newline - \n
    strb    W0,     [X25, #0]
    strb    W0,     [X25, #1]
    strb    W1,     [X25, #2]
    strb    W1,     [X25, X26]
    add     X26,    X26,    #1                     // Add Space In Output Buffer For Newline Character
    mov     X6,     #1
    b       write_1


_append_decompressed_data:
    mov     X0,     #10                            // Newline - \n
    strb    W0,     [X25, X26]
    add     X26,    X26,    #1                     // Add Space In Output Buffer For Newline Character
    mov     X6,     #1
    // Writes To Disk - For Segment File Only
    sub     X26,    X26,    #3                     // Remove Offset That Is Due To Formatting
    mov     X0,     X22
    add     X1,     X25,    #3
    mov     X2,     X26
    mov     X16,    #4
    svc     0
    mov     X24,    #0
    mov     X26,    #0
    b       _read_again


write_1:
    // Writes To Disk And Exits (When Read Returns 0)
    mov     X0,     X22
    mov     X1,     X25
    mov     X2,     X26
    mov     X16,    #4
    svc     0
    mov     X24,    #0
    mov     X26,    #0
    b       _read_again
_handle_indivisibility:
    // Is Program At Last Bit
    sub     X1,     X27,    #1                     // Is Postpress At Last Bit
    cmp     X24,    X1
    bne     _write_to_buffer
get_acceptable_length:
    mov     X1,     #0b00110000
    and     W1,     W28,    W1
    cmp     W1,     #0b00000000                    // No Bytes Left At The End Due To File Length's Divisibility By 4
    beq     bytes_at_end_1
    cmp     W1,     #0b00010000                    // 1 Byte At The End Due To Indivisibility
    beq     bytes_at_end_2
    cmp     W1,     #0b00100000                    // 2 Bytes At The End Due To Indivisibility
    beq     bytes_at_end_3
    cmp     W1,     #0b00110000                    // 3 bytes At The End Due To Indivisibility
    beq     bytes_at_end_4
bytes_at_end_1:
    mov     X18,    #0
    b       handle_bytes_at_end
bytes_at_end_2:
    mov     X18,    #1
    b       handle_bytes_at_end
bytes_at_end_3:
    mov     X18,    #2
    b       handle_bytes_at_end
bytes_at_end_4:
    mov     X18,    #3
handle_bytes_at_end:
    mov     X1,     #4
    sub     X1,     X1,     X18
    cmp     X2,     X1
    bge     _write_to_buffer
    // Do Not Decompress For 'A'
    add     X2,     X2,     #1
    lsl     W0,     W0,     #2
    b       loop
_reading_input_file_error:
    add     sp,     sp,     #4096                  // Free Buffer
    // Set Dangling Pointers To 0
    mov     X23,    #0
    mov     X25,    #0
    // Close Input File
    mov     X0,     X21
    mov     X16,    #6
    svc     0
    // Close Output File
    mov     X0,     X22
    mov     X16,    #6
    svc     0
    bcs     _error_making_output_file              // Informs User That There Was An Issue With The Output File
    mov     X0,     #9                             // Error Reading Input (Compressed) File
    b       _end_program
_prepare_exit:
    add     sp,     sp,     #4096                  // Free Buffer
    // Set Dangling Pointers To 0
    mov     X23,    #0
    mov     X25,    #0
    // Close Current File To Prevent Filling The File Descriptor Pool - Leave Space For Next And Other File Descriptors In The FD Pool
    mov     X0,     X21
    mov     X16,    #6
    svc     0
    // Also The Output File Descriptor Is Opened A Lot - Close It On Every Open
    mov     X0,     X22
    mov     X16,    #6
    svc     0
    bcs     _error_making_output_file              // Informs User That There Was An Issue With The Output File
    mov     X0,     #0                             // No Errors - If close() Is Successful
    cmp     X8,     #1                             // Is Chunk Folder Decompression On
    bne     _end_program
    add     X7,     X7,     #1                     // Increment Files - To Be Decompressed Like 2.fgh
    b       _open_current_file
_end_program:
    mov     X16,    #1
    svc     0
