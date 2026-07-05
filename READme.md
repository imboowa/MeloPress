# MeloPress
MeloPress is a project in ARM Assembly that compresses a file (text file) basing on its bytes. It gets 4 bytes (A,T/U,G,C) and compresses them into 1 byte by using 2-bit compression--this involves getting the first byte and putting only 2-bits of it into the first lower section of a byte and continue till 4 kinds of 2-bit pairs are into that byte hence 4 bytes have been packed into 1 byte. This on average gives a drastic reduction in file size. I am adopting this project into DNAGenre--just like I did with Decode--so that DNAGenre can compress and decompress DNA/RNA files.


# About
1. Works on valid **.txt** files (Check Format Section).
2. Only **@ or user's (your) character**, **\n**, **A**, **T**, **G**, **C**, and **U** are valid characters.
3. A file header that influences crucial program decisions.
4. Achieves a drastic reduction in file size on average.
5. Uses bits to compress the data.
6. Can only work on a 2KB-sized file.


# Bugs
1. AACC bits are similar to the newline character's bits
```
    cmp     W0,     #10                             // ascii code for newline character
    beq     _handle_special_char
```
**Problem**
/
Incase--in an uncompressed file--a line like `...AACC\n` is being worked on, AACC--4 bytes--is being packed into 1 byte. Those bits are fully similar to the bits in a newline character. This causes chaos in the compressed file which later on affects decompression.
/
In an uncompressed file
```
@
GCTCGATAGAGTCCAGATCCATCAGACAGGGAATATATTACAGATACAGGGAGGTAGAGAAACC
```
Result after compression
```
@
ÊƒÕ£»¸åH¸ÙÃ

```
Result after decompression
```
@
GCTCGATAGAGTCCAGATCCATCAGACAGGGAATATATTACAGATACAGGGAGGTAGAGA

```
**Solution**
/
As you can tell, the output is not alike the original one which means that we are getting incoherent decompressed data back. A new alternative was concocted--by letting the compressor have this bug we can fix this in the decompressor by using `@` as a marker. `@` is a marker meaning that the decompressor checks 1 byte behind the "newline character" and 1 byte infront looking for `@`. If it finds `@`, it allows a newline character to appear. If it does not find `@` infront and back, a newline is not allowed to appear.
With this section of code being called whenever a newline claims to be present--even though it is AACC--it can make wise decisions based on the `@`.
```
_handle_special_incident_1:
    // checking backward
    sub     X1,     X1,     #1
    cmp     X1,     #0
    blt     _write
    ldrb    W5,     [sp, X1]                        // load byte that is behind
    add     X1,     X1,     #1                      // reinstate overall counter - X1
    cmp     W5,     #64                             // @
    beq     _handle_special_char                    // allows newline char to appear behind
    // checking forward
    add     X1,     X1,     #1
    cmp     X1,     X22
    bge     _write
    ldrb    W5,     [sp, X1]                        // load byte that is ahead
    sub     X1,     X1,     #1                      // reinstate overall counter - X1
    cmp     W5,     #64                             // @
    bne     loop                                    // does not allow newline char to appear infront
    b       _handle_special_char                    // allows newline char to appear behind
```


2. TAAA bits are similar to the @ character's bits
/
```
    cmp     W2,     #64                             // @
    beq     _handle_special_character
```
**Problem**
/
In an uncompressed file with this `...TAAA`, the bits of `TAAA` are fully similar to the bits in `@`. If this file is compressed, the decompressor will think this `@` is a marker and not decompress it.
/
uncompressed file
```
@
GTTACACAAGGATCGCTACAGATATCGGTACGCTAAATATCGCGCCTTAGTAGAGTCGAGTAAA

```
/
compressed file
```
@
‘à<nHƒoKêª•4Õ≥@

```
Note: Since in the program every `@` is treated as a special character not to be decompressed--a marker--the output from the decompressor will not be congruent with the original file data.
/
decompressed file
```
@
GTTACACAAGGATCGCTACAGATATCGGTACGCTAAATATCGCGCCTTAGTAGAGTCGAG@

```
**Solution**
/
The program can be reprogrammed to only show a `@` only when there is a newline character right after the `@` like `...@\n`. This enforces all occurrences of `@` without a newline character proceeding them to be utterly decompressed.
/
Note: In such a scenario like `...TAAA\n`, using `@` as a marker--like this `...TAAA@\n`--during such a scenario is a brilliant move. This is because: the `@` is a special character which will not trigger the error asserting invalid character; the `@` is a marker and using it here acts as a "newline blocker"--meaning that the program checks forward one byte and finds no newline which decompresses that `@`--allowing the preceeding `@` to be decompressed.
/
```
_handle_special_incident_2:
    // checking backward
    sub     X1,     X1,     #1
    cmp     X1,     #0
    blt     _write
    ldrb    W5,     [sp, X1]                        // load byte that is ahead
    add     X1,     X1,     #1                      // reinstate overall counter - X1
    cmp     W5,     #10                             // newline character
    beq     _handle_special_char                    // allows @ char to appear infront
    // checking forward
    add     X1,     X1,     #1
    cmp     X1,     X22
    bge     _write
    ldrb    W5,     [sp, X1]                        // load byte that is ahead
    sub     X1,     X1,     #1                      // reinstate overall counter - X1
    cmp     W5,     #10                             // newline character
    bne     loop                                    // does not allow @ char to appear behind
    b       _handle_special_char                    // allows @ char to appear behind
```
Note: Checking only 1 byte forward is a brilliant way to handle this bug because in suh a scenario below, checking forward assures `...TAAA...` is decompressed. Checking forward and back is ruining for this scenario.
```
@
TAAA...
```


