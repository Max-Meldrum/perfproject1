#include <stdio.h>  // Used by printf, scanf, fread, fwrite, fopen
#include <string.h> // Used by memcpy

#define W 251 // Image width
#define H 256 // Image height

int main(int argc, char* argv){ // Main start function
    FILE* fin = fopen("roller1.raw", "r");  // Open file descriptor for input file
    FILE* fout = fopen("roller2.raw", "w"); // Open file descriptor for output file

    unsigned char in[W][H];  // Define input data array
    unsigned char out[W][H]; // Define output data array

    int itercount; // Define iteration count variable
    printf("iterations: "); // Print iteration prompt
    scanf("%d", &itercount); // Get user input for iteration count and set itercount variable

    fread(in, W*H, sizeof(char), fin); // Read input file into array
    memcpy(out, in, sizeof(out)); // Copy inarray to outarray

    // Blur
    for (int iter=0; iter < itercount; iter++){ // Number of blur iterations
        for (int x=1; x<W-1; x++){ // Iterate X
            for (int y=1; y < H-1; y++){ // Iterate Y
                int sum = 0; // Initialize sum to zero
                for (int xa=-1; xa<=1; xa++){ // Iterate X offset: -1,0,1
                    for (int ya=-1; ya<=1; ya++){ // Iterate Y offset: -1,0,1
                        sum += in[x+xa][y+ya]; // Add pixel color value to sum
                    }
                }
                // Calculate blur and set it to out array
                // Bordering pixels have 50% weight and original pixel has 50% weight
                out[x][y] = (( sum + in[x][y]*7 ) / 16 );
            }
        }
        memcpy(in, out, sizeof(out)); // Copy out array to in array for next iteration
    }
    fwrite(out, W*H, sizeof(char), fout); // Write out array to out file

    return 0; // Exit gracefully
}
