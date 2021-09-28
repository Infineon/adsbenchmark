#! /opt/python/3.9/bin/python
#// Disclaimer:
#// THIS FILE IS PROVIDED AS IS AND WITH:
#// (A) NO WARRANTY OF ANY KIND, express, implied or statutory, including any implied warranties of merchantability, fitness for a particular purpose and noninfringement, which  Infineon disclaims to the maximum extent permitted by applicable law; and
#// (B) NO INDEMNIFICATION FOR INFRINGEMENT OF INTELLECTUAL PROPERTY RIGHTS.
#// (C) LIMITATION OF LIABILITY: IN NO EVENT SHALL INFINEON BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES (INCLUDING LOST PROFITS OR SAVINGS) WHATSOEVER, WHETHER BASED ON CONTRACT, TORT OR ANY OTHER LEGAL THEORY, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
#// © 2020 Infineon Technologies AG. All rights reserved.

#// Note:
#// The CMOS transistor models used, were freely available models downloaded from: http://ptm.asu.edu.
#// The bipolar transistor models are from: The Development of Bipolar Log-Domain Filters in a Standard CMOS Process, G. D. Duerden, G. W. Roberts, M. J. Deen, 2001

#// Release:
#// 	version 1.0

register      = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
register_next = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

internal_state = [1,0,0,1,0,1,0,1,0]

expect = [1,1,1,0,0,1,0,0,0,0,1,0,1,1,0,0]

for j in range(0,16):
    tmp = 0 if bool(internal_state[4]) ^ bool(internal_state[8]) else 1;
    for i in [7,6,5,4,3,2,1,0]:
        internal_state[i+1] = internal_state[i];
    internal_state[0] = tmp;
    register_next[j] = tmp;

print(f"Before:   {register}")
print(f"Next:     {register_next}")
print(f"Expect:   {expect}")

