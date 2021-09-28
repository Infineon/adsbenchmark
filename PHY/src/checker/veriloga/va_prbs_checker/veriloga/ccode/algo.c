// Disclaimer:
// THIS FILE IS PROVIDED AS IS AND WITH:
// (A) NO WARRANTY OF ANY KIND, express, implied or statutory, including any implied warranties of merchantability, fitness for a particular purpose and noninfringement, which  Infineon disclaims to the maximum extent permitted by applicable law; and
// (B) NO INDEMNIFICATION FOR INFRINGEMENT OF INTELLECTUAL PROPERTY RIGHTS.
// (C) LIMITATION OF LIABILITY: IN NO EVENT SHALL INFINEON BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES (INCLUDING LOST PROFITS OR SAVINGS) WHATSOEVER, WHETHER BASED ON CONTRACT, TORT OR ANY OTHER LEGAL THEORY, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
// © 2020 Infineon Technologies AG. All rights reserved.

// Note:
// The CMOS transistor models used, were freely available models downloaded from: http://ptm.asu.edu.
// The bipolar transistor models are from: The Development of Bipolar Log-Domain Filters in a Standard CMOS Process, G. D. Duerden, G. W. Roberts, M. J. Deen, 2001

// Release:
// version 1.0

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
   
void printBits(size_t const size, void const * const ptr)
{
    unsigned char *b = (unsigned char*) ptr;
    unsigned char byte;
    int i, j;
    
    for (i = size-1; i >= 0; i--) {
        for (j = 7; j >= 0; j--) {
            byte = (b[i] >> j) & 1;
            printf("%u", byte);
        }
    }
    puts("");
}

int main(int argc, char* argv[]) {
    uint16_t start;
    for(start=1; start<500; start++)
    {

        uint16_t a = start;
        int i;    
        for (i = 1;; i++) {
            uint16_t newbit = (((a >> 8) ^ (a >> 4)) & 1);
            a = ((a << 1) | newbit)&0x1FF;
            //printBits(2, &a);
            if (a == start) {
                printf("repetition period is %d\n", i);
                break;
            }
        }

    }
}
