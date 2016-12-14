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
# Data arrays
DataIn:         .space 251*256
DataOut:        .space 251*256
# Loop control variables and other variables:
# For some reason we need space between the variables
# Otherwise different variables overwrite eachother for some reason
h:               .quad
test1:           .space 1000
i:               .quad
test2:           .space 1000
j:               .quad
test3:           .space 1000
k:               .quad
test4:           .space 1000
l:               .quad
test5:           .space 1000
sum:             .quad
test6:           .space 1000
iterations:      .quad

# File descriptors
.lcomm fd_in 1
.lcomm fd_out 1

# In and out arrays
#DataIn:         .space 251*256
#DataOut:        .space 251*256

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

BadOpen:        # Print error message in case of bad open
                mov     $CantOpenFileMsg, %eax
                subl    $16, %esp
                push    %eax
                call    puts
                addl    $16, %esp
                jmp     Quit

GoodOpen:       # Read data into DataIn
                mov     $3, %eax
                mov     fd_in, %ebx
                mov     $DataIn, %ecx
                mov     $251*256, %edx
                int     $0x80

                cmp     $0, %eax   #See if we read the data
                jge     GoodRead

                # Print error message in case of bad read
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

copy:           # Copy the input data to the output buffer.
                mov     $DataIn, %esi
                mov     $DataOut, %edi
                mov     $251*64, %ecx  # 251*(256/4)(movsd moves 4 bytes per iteration)
                rep     movsd


                mov     $0, %ebx # Since we later will only use %bx, clear high 32-bit part of the register
                mov     $1, %ax
                mov     %ax, h
hloop:          # for h := iterationcount
                mov     $1, %bx
                mov     %bx, i
iloop:          # for i := 1 to 249
                mov     i, %bx
                cmp     $249, %bx
                ja      iloopDone

                mov     $1, %bx
                mov     %bx, j
jloop:          # for j := 1 to 254 -
                mov     j, %bx
                cmp     $254, %bx
                jg      jloopDone

                # sum := 0#
                mov     $0, %bx
                mov     %bx, sum
		        # -1,-1
                mov     i, %bx
                add     $-1, %bx
                shl     $8, %bx
                add     j, %bx
                add     $-1, %bx

                mov     $DataIn, %ecx
                add     %ebx, %ecx
                mov     (%ecx), %al

                mov     $0, %ah
                add     %ax, sum

		        # -1,0
                mov     i, %bx
                add     $-1, %bx
                shl     $8, %bx
                add     j, %bx
                add     $0, %bx

                mov     $DataIn, %ecx
                add     %ebx, %ecx
                mov     (%ecx), %al

                mov     $0, %ah
                add     %ax, sum

		        # -1,1
                mov     i, %bx
                add     $-1, %bx
                shl     $8, %bx
                add     j, %bx
                add     $1, %bx

                mov     $DataIn, %ecx
                add     %ebx, %ecx
                mov     (%ecx), %al

                mov     $0, %ah
                add     %ax, sum

		        # 0,-1
                mov     i, %bx
                add     $0, %bx
                shl     $8, %bx
                add     j, %bx
                add     $-1, %bx

                mov     $DataIn, %ecx
                add     %ebx, %ecx
                mov     (%ecx), %al

                mov     $0, %ah
                add     %ax, sum

		        # 0,0
                mov     i, %bx
                add     $0, %bx
                shl     $8, %bx
                add     j, %bx
                add     $0, %bx

                mov     $DataIn, %ecx
                add     %ebx, %ecx
                mov     (%ecx), %al

                mov     $0, %ah
                add     %ax, sum

		        # 0,1
                mov     i, %bx
                add     $0, %bx
                shl     $8, %bx
                add     j, %bx
                add     $1, %bx

                mov     $DataIn, %ecx
                add     %ebx, %ecx
                mov     (%ecx), %al

                mov     $0, %ah
                add     %ax, sum

		        # 1,-1
                mov     i, %bx
                add     $1, %bx
                shl     $8, %bx
                add     j, %bx
                add     $-1, %bx

                mov     $DataIn, %ecx
                add     %ebx, %ecx
                mov     (%ecx), %al

                mov     $0, %ah
                add     %ax, sum

		        # 1,0
                mov     i, %bx
                add     $1, %bx
                shl     $8, %bx
                add     j, %bx
                add     $0, %bx

                mov     $DataIn, %ecx
                add     %ebx, %ecx
                mov     (%ecx), %al

                mov     $0, %ah
                add     %ax, sum

		        # 1,1
                mov     i, %bx
                add     $1, %bx
                shl     $8, %bx
                add     j, %bx
                add     $1, %bx

                mov     $DataIn, %ecx
                add     %ebx, %ecx
                mov     (%ecx), %al

                mov     $0, %ah
                add     %ax, sum


# dataout [i][j] := (sum + datain[i][j]*7) div 16#
kloopDone:      # Get pointer to element in DataIn
                mov     i, %bx
                shl     $8, %bx  #*256
                add     j, %bx

                mov     $DataIn, %ecx
                add     %ebx, %ecx
                mov     (%ecx), %al

                mov     $0, %ah
                imul    $7, %ax
                add     sum, %ax
                shr     $4, %ax  #div 16

                mov     i, %bx
                shl     $8, %bx
                add     j, %bx

                # Get pointer to DataOut
                mov     $DataOut, %ecx
                add     %ebx, %ecx
                # Move result to DataOut
                mov     %al, (%ecx)

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
                mov     $DataOut, %esi
                mov     $DataIn, %edi
                mov     $251*64, %ecx  # 251*(256/4)(movsd moves 4 bytes per iteration)
                rep     movsd

iDone1:         mov     h, %bx
                inc     %bx
                mov     %bx, h

                mov     h, %ax
                cmp     iterations, %ax
                jle      hloop

hloopDone:      # Print "Writing results" message
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

                # Check that file was sucessfully opened
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

                # Check that file was successfully written to
                cmp     $251*256, %eax
                je      GoodWrite

                # Print error message in case of bad write
                mov     $BadWriteMsg, %eax
                subl    $16, %esp
                push    %eax
                call    puts
                addl    $16, %esp
                jmp     Quit

GoodWrite:      # close the file
                mov $6, %eax
                mov fd_out, %ebx


Quit:           # Exit program
                mov     $0, %eax
                subl    $16, %esp
                push    %eax
                call    exit
