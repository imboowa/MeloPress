# MeloPress
MeloPress is a project in ARM Assembly that compresses a file (DNA/RNA valid file). It gets 4 bytes (A,T/U,G,C) and compresses them into 1 byte by using 2-bit compression. This involves getting the first byte and putting only 2-bits of it into the first lower section of a byte and MeloPress continues till 4 kinds of 2-bit pairs are into that byte hence 4 bytes have been packed into 1 byte. This on average gives a drastic reduction in file size. I am adopting this project into [DNAGenre](https://github.com/imboowa/DNAGenre), just like I did with [Decode](https://github.com/imboowa/Decode), so that DNAGenre can compress and decompress valid DNA/RNA files.

# About
1. Works on validly formatted files (Check Format Section).
2. Only **@**,**A**, **T**, **G**, **C**, and **U** are valid characters during compression.
3. A file header for each read index that influences crucial program decisions.
4. Achieves a drastic reduction in file size on average for valid DNA/RNA files.
5. Uses bits to compress the data.

### Big Notes
a. This project was 35% AI and 65% me.

b. I built this project on a MacBook M2 Pro, 2022 and a MacBook M5 Pro.

c. This project runs on Apple Silicon based laptops like the M-Chips.

d. If you are familiar with Intel, Linux, Windows Assembly, please reach out to write this code in your expertise Assembly architecture.

e. When the input file is too large, MeloPress (Prepress) will break it down into separate read indexes in between reads. Prepress does this to retain useful information in the file header which is used during decompression.

f. This MeloPress is very fast when compressing and decompressing data compared to DNAGenre's MeloPress.

g. Here is the link to the DNAGenre app (works for only Apple Silicon or M-Chips): [DNAGenre Download](https://sites.google.com/view/dnagenre/dnagenre-home?pli=1&authuser=0#h.cfgyjm2azd2m)
h. Here is the link to the Github code for DNAGenre: [DNAGenre](https://github.com/imboowa/DNAGenre)

i. In case user (you) experience anomally behaviour in the created _fgh folder, Prepress can only remove files from 1.fgh to 1000000.fgh (included).
j. Any file NOT of this kind will NOT be touched (removed). In addition to this, if there is such behaviour in the _fgh folder, I recommend to reset (delete that _fgh folder) and re-run Prepress on user (your) target file.

# Bugs

### 1. Illegal input
Input like this does not meet the format section's requirements (See the Format Section).

### **a. No special character**

```
AGCT
```
When Prepress finishes compression on this kind of file input, Prepress starts to write the compressed data to output file. During write, write fails because Prepress needs the sprecial character (`@`) to create the output file for that current read index. Since this input does not have the special character, the output file will not be created but the compressed chunk folder is created.

### **b. Only a special character**

```
@
```
When Prepress encounters only a special character, since it creates an output file whenever it encounters a special character. Prepress will create a file and write only the file magic and file header.

### **Proof**
File layout: `00000000: 2348 3947                                #H9G`\
File Header: `01000111`\
Bit 6 (From the right; starting at index 0): `1` - this if the first compressed file.\
Bit 2 (From the right; starting at index 0): `1` - this is a `.fgh` file.\
Bit 1 (From the right; starting at index 0): `1` - this is a compressed file.\
Bit 0 (From the right; starting at index 0): `1` - this is an RNA file.

### **c. No starting special characer but data**

```
ATGC
@
```
Because Prepress had not written the compressed data anywhere due to no starting special character; Prepress will create a file at the next special character and write the previous data to the newly created output file. It will also add data that comes after the special character (if there is data after the specail character).

### **Proof**
File layout: `00000000: 2348 3946 1e                             #H9F.`\
File header: `01000110`\
Bit 0 (From the right; starting at index 0): `0` - this is a DNA file.\
`1e` - ATGC

**Note**: This also works for input like `@ATGC`.

### 2. Mixing DNA and RNA nucleotides in a file
```
@
GUCATGGG
```
### Problem
In this scenario, the DNA and RNA have mixed up into a file. Integrating a peice of code--like the one below--makes compression and decompression have the ability to respect file **sequence type**.

```
for_T:
    cmp     X26,    #1                              // Is Program Already In RNA Mode
    beq     _handle_mixed_modes
```

```
for_U:
    cmp     X26,    #0                              // Is Program Already In DNA Mode
    beq     _handle_mixed_modes
```

### **Solution**
By checking modes, the program makes sure it is dealing with one mode and not two-mixed up modes. If two modes appear mixed up then the program stops executing and exits with error code (8) and does not write anything to the output file due to the error.
#### Notes:
### **a) If file input to Prepress is:**
```
@
CGGG
```
The variable `X26` is by default at the value `2`. Since such input does not have `T` or `U` to trigger DNA or RNA respectively, MeloPress will treat the input as RNA.

### **Proof**
File layout: `00000000: 2348 3947 bf                             #H9G.`\
File Header: `01000111`\
Bit 0 (From the right; starting at index 0): `1` - which signifies RNA.
### **b. If file input to Prepress is:**
```
@
CGGGUT
```
Despite file having indivisible length by 4, Prepress still checks for mixed up modes. The outcome is still error code (8) and Prepress does not write anything to output file due to the error.
### **c. Even illegal input that violates format requirements is screened out:**
```
GUCATGGG
```
This input may violate format requirements but Prepress will screen this out as mixed modes with error code (8).

### 3. File with length indivisible by 4
### Problem
In a scenario like this `...GCA\n` whereby the length is 3. The program wants 4 bytes so that it can pack those 4 bytes into 1 byte using 2-bit compression. Indivisible file lengths cause trouble to the program flow. To counter this, I adopted the use of file headers which help in storing useful information for decompression. The file header can store infomation like if this file data's length was indivisible by 4.
### **Solution**
If the read index has an indivisble length (not divisible by 4), MeloPress will write the remainign bytes to the end of the file and indicate in the file header (the current file created where results of the current Read Index are stored) that this read index's data length was indivisble by 4.
#### Notes:
### **a. If file input is:**
```
@
CGG
```
There will be no error because Prepress handles indivisbility in file length.
### **Proof**
File layout: `00000000: 2348 397f 2f                             #H9./`\
File Header: `01111111`\
Bit 3 (From the right; starting at index 0): `1` - which means that the file length is indivisible by 4.\
Bit 4 and Bit 5 (From the right; starting at index 0): `11` - which means that **3** nucleotides are allowed at the end.

### 4. If folder name is not obtained or there is an error obtaining the folder name
Prepress will use the default convention to show the compressed chunk folder which is `_fgh`. 
### **Proof**
Folder layout: `_fgh	Postpress	Prepress	READme.md`

This could be triggered if Prepress is called like this: `./Prepress/main ./Prepress/test.txt`. Since Prepress does not have the ability to obtain the folder name from this kind of calling convention, it will use the default calling convention.

**Note**:
If user (you) run Prepress many times, it will store the compressed chunks in this folder during such situation. On round two, Prepress will clear `_fgh` and overwrite that preexisting information.
### **Proof**

### On Round One

| Column 1 | Column 2 |
| --- | --- |
| **Input**| @AGCT|
| **User (Your) Calling Convention In Terminal** | ./Prepress/main ./Prepress/test.txt |
| **\_fgh** |
|  |
| 1.fgh|
|  #H9F9 |
| **error code** |
| 0 |

### On Round Two

| Column 1 | Column 2 |
| --- | --- |
| **Input**| @AAAA|
| **User (Your) Calling Convention In Terminal** | ./Prepress/main ./Prepress/test.txt |
| **\_fgh** |
|  |
| 1.fgh|
| #H9G |
| **error code** |
| 0 |

### 5. If folder name was not obtained, the output file name will just be?
Prepress will use the defualt convention to show the output file of decompressed data which is `.hgf`.
### **Proof**
Folder layout: `_fgh	.	..	.DS_Store	.git	.hgf	Postpress	Prepress	READme.md`

This could be triggered if Postpress is called like this: `./Postpress/main ./_fgh/1.fgh`.

**Note**:
If user (you) run Postpress many times, it will just appennd the decompressed data to the output file (in this case `.hgf`).
### **Proof**

### On Round One

| Column 1 | Column 2 |
| --- | --- |
| **Input**| @AAAA|
|  |  @GCGG|
| **User (Your) Calling Convention In Terminal** | ./Postpress/main ./\_fgh/1.fgh |
| **\_fgh** |
|  |
| 1.fgh|
| #H9G  |
| 2.fgh |
| #H9Ô|
| **.hgf** |
|  |
|  |
| @@AAAA|
|  |
| @@GCGG|
| **error code** |
| 0 |

### On Round Two

| Column 1 | Column 2 |
| --- | --- |
| **Input**| @AAAA |
| | @GCGG|
|  | @TTTT |
| **User (Your) Calling Convention In Terminal** | ./Postpress/main ./\_fgh/1.fgh |
| **\_fgh** |
|  |
| 1.fgh|
| #H9G |
| 2.fgh |
| #H9Ô|
| 3.fgh |
| #H9U |
| **.hgf** |
|  |
|  |
| @@AAAA |
|  |
| @@GCGG |
|  |
| @@AAAA |
|  |
| @@GCGG |
|  |
| @@TTTT |
| **error code** |
| 0 |

### 6. If input has read indexes with empty data
Prepress will recognize read indexes without information. This means that if a read index was empty there is an empty file taking up that position. The reason I leave this feature is that during tests it was discovered that when Prepress disregards the empty read indexes, this violates the original pattern in the data.
### **Proof**

| Column 1 | Column 2 |
| --- | --- |
|  **Input**| @AAAA |
| | @|
|  | @GCGG|
| | @TTTT|
|  **User(Your) Calling Convention In Terminal** | ./Prepress/main ./Prepress/test.txt |
| **\_fgh** |  |
| 1.fgh | #H9G|
| 2.fgh | #H9 |
| 3.fgh | #H9Ô|
| 3.fgh | #H9U |
| **.hgf** |  |
| |  @@AAAA|
|  |  @@|
|  |  @@GCGG|
|  |  @@TTTT|
| **error code** | 0 |

### 7. Mixed data in input file
Prepress will check for DNA in RNA or RNA in DNA and exit with error code (8) if True. When the data starts as valid, there is a behaviour that is notable. When Prepress encounters an invalid section of the data, it will have compressed all the valid data to that point then it will stop (exit) compression without compressing that read index.
### **Proof**

| Column 1 | Column 2 |
| --- | --- |
|  **Input**|@AAAA  |
|  |  @|
|  |  @GCGG|
|  |  @TTTT|
|  |  @TUUT|
| **User (Your) Calling Convention In Terminal** |  ./Prepress/main ./Prepress/test.txt|
| **\_fgh** |  |
| 1.fgh | #H9G  |
| 2.fgh | #H9Ô |
| 3.fgh |  #H9U|
| 4.fgh | |
| **error code** | 8 |
| **User (Your) Calling Convention In Terminal** |  ./Postpress/main ./\_fgh/1.fgh |
| **O****utput** | @@AAAA |
|  |  @@GCGG|
|  |  @@TTTT|
| **error code** | 0 |

### 8. If one or more file headers are corrupted
Postpress will decompress all compressed chunk folder files. When it encounters a corrupted file header or file magic, it stops (exits) with error code (4).
### **Proof**

| Column 1 | Column 2 |
| --- | --- |
| **Input** | @AAAAA|
|  |  @|
|  |  @GCGG|
|  |  @TTTTTTT|
|  |  @TAAT|
|  |  @CGGCGA|
| **User (Your) Calling Convention In Terminal** | ./Prepress/main ./Prepress/test.txt |
| **\_fgh** |  |
| 1.fgh |  #H9_  |
| 2.fgh | #H9Ô |
| 3.fgh |  #H9>U|
| 4.fgh | #A |
| 5.fgh | #H9.æ |
| **error code** | 0 |
| **User (Your) Calling Convention In Terminal** | ./Postpress/main ./\_fgh/1.fgh |
| **Output** |  @@AAAAA|
|  |  @@GCGG|
|  |  @@TTTTTTT|
| **error code** | 4 |

### **Note**: If user (you) experiences error code 4, re-run Prepress to compress the input file again which resets everything.

### 9. Invalid characters
Invalid characters are skipped during compresssion, but there are behaviours to take note of.

### **Notes**:
a. Using another character for a special character instead of (@)
Prepress code only recognizes `@`  as the special character (the character that acts as a separactor and read index marker). Using any other special character like I did choose `#`.
Prepress will skip `#` and since there is no special character (this special character also helps Prepress to create a file for output). The final result is that there are no output files in the compressed chunk folder.
### **Proof**

| Column 1 | Column 2 |
| --- | --- |
| **Input** |  #AAAAA|
|  |  #|
|  |  #GCGG|
|  |  #TTTTTTT|
|  |  #TAAT|
|  |  #CGGCGA|
| **User (Your) Calling Convention In Terminal** | ./Prepress/main ./Prepress/test.txt |
| **\_fgh** |  |
| **error code** | 0 |
| **User (Your) Calling Convention In Terminal** | ./Postpress/main ./\_fgh |
| **Output** |  |
| **error code** | 3 |

### **b. Invalid characters in the input file**
If there are invalid characters in the input, they are skipped and Prepress will consider only valid characters even though they might be part of the invalid characters. This causes corruption of data too.
### **Proof**

| Column 1 | Column 2 |
| --- | --- |
| **Input** | There@ |
|  |  AAAAA|
|  |  is@|
|  |  invalid@|
|  |  GCGG|
|  |  data@|
|  |  TTTTTTT|
|  |  in@|
|  |  TAAT|
|  |  this@|
|  |  CGGCGA|
|  |  file|
| **User (Your) Calling Convention In Terminal** |  ./Prepress/main ./Prepress/test.txt |
| **\_fgh** |  |
| 1.fgh | #H9n@  |
| 2.fgh | #H9Ô |
| 3.fgh | #H9>U |
| 4.fgh | #H9A |
| 5.fgh | #H9.æ |
| **error code** | 0 |
| **User (Your) Calling Convention In Terminal** |  ./Postpress/main ./\_fgh/1.fgh |
| **Output** | @@TAAAAA |
|  |  @@GCGG|
|  |  @@TTTTTTT|
|  |  @@TAAT|
|  |  @@CGGCGA|
| **error code** | 0 |

### **Note**: You (user) can see that the first `T` was added to valid data yet it was part of the invalid data. Technically it is a valid character but this causes corruption. This leads to a conclusion that Prepress only compresses valid characters (A, T/U, G, C) and special characters (@).


# Format
### 1. Recommended Input Format - For **Prepress**

```
test_1.txt
```
```
@
A
@
AG
@
AGU
@
AGUG
@
AGUGC
@
AGUGCC
@
AGUGCCG
@
AGUGCCGG
```

### 2. Recommended Input Format For Compressed Chunk Folder - For** Postpress**

```
test_1_fgh
```

1.fgh
```
#H9_.
```
2.fgh
```
#H9/.
```
3.fgh
```
#H9?.
```
4.fgh
```
#H9.7
```
5.fgh
```
#H9.7.
```
6.fgh
```
#H9/7.
```
7.fgh
```
#H9?7+
```
8.fgh
```
#H9.7.
```

### 3. File Header Bits
```
00000000: 2348 3947 c923 12b1 b112 c8c4 8c4c 8c4c  #H9G.#.......L.L
```
### I. The file starts with `#H9` (this is the file magic that marks a known file to the decompressor).
### II. Then `G` (which is the file header itself - 01000111). This file header provides the following information (Starting from the Left):
   A. this byte is ignored by the program (MeloPress) `0`
   B. file is a head file (the first file to be compressed) `1`
   C. read index did not have any nucleotides left at the end due to read index length being indivisible by 4 `00`
   D. is read index length indivisible by 4 `0`
   E. file is a `.fgh` file `1`
   F. file is in a state of compression (compressed) `1`
   G. file is an RNA file `1`
### III. The rest of the bytes above are compressed RNA nucleotides.
```
00000000: 2348 3946 8113 7334 cdef 86c7 1b1b 14b2  #H9F..s4........
```
### I. The file starts with `#H9` (this is the file magic that marks a known file to the decompressor).
### II. Then `F` (which is the file header itself - 01000110). This file header provides the following information:
   A. this byte is ignored by program `0`
   B. file is a head file (the first file to be compressed) `1`
   C. read index did not have any nucleotides left at the end due to read index length being indivisible by 4 `00`
   D. is read index length indivisible by 4 `0`
   E. file is a `.fgh` file `1`
   F. file is in a state of compression (compressed) `1`
   G. file is an DNA file `0`
### III. The rest of the bytes above are compressed DNA nucleotides.
### 4. Special Characters  
```
A special character (@) is the only special character considered a valid character in the compression process other than A,T/U,C,G. In the decompression process, invalid characters' bits are considered. For expected output use the recommended format (Check Format Section - Recommended Format) respectively.
```
### 5. Error Codes  
```
Success code 0 means that the program (Prepress/Postpress) ran successfully without any error.

Error code 1 (In Prepress/Postpress) means that the required commandline arguments were not received.

Error code 2 (In Prepress) means that the file to be compressed could not be opened. In Postpress means that there was an error starting standalone decompression.

Error code 3 (In Prepress) means that the file is already compressed. In Postpress means that there was an error to open a compressed chunk file in the compressed chunk folder. In Postpress it also means that the file to be decompressed is not the head file (the first file to be compressed).

Error code 4 (In Prepress) means that the file is not a .fgh (based on the second bit while counting from index 0 from the right) not the file extension. In Postpress means that the file being decompressed was not formatted for decompressiong which could be due to file magic or file header corruption.

Error code 5 (In Prepress) means that the making of the compressed chunk folder (where compressed files are stored) was unsuccessful. In Postpress means that the input file (compressed file) is not a .fgh file (based on the second bit while counting from index 0 from the right) not the file extension.

Error code 6 (In Prepress) means that the creating of one of the compressed chunk files was unsuccessful. In Postpress means that there was an error opening the copressed chunk folder for decompression.

Error code 7 (In Prepress) means that reading data from the uncompressed data file was unsuccessful at some point. In Postpress (In Standalone Decompression Mode) means that the user file of choice was obtained unhealthily due to user using a wrong format in Terminal (See Terminal Input Format).

Error code 8 (In Prepress) means that the uncompressed data file has DNA and RNA. In Postpress means that the output file (where all decompressed data will be stored) could not be created. In Postpress it could mean output file was not closed successfully.

Error code 9 (In Prepress) means that cleaning up (removing the last file created by mistake during compression) was unsuccessful. In Postpress means that there was an error reading input from a compressed file during decompression.
```

### 6. Termial Arguments
When compressing input data in a file (could be a .txt or .hgf) using the right method of parsing *Terminal* arguments is key to getting error free results. Let's look at some scenarios that are common and see how to compress and decompress input.
### a. Prepress
- Input file, Prepress, and Postpress in the same directory.
### **Proof**
Folder layout: `Postpress		Prepress	READme.md	test_1.txt`\
User (Your) calling convention: `./Prepress/main test.txt`\
Folder layout (after successful compression): `Postpress	Prepress	READme.md	test_1_fgh	test_1.txt`

- Input file in Prepress, while Prepress and Postpress in the same directory.
### **Proof**
Folder layout (Prepress): `main		main.o		main.s		Makefile	sampleDNA.txt		sampleRNA.txt		test.txt`\
Folder layout (Current Directory - MeloPress): `Postpress	Prepress	READme.md`\
User (Your) calling convention: `./Prepress/main ./Prepress/test.txt`\
Folder layout (after successful compression - Prepress): `main		main.o		main.s		Makefile	sampleDNA.txt	sampleRNA.txt	test.txt`\
Folder layout (after successful compression - Current Directory - MeloPress): `_fgh	Postpress	Prepress	READme.md`

- Input file in Postpress, while Prepress and Postpress in the same directory.
### **Proof**
Folder layout (Postpress): `main		main.o		main.s		Makefile	sampleDNA_fgh		sampleDNA.hgf		sampleRNA_fgh		sampleRNA.hgf		test_1.txt	test_fgh	test.hgf`\
Folder layout (Current Directory - MeloPress): `Postpress	Prepress	READme.md`\
User (Your) calling convention: `./Prepress/main ./Postpress/test_1.txt `\
Folder layout (after succesful compression - Postpress): `main		main.o		main.s		Makefile	sampleDNA_fgh		sampleDNA.hgf		sampleRNA_fgh		sampleRNA.hgf	test_1.txt	test_fgh	test.hgf`\
Folder layout: (after successful compression - Current Directory - MeloPress): `_fgh	Postpress	Prepress	READme.md`


### b. Postpress
- Input file, Prepress, and Postpress in the same directory.
### **Proof**
Folder layout: `Postpress		Prepress	READme.md	test_1_fgh	test_1.txt`\
User (Your) calling convention: `./Postpress/main ./test_1_fgh/1.fgh`\
Folder layout (after a successful decompression): `Postpress		Prepress	READme.md	test_1_fgh	test_1.hgf	test_1.txt`

- Input file in Prepress, while Prepress and Postpress in the same directory.
### **Proof**
Folder layout (after successful compression - Prepress): `main		main.o		main.s		Makefile	sampleDNA.txt		sampleRNA.txt		test.txt`\
Folder layout (after successful compression - Current Directory - MeloPress): `_fgh	Postpress	Prepress	READme.md`\
User (Your) calling convention: `./Postpress/main ./_fgh/1.fgh `\
Folder layout (after successful decompression - Prepress): `main	main.o		main.s		Makefile	sampleDNA.txt		sampleRNA.txt		test.txt`\
Folder layout (after successful decompression - Current Directory - MeloPress): `_fgh	.	..	.DS_Store	.git		.hgf		Postpress	Prepress	READme.md`

- Input file in Postpress, while Prepress and Postpress in the same directory.
### **Proof**
Folder layout (after succesful compression - Postpress): `main		main.o		main.s		Makefile	sampleDNA_fgh		sampleDNA.hgf		sampleRNA_fgh		sampleRNA.hgf	test_1.txt	test_fgh	test.hgf`\
Folder layout: (after successful compression - Current Directory - MeloPress): `_fgh	Postpress	Prepress	READme.md`\
User (Your) calling convention: `./Postpress/main ./_fgh/1.fgh`\
Folder layout (after successful decompression - Postpress): `main		main.o		main.s		Makefile	sampleDNA_fgh		sampleDNA.hgf		sampleRNA_fgh		sampleRNA.hgf	test_1.txt	test_fgh	test.hgf`\
Folder layout (after successful decompression - Current Directory - MeloPress): `_fgh		.		..		.DS_Store	.git		.hgf		Postpress	Prepress	READme.md`

### **Note**:
This is just a way to illustrate how MeloPress's Prepress and Postpress expect *Terminal* arguments. If user (you) are wondering how to just decompress one file instead of the whole chunk folder, there is a way to achieve that.
Basing on a scenario where Prepress, Postpress, and the input file are in the same directory. This can be applied to scenarios illustrated earlier (See Terminal Arguments).

### **Proof**
Folder layout: `Postpress		Prepress	READme.md	test.txt`\
User (Your) calling convention: `./Prepress/main test.txt `\
Folder layout (after successful compression): `Postpress	Prepress	READme.md	test_fgh	test.txt`
a. Looking at snapshot **1.fgh**
User (Your) calling convention: `./Postpress/main -s ./test_fgh/1.fgh` or `./Postpress/main ./test_fgh/1.fgh -s`\
Folder layout: `1.hgf	Postpress	Prepress	READme.md	test_fgh	test.txt`

b. Looking at snapshot **2.fgh**
User (Your) calling convention: `./Postpress/main -s ./test_fgh/2.fgh` or `./Postpress/main ./test_fgh/2.fgh -s`\
Folder layout: `2.hgf	Postpress	Prepress	READme.md	test_fgh	test.txt

### **Note**: The `-s` flag triggers standalone decompression which means that decompression will only be applied to that target file and not the entire files in the comrpessed chunk folder.


## Note:
### 1. To see the error codes in the *Terminal*. After running a program, do this to see the result of the last run program.
```
echo $?
```
### 2. To decompress a compressed chunk folder, the target file must be **1.fgh**. This file is the head file that has a bit in the file header that informs Postpress to decompress the entire compressed chunk folder if not in standalone decompression.
### 3. I have added some test files that I recommend user (you) try them out.
### a. Below is the code I created to generate decent data for MeloPress. `sampleDNA.txt` and `sampleRNA.txt`.
```python
nucleotides = ("A", "C", "G", "T")
special_character = '@'

import random
def generateSampleData(data: tuple, marker):
    """
    Generates Data Marked By marker
    :param data:
    :param marker:
    :return: result
    """
    temp_string = ''
    result = []
    for i in range(100000):
        temp_string += marker + '\n'
        for j in range(random.randint(1,100)):
            temp_string += random.choice(data)
        result.append(temp_string)
        temp_string = ''
    return result

x1 = generateSampleData(nucleotides, special_character)

with open('sampleDNA.txt', 'w') as f:
    f.write('\n'.join(x1))

nucleotides = ("A", "C", "G", "U")
special_character = '@'

x2 = generateSampleData(nucleotides, special_character)

with open('sampleRNA.txt', 'w') as f:
    f.write('\n'.join(x2))
```
### b. I have added another test file that has difficult scenarios that MeloPress might fail. Try it out too `test.txt`.

# Take Aways
### 1. This project has a space complexity of O(n) because it takes up as much space on disk as much as the data given. If given 1,000,000 read indexes, MeloPress will create a million files for this. It will not exceed this limit in order to prevent filling the user's (your) disk even though this is still a large number of files. There is away to reduce this (creating lots of files). By isolating read indexes with bytes that resemble the newline character or the @ character, the files could be broken down into normal files (stores read indexes that do not have the newline character or the @ character in the read index data) and special files (stores read indexes that have the @ character and the newline character in the read index data).
### This might seem promising but it hinders a certain achievement I made. When files are bundled into the normal files and the special files, the ability to keep track of read indexes who have data length indivisble by 4 is gone. On the other hand having each read index in a respective file allows MeloPress to store valuable information into file headers which preserves data but trades off computer space (lots of files are created). I decided to trade off space rather than the data itself.
### I might want to avoid creating a lot of files by creating a normal file with read index header then the read index data then the next read index header then the next read index data etc. This is still the same bug I had to fix in earlier versions. Some bytes might resemble the read index header and MeloPress will get confused hence corrupted data is returned.
### With these unpredictable bugs, the current way is the best way for MeloPress to move forward safely and accurately.
### 2. DNAGenre's MeloPress and this MeloPress compress data differently. DNAGenre's MeloPress is made in Python which provides the luxury of looking at the entire input at once in a go and compress it at once. This is fine but results in a poor execution time and might not work on systems with less resources. On the other side, this MeloPress looks at the entire input in chunks (breaking down the data in manageable pieces) which contributes to its mindblowing execution time. The final conclusion is that they both compress input differently but decompress it similarly.
### a. MeloPress can compress an input file and DNAGenre's Postpress can decompress that input file (Compatible this way).
### b. DNAGenre's Prepress can compress an input file but MeloPress's Postpress cannot decompress that input from DNAGenre's Prepress (Incompatible this way). If this works, I have noticed during tests that MeloPress' output is split into two files or more.
### c. When compressing a file be consistent with the architecture used. If user (you) use DNAGenre's MeloPress to compress input then use DNAGenre to decompress that input. If user (you) use MeloPress to compress, then use MeloPress to decompress.

# Tech Stack
```
Apple's Xcode - Code Editor
Google's AI Mode - AI Assistant
Google - Research
```
# Contributing
```
If you are interested in improving or upgrading this project even though you are a beginner or expert,
please feel free to contact me through my contacts in the contacts section.

Upgrading Opportunities:
You can upgrade this project to run on Linux Architecture.
You can upgrade this project to run on Windows Architecture.
You can upgrade this project to run on Intel Architecture.
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
