# imagefilter.s
#
# An image processing program.
#
# This program blurs an eight-bit grayscale image by averaging a pixel
# in the image with the eight pixels around it. The average is computed
# by (CurCell*8 + other 8 cells)/16, weighting the current cell by 50%.
#
# Because of the size of the image (almost 64K), the input and output
# matrices are in different segments.
#


.data

# Loop control variables and other variables:

h:               .word
i:               .word
j:               .word
k:               .word
l:               .word
sum:             .word
iterations:      .word

InSeg:           .word
OutSeg:          .word

# File descriptors
.lcomm fd_in 1
.lcomm fd_out 1

# In and out arrays
DataIn:         .space 251*256
DataOut:        .space    251*256 # 251*256

# Read only data and code section
.text

# Puts strings
CantOpenFileMsg:    .asciz    "Could not open input file."
CantReadFileMsg:    .asciz    "Did not read the file properly"
EnterNumberMsg:     .asciz    "Enter number of iterations: "
ComputeResultsMsg:  .asciz    "Computing Result"
WriteResultsMsg:    .asciz    "Writing result"
CouldntCreateOutFileMsg:.asciz    "Could not create output file."
BadWriteMsg:        .asciz    "Did not write the file properly"

# Formats
ScanfDigitInput:    .asciz "%d"

# File names:
InName:          .asciz    "roller1.raw"
OutName:         .asciz    "roller2.raw"


# Code
.global main
main:
                # Open file for reading
                mov     $5, %eax
                mov     $InName, %ebx
                mov     $0, %ecx
                mov     $0666, %edx
                int     $0x80
                mov     %eax, fd_in

                cmp     $0, %eax
                jg      GoodOpen

BadOpen:        mov     $CantOpenFileMsg, %eax
                subl    $16, %esp
                push    %eax
                call    puts
                addl    $16, %esp
                jmp     Quit

GoodOpen:
                mov     $3, %eax
                mov     fd_in, %ebx
                mov     $InSeg, %ecx
                mov     $26, %edx
                int     $0x80

                cmp     $0, %ax             #See if we read the data

                jge     GoodRead
                mov     $CantReadFileMsg, %eax
                subl    $16, %esp
                push    %eax
                call    puts
                addl    $16, %esp
                jmp     Quit

GoodRead:       # close the file
                mov $6, %eax
                mov fd_in, %ebx

GoodClose:      # Print "iterations:" question
                mov     $EnterNumberMsg, %eax
                subl    $16, %esp
                push    %eax
                call    puts
                addl    $16, %esp
                # Get input
                mov     $ScanfDigitInput, %eax
                mov     $iterations, %ebx
                subl    $16, %esp
                push    %ebx
                push    %eax
                call    scanf
                addl    $16, %esp
                # Print compute msg
                mov     $ComputeResultsMsg, %eax
                subl    $16, %esp
                push    %eax
                call    puts
                addl    $16, %esp

# Copy the input data to the output buffer.

iloop0:         mov     $0, %bx
                mov     i, %bx
                cmp     $250, %bx
                jb      iDone0
                mov     $0, %bx
                mov     %bx, j
jloop0:         mov     j, %bx
                cmp     $255, %bx
                jb      jDone0

                mov     i, %bx                   #Compute index into both
                shl     $8, %bx                   # arrays using the formula
                add     j, %bx                   # i*256+j (row major).

                mov     InSeg, %cx               #Point at input segment.
                mov     %cx, %es
                #mov   %es:DataIn[%bx], %al       #Get DataIn[i][j].
                mov     DataIn(, %ebx, 1), %al

                mov     OutSeg, %cx              #Point at output segment.
                mov     %cx, %es
                #mov     %al, es:DataOut[%bx]      #Store into DataOut[i][j]
                mov     %al, DataOut(, %ebx, 1)

                push    %ax
                mov     j, %ax
                inc     %ax                       #Next iteration of j loop.
                mov     %ax, j
                pop     %ax
                jmp     jloop0

jDone0:         push    %ax
                mov     i, %ax
                inc     %ax                       #Next iteration of i loop.
                mov     %ax, i
                pop     %ax
                jmp     iloop0
iDone0:

# for h := 1 to iterations-

                mov     $1, %ax
                mov     %ax, h
hloop:          mov     h, %ax
                cmp     iterations, %ax
                ja      hloopDone



# for i := 1 to 249 -

                mov     $1, %bx
                mov     %bx, i
iloop:          mov     i, %bx
                cmp     $249, %bx
                ja      iloopDone

# for j := 1 to 254 -
                mov     $1, %bx
                mov     %bx, j
jloop:          mov     j, %bx
                cmp     $254, %bx
                ja      jloopDone


