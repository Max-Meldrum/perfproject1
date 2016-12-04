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
# Version #1: Straight-forward translation from Pascal to Assembly.
#
#       Performance comparisons (66 MHz 80486 DX/2 system).
#
#       This code-                              36 seconds.
#       Borland Pascal v7.0-                    45 seconds.
#       Borland C++ v4.02-                      29 seconds.
#       Microsoft C++ v8.00-                    21 seconds.
#                .xlist
#                include         stdlib.a
#                includelib      stdlib.lib
#                .list 286

#dseg            segment para public 'data'
.data

# Loop control variables and other variables:

h:               .word
i:               .word
j:               .word
k:               .word
l:               .word
sum:             .word
iterations:      .word

# File names:

InName:          .byte    "roller1.raw",0
OutName:         .byte    "roller2.raw",0

CantOpenFileMsg:    .byte    "Could not open input file.",cr,lf,0
CantReadFileMsg:    .byte    "Did not read the file properly",cr,lf,0
EnterNumberMsg:     .byte    "Enter number of iterations: ",0
ComputeResultsMsg:  .byte    "Computing Result",cr,lf,0
WriteResultsMsg:    .byte    "Writing result",cr,lf,0
CouldntCreateOutFileMsg:.byte    "Could not create output file.",cr,lf,0
BadWriteMsg:        .byte    "Did not write the file properly",cr,lf,0



# Here is the input data that we operate on.
.bss

#DataIn:          .byte    251 dup (256 dup (?))
DataIn:         .space 64256 # 251*256


# Here is the output array that holds the result.

#DataOut         byte    251 dup (256 dup (?))
DataOut:        .space    64256 # 251*256

# Code
.text

.global main
main:
                mov     $0x3d00, %ax               # Open input file for reading.
                lea     InName, %dx
                int     $0x21
                jnc     GoodOpen
                push    CantOpenFileMsg
                call    puts
                jmp     Quit

GoodOpen:       mov     %ax, %bx                  # File handle.
                mov     InSeg, %dx               # Where to put the data.
                mov     %dx, ds
                lea     DataIn, %dx
                mov     $256*251, %cx             #Size of data file to read.
                mov     $0x3F, %ah
                int     $0x21
                cmp     $256*251, %ax             #See if we read the data.
                je      GoodRead
                push    CantReadFileMsg
                call    puts
                jmp     Quit

GoodRead:       mov     dseg, %ax
                mov     %ax, ds
                push    EnterNumberMsg
                call    puts
                # TODO: Fix iterations
                #getsm
                mov     $5, %ax
                push    %ax
                call    atoi
                # TODO: What does this do?
                #free
                mov     iterations, %ax
                push    ComputeResultsMsg
                call    puts

# Copy the input data to the output buffer.

                mov     $0, i
iloop0:         cmp     i, $250
                ja      iDone0
                mov     j, $0
jloop0:         cmp     j, $255
                ja      jDone0

                mov     i, %bx                   #Compute index into both
                shl     $8, %bx                   # arrays using the formula
                add     j, %bx                   # i*256+j (row major).

                mov     InSeg, %cx               #Point at input segment.
                mov     %cx, es
                mov     es:DataIn[bx], %al       #Get DataIn[i][j].

                mov     OutSeg, %cx              #Point at output segment.
                mov     %cx, es
                mov     %al, es:DataOut[bx]      #Store into DataOut[i][j]

                inc     j                       #Next iteration of j loop.
                jmp     jloop0

jDone0:         inc     i                       #Next iteration of i loop.
                jmp     iloop0

iDone0:

# for h := 1 to iterations-

                mov     $1, h
hloop:          mov     h, %ax
                cmp     iterations, %ax
                ja      hloopDone



# for i := 1 to 249 -

                mov     $1, i
iloop:          cmp     $249, i
                ja      iloopDone

# for j := 1 to 254 -
                mov     $1, j
jloop:          cmp     $254, j
                ja      jloopDone


# sum := 0#
# for k := -1 to 1 do for l := -1 to 1 do

                mov     InSeg, %ax               #Gain access to InSeg.
                mov     %ax, es

                mov     $0, sum
                mov     -1, k
kloop:          cmp     1, k
                jg      kloopDone

                mov     -1, l
lloop:          cmp     1, l
                jg      lloopDone

# sum := sum + datain [i+k][j+l]

                mov     i, %bx
                add     k, %bx
                shl     $8, %bx                 #Multiply by 256.
                add     j, %bx
                add     l, %bx

                mov     es:DataIn[bx], %al
                mov     $0, %ah
                add     %ax, Sum

                inc     l
                jmp     lloop

lloopDone:      inc     k
                jmp     kloop


# dataout [i][j] := (sum + datain[i][j]*7) div 16#

kloopDone:      mov     i, %bx
                shl     $8, %bx                   #*256
                add     j, %bx
                mov     es:DataIn[bx], %al
                mov     $0, %ah
                imul    $7, %ax
                add     sum, %ax
                shr     $4, %ax                   #div 16

                mov     OutSeg, %bx
                mov     %bx, es

                mov     i, %bx
                shl     $8, %bx
                add     j, %bx
                mov     %al, es:DataOut[bx]

                inc     j
                jmp     jloop

jloopDone:              inc     i
                jmp     iloop

iloopDone:
# Copy the output data to the input buffer.

                mov     $0, i
iloop1:         cmp     $250, i
                ja      iDone1
                mov     j, 0
jloop1:         cmp     j, 255
                ja      jDone1

                mov     i, %bx                   # Compute index into both
                shl     %bx, $8                  # arrays using the formula
                add     j, %bx                   # i*256+j (row major).

                mov     OutSeg, %cx              # Point at input segment.
                mov     %cx, es
                mov     es:DataOut[bx], %al      # Get DataIn[i][j].

                mov     InSeg, %cx               # Point at output segment.
                mov     %cx, es
                mov     %al, es:DataIn[bx]       # Store into DataOut[i][j]

                inc     j                        # Next iteration of j loop.
                jmp     jloop1

jDone1:         inc     i                       # Next iteration of i loop.
                jmp     iloop1

iDone1:         inc     h
                jmp     hloop

hloopDone:      push    WriteResultsMsg
                call    puts


# Okay, write the data to the output file:

                mov     0x3c, %ah         #Create output file.
                mov     0, %cx              #Normal file attributes.
                lea     OutName, %dx
                int     0x21
                jnc     GoodCreate
                push    CouldntCreateOutFileMsg
                call    puts
                jmp     Quit

GoodCreate:     mov     %ax, %bx          #File handle.
                push    %bx
                mov     OutSeg, %dx      #Where the data can be found.
                mov     %dx, %ds
                lea     DataOut, %dx
                mov     256*251, %cx     #Size of data file to write.
                mov     0x40, %ah         #Write operation.
                int     0x21
                pop     %bx              #Retrieve handle for close.
                cmp     256*251, %ax     #See if we wrote the data.
                je      GoodWrite
                push    BadWriteMsg
                call    puts
                jmp     Quit

GoodWrite:      mov     0x3e, %ah         #Close operation.
                int     0x21


#Quit:           ExitPgm                 #DOS macro to quit program.
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
