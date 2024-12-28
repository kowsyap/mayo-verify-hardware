#include <mayo.h>
#include <mem.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

void fill_upper_triangle(int N, int O, int M, int *values, int **y1) {
    int value_index = 0;

    // Fill each subarray, but only the upper triangle
    for (int k = 0; k < M; k++) {
        int start_row = k * N;

        // Fill only the upper triangular part of the current NxN subarray
        for (int i = 0; i < (N - O); i++) {
            for (int j = i; j < (N - O); j++) {  // Fill only when column index >= row index
                if (value_index < M * (N - O) * (N - O + 1) / 2) {
                    y1[start_row + i][j] = values[value_index++];
                }
            }
        }
    }
}

void fill_right_part(int N, int O, int M, int *values2, int **y1) {
    int value_index = 0;

    // Fill the right part of each subarray
    for (int k = 0; k < M; k++) {
        int start_row = k * N;

        // Fill the rightmost part (N-O) x O of the current NxN subarray
        for (int i = 0; i < (N - O); i++) {
            for (int j = (N - O); j < N; j++) {  // Fill columns from (N-O) to N-1
                if (value_index < M * (N - O) * O) {
                    y1[start_row + i][j] = values2[value_index++];
                }
            }
        }
    }
}

void fill_bottom_right_part(int N, int O, int M, int *values3, int **y1) {
    int value_index = 0;

    // Fill the bottom-right O x O part of each subarray
    for (int k = 0; k < M; k++) {
        int start_row = k * N + (N - O);

        // Fill the O x O part at the bottom right of each subarray
        for (int i = 0; i < O; i++) {
            for (int j = 0; j < O; j++) {
                if (value_index < M * O * O) {
                    y1[start_row + i][(N - O) + j] = values3[value_index++];
                }
            }
        }
    }
}

void process_arrays(const mayo_params_t* p,unsigned char *epk,unsigned char *sig, unsigned long long slen, unsigned char *t) {
    // Define y1 array dynamically

    int rows_y1 = p->m * p->n;
    int **y1 = (int **)malloc(rows_y1 * sizeof(int *));
    for (int i = 0; i < rows_y1; i++) {
        y1[i] = (int *)malloc(p->n * sizeof(int));
    }

    // Initialize y1 to zeros
    for (int i = 0; i < rows_y1; i++) {
        for (int j = 0; j < p->n; j++) {
            y1[i][j] = 0;
        }
    }

    // Allocate and initialize values array for upper triangle
    int num_values = p->m * (p->n - p->o) * (p->n - p->o + 1) / 2;
    int *values = (int *)malloc(num_values * sizeof(int));
    for (int i = 0; i < num_values; i++) {
        values[i] = i + 1;  // Just using sequential values for testing
    }

    // Allocate and initialize values2 array for right part
    int num_values2 = p->m * (p->n - p->o) * p->o;
    int *values2 = (int *)malloc(num_values2 * sizeof(int));
    for (int i = 0; i < num_values2; i++) {
        values2[i] = num_values + i + 1;  // Start from the next value after the last element in 'values'
    }

    // Allocate and initialize values3 array for bottom-right part
    int num_values3 = p->m * p->o * p->o;
    int *values3 = (int *)malloc(num_values3 * sizeof(int));
    for (int i = 0; i < num_values3; i++) {
        values3[i] = num_values + num_values2 + i + 1;  // Start from the next value after the last element in 'values2'
    }


    // Fill the upper triangle of each subarray
    fill_upper_triangle(p->n, p->o, p->m, values, y1);

    // Fill the right part of each subarray
    fill_right_part(p->n, p->o, p->m, values2, y1);

    // Fill the bottom-right  x  part of each subarray
    fill_bottom_right_part(p->n, p->o, p->m, values3, y1);

    // Get the indices and values of y2 from y1

     // Allocate y2 array dynamically
    int y2_size = p->m * p->n * p->n;
    int *y2 = (int *)malloc(y2_size * sizeof(int));

    // Copy elements from y1 to y2
    for (int i = 0; i < y2_size; i++) {
        int f = i % p->n;
        int g = i / p->n;
        y2[i] = y1[g][f];
    }

    // Open a file to write the output
    FILE *file = fopen("input_file.txt", "w");
    if (file == NULL) {
        printf("Failed to open the file for writing!\n");
        free(y2);
        return;
    }


    // Print the y2 array to verify the result
    for (unsigned int i = 0; i < (unsigned int)y2_size / 2; i++) {
        int d1, d2;
        int bits=18;
        int bits1 = 8;
        unsigned char c1,c2,s,t1;
        d1 = (y2[2 * i] == 0) ? -1 : y2[2 * i]-1;
        d2 = (y2[2 * i + 1] == 0) ? -1 : y2[2 * i + 1]-1;
        c1 = (d1==-1) ? 0 : epk[d1];
        c2 = (d2==-1) ? 0 : epk[d2];
        s = (i<(unsigned int)slen) ? ((sig[i] & 0x0F) << 4) | ((sig[i] & 0xF0) >> 4) : 0;
        //s = (i<(unsigned int)slen) ? sig[i] : 0;
        t1 = ((int)i<p->m_bytes) ? t[i] : 0; 
       // printf("%0*x %x%x %0*x %0*x\n", (bits + 3) / 4, i, c1, c2, (bits1 + 3) / 4, s, (bits1 + 3) / 4, t1);
        fprintf(file, "%0*X %X%X %0*X %0*X\n", (bits + 3) / 4, i, c1, c2, (bits1 + 3) / 4, s, (bits1 + 3) / 4, t1);
    }

    // Free the allocated memory for y2
    free(y2);
    free(y1);
    free(values);
    free(values2);
    free(values3);
}

