// Source code for the Thumb code in scan.tcl

// Inputs:
//  r0 = base address, aligned to SIDR
//  r1 = end address

.syntax unified
.cpu cortex-m0

BusFault_Handler:
    ldr  r3, [sp, #24]  // get stacked PC
    adds r3, #8         // ON ERROR RESUME NEXT
    str  r3, [sp, #24]
    bx   lr

entry:
    movs r2, #0x80      // r2 <- 0x400 (0x80 << 3)
    lsls r2, r2, #3
loop:
    ldr  r3, [r0, #0]   // r3 <- sidr
    cmp  r3, #0
    beq  nah
    bkpt #1
nah:
    adds r0, r0, r2
    cmp  r0, r1
    bcc  loop
    bkpt #0