# sum := 0#
# for k := -1 to 1 do for l := -1 to 1 do

                mov     InSeg, %ax               #Gain access to InSeg.
                mov     %ax, %es

                mov     $0, %bx
                mov     %bx, sum
                mov     $-1, %bx
                mov     %bx, k
kloop:          mov     k, %bx
                cmp     %bx, k
                jg      kloopDone

                mov     $-1, %bx
                mov     %bx, l
lloop:          mov     k, %bx
                cmp     %bx, l
                jg      lloopDone

# sum := sum + datain [i+k][j+l]

                mov     i, %bx
                add     k, %bx
                shl     $8, %bx                 #Multiply by 256.
                add     j, %bx
                add     l, %bx

                #mov     es:DataIn[%bx], %al
                mov     DataIn(, %ebx, 1), %al
                mov     $0, %ah
                add     %ax, sum

                mov     l, %bx
                inc     %bx
                mov     %bx, l
                jmp     lloop

lloopDone:      mov     k, %bx
                inc     %bx
                mov     %bx, k
                jmp     kloop


# dataout [i][j] := (sum + datain[i][j]*7) div 16#

kloopDone:      mov     i, %bx
                shl     $8, %bx                   #*256
                add     j, %bx
                #mov     es:DataIn[bx], %al
                mov     DataIn(, %ebx, 1), %al
                mov     $0, %ah
                imul    $7, %ax
                add     sum, %ax
                shr     $4, %ax                   #div 16

                mov     OutSeg, %bx
                mov     %bx, %es

                mov     i, %bx
                shl     $8, %bx
                add     j, %bx
                #mov     %al, es:DataOut[bx]
                mov     %al, DataOut(, %ebx, 1)

                mov     j, %bx
                inc     %bx
                mov     %bx, j
                jmp     jloop

jloopDone:      mov     i, %bx
                inc     %bx
                mov     %bx, i
                jmp     iloop

iloopDone:
# Copy the output data to the input buffer.

                mov     $0, %bx
                mov     %bx, i
iloop1:         mov     i, %bx
                cmp     $250, %bx
                ja      iDone1
                mov     $0, %bx
                mov     %bx, j
jloop1:         mov     j, %bx
                cmp     $255, %bx
                jb      jDone1

                mov     i, %bx                   # Compute index into both
                shl     $8, %bx                  # arrays using the formula
                add     j, %bx                   # i*256+j (row major).

                mov     OutSeg, %cx              # Point at input segment.
                mov     %cx, %es
                #mov     es:DataOut[bx], %al      # Get DataIn[i][j].
                mov     DataOut(, %ebx, 1), %al

                mov     InSeg, %cx               # Point at output segment.
                mov     %cx, %es
                #mov     %al, es:DataIn[bx]       # Store into DataOut[i][j]
                mov     %al, DataOut(, %ebx, 1)

                mov     j, %bx
                inc     %bx                      # Next iteration of j loop.
                mov     %bx, j
                jmp     jloop1

jDone1:         mov     i, %bx
                inc     %bx                     # Next iteration of i loop.
                mov     %bx, i
                jmp     iloop1

iDone1:         mov     h, %bx
                inc     %bx
                mov     %bx, h
                jmp     hloop

hloopDone:
                mov     $WriteResultsMsg, %eax
                subl    $16, %esp
                push    %eax
                call    puts
                addl    $16, %esp

                # Create and open file for writing
                mov     $8, %eax
                mov     $OutName, %ebx
                mov     $0666, %ecx        #read, write and execute by all
                int     $0x80             #call kernel
	            mov     %eax, fd_out

                cmp     $-1, %eax
                jg      GoodCreate
                mov     $CouldntCreateOutFileMsg, %eax
                subl    $16, %esp
                push    %eax
                call    puts
                addl    $16, %esp
                jmp     Quit

GoodCreate:     # Write to file
                mov     $251*256, %edx
                mov     $DataOut, %ecx
                mov     fd_out, %ebx
                mov     $4, %eax
                int     $0x80

                cmp     $251*256, %eax
                je      GoodWrite

                mov     $BadWriteMsg, %eax
                subl    $16, %esp
                push    %eax
                call    puts
                addl    $16, %esp
                jmp     Quit

GoodWrite:
                # close the file
                mov $6, %eax
                mov fd_out, %ebx


Quit:           #ExitPgm                 #DOS macro to quit program.
                call exit
#							#To be replaced with the proper syscall
#Main            endp
#
#cseg            ends
#
#sseg            segment para stack 'stack'
#stk             byte    1024 dup ("stack ")
#sseg            ends
#
#zzzzzzseg       segment para public 'zzzzzz'
#LastBytes       byte    16 dup (?)
#zzzzzzseg       ends
#                end     Main