void divide_nibbles(const unsigned char *input, size_t length, unsigned char *output) {
    // Process each byte of input and split it into nibbles
    for (size_t i = 0; i < length; i++) {
        unsigned char byte = input[i];

        // Extract the most significant nibble and least significant nibble
        unsigned char most_significant_nibble = (byte & 0xF0) >> 4; // Top 4 bits
        unsigned char least_significant_nibble = byte & 0x0F;        // Bottom 4 bits

        // Store the nibbles in the output array
        output[2 * i] = most_significant_nibble;
        output[2 * i + 1] = least_significant_nibble;
        
    }
}

static int verify_val_gen(const mayo_params_t* p) {

    unsigned long long msglen = 32;
    unsigned long long smlen = p->sig_bytes + msglen;

    unsigned char *pk  = calloc(p->cpk_bytes, 1);
    unsigned char *sk  = calloc(p->csk_bytes, 1);

    unsigned char *epk = calloc(p->epk_bytes, 1);
    unsigned char *epk_div = calloc(p->epk_bytes*2, 1);

    unsigned char *sig = calloc(p->sig_bytes + msglen, 1);

    unsigned char msg[32] = { 0xe,0xaa,0xdf };

    int res = mayo_keypair(p, pk, sk);
    if (res != MAYO_OK) {
        printf("FAIL\n");
        res = -1;
        goto err;
    }
    res = mayo_expand_pk(p, pk, epk);
    if (res != MAYO_OK) {
        printf("FAIL\n");
        res = -1;
        goto err;
    } else {
    }

    divide_nibbles(epk,p->epk_bytes*2,epk_div);

    res = mayo_sign(p, sig, &smlen, msg, msglen, sk);
    if (res != MAYO_OK) {
        printf("FAIL\n");
        res = -1;
        goto err;
    }
    res = mayo_verify(p, msg, msglen, sig, p->sig_bytes, pk);
    if (res != MAYO_OK) {
        printf("FAIL\n");
        res = -1;
        goto err;
    } else {
        res = MAYO_OK;
    }
    unsigned char *t = calloc(p->m_bytes, 1);

    res=getT(p,msg,msglen,sig,t);
    printf("\nttt: ");
    for(int i=0;i<p->m_bytes;i++){
        printf("%x ", t[i]);
    }

   process_arrays(p,epk_div,sig,smlen,t);

  
err:
    free(pk);
    free(epk);
    mayo_secure_free(sk, p->csk_bytes);
    free(sig);
    return res;
}

int main(void) {
    return verify_val_gen(&MAYO_VARIANT);
}