3. Mixing DNA and RNA nucleotides in a file
```
GUCATGGG
```
**Problem**
/
In this scenario, the DNA and RNA have mixed up into a file. Integrating a peice of code--like the one below--makes compression and decompression easier.
```
for_T:

    cmp     X23,    #1                              // is program already in RNA mode
    beq     _end_program

```
```
for_U:

    cmp     X23,    #0                              // is program already in DNA mode
    beq     _end_program

```
**Solution**
/
By checking modes, the program makes sure it is dealing with one mode and not two-mixed up modes. If two modes appear mixed up then the program stops executing and exits.
/

4. File with length indivisible by 4
/
**Problem**
/
In a scenario like this `...GCA\n` whereby the length is 3. The program wants 4 bytes so that it can pack those 4 bytes into 1 byte using 2-bit compression. Indivisible file lengths cause trouble to the program flow hence if an indivisible file length happens, the program does not compress that indivisible-file-length file.
/
**Solution**
/
If during compression and the compressor does not pack or compress 4 bytes into 1 byte then it exits with error code 3 (Check Format - Error Codes)
/

# Format
1. Recommended Format
/
This is recommended for input to **Prepress**.
```
@
GCTAGATCCTAGATCCTAGGCGACCGTGTTGA
@
CTAGCTACTACTCTGATCCTAGCTACGACTCT
@
GTGTGTGCGCATTGAGCGACGTGTGATCCTAG
```
This is recommended for input to **Postpress**.
```
@
‰∆ìO≤∑\
@
ìíIúi9,ô
@
›ﬁ·s≤›∆ì
```


2. File Header Bits
/
A file header that contains **0000000-0** whereby bit 0 indicates whether it is a DNA or RNA file. When it is an RNA file, the file header is **0000000-1** and when it is a DNA file it is **0000000-0**.
```
00000000: 0140 0ad8 0a                             .@...
```
```
00000000: 0040 0ad8 0a                             .@...
```
As you can tell, there is a file header which indicates DNA if it is **00** or RNA if it is **01**.
/

3. An Example Walkthrough
/
The **40** is the `@`, **0a** is the newline character, **d8** is the byte with **GUCA** packed into it if the file header has **01** or is the byte with **GTCA**packed into it if the file header has **00**, and ends with **0a** as the newline character.
/
compressed file
```
@
ÿ

```
This is a total of 5 bytes of file size.
/
original-uncompressed file
```
@
GUCA

```
This is a total of 7 bytes of file size.
/
/
Note: The `@` is unnecessary in this scenario because `@` is a marker that allows a newline character to appear. (Check Bug Section - AACC bits are similar to the newline character's bits)
/

4. Special Characters
/
A special character--**a @ (or user's [your] chosen character) and a newline character**--are the only special characters considered valid characters in the compression process. In the decompression process, invalid characters' bits are considered hence weird output with invalid characters to decompressor hence for expected output use the **recommended format** respectively.
/
/
Note: `@` could be any other character as long as this character of user's (your) choice is not a byte that will appear in user's (your) DNA or RNA data in file. Remember `@` or user's (your) character is a marker--a character that is going to enable the decompressor detect when to put a newline and when not to do so.
/

5. Error Codes
/
Success code **0** means that the program ran successfully without any error.
/
Error code **1** means that the program has DNA and RNA nucleotides in it.
/
Error code **2** means that the program has invalid characters. (Check About Section - 2)
/
Error code **3** means that the program's last bytes are indivisible by 4.
/
/
Note: Let me know if anyone (users) would prefer these error codes injected into the file header's bits or returned codes form the program. Let me know what is more convenient.
/

6. Invalid Characters
/
Characters not **A, T, C, G, U, @, and the newline character** are considered invalid character in this program. If any invlaid character is found, the program exits immediately and returns error code 2 that signifies the file to be compressed has invalid character(s) (Check Format Section - Error Codes).
/

# Tech Stack
```
Apple's Xcode - Code Editor
ChatGPT - AI Assistent
```


# Contributing
```
If you are interested in improving or upgrading this project even though you are a beginner or expert,
please feel free to contact me through my contacts in the contacts section.
```


# Copyright
```
If anyone wants to use this project for their project(s), education or work, please do freely.
Please feel at ease to either star the project or fork it just to show an appreciation
(It is optional to star or fork).
```


# Contact
```
It is very convenient to reach out to me through these contacts below because I can answer
within minutes.
```
LinkedIn - [My LinkedIn](https://www.linkedin.com/in/imboowa/)
