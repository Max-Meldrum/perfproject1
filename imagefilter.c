#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define W 251
#define H 256

int main(int argc, char* argv){
    FILE* fin = fopen("roller1.raw", "r");
    FILE* fout = fopen("roller2.raw", "w");

    unsigned char in[W][H];
    unsigned char out[W][H];

    int itercount;
    printf("iterations: ");
    scanf("%d", &itercount);

    // Read raw file into array
    fread(in, W*H, sizeof(char), fin);
    // Copy in array to out (for the border pixels), can be optimized
    memcpy(out, in, sizeof(out));

    // Blur
    for (int iter=0; iter < itercount; iter++){ // Number of blur iterations
        for (int x=1; x<W-1; x++){ // Iterate X
            for (int y=1; y < H-1; y++){ // Iterate Y
                int sum = 0;
                for (int xa=-1; xa<=1; xa++){ // Iterate X offset: -1,0,1
                    for (int ya=-1; ya<=1; ya++){ // Iterate Y offset: -1,0,1
                        sum += in[x+xa][y+ya];
                    }
                }
                // bordering pixels have 50% weight and original pixel has 50% weight
                out[x][y] = (( sum + in[x][y]*7 ) / 16 );
            }
        }
        memcpy(in, out, sizeof(out));
    }

    fwrite(out, W*H, sizeof(char), fout);

    return 0;
}
