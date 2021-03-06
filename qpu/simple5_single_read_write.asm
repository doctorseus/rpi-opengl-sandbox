.include "vc4.qinc"

.func gvpm_wr_setup(stride, addr)
    # Ignored, Horizontal, Laned (ignored), 32-bit
    gvpm_setup(0, stride, 1, 0, 2, addr)
.endf

.func gvpm_rd_setup(num, stride, addr)
    # Horizontal, Laned (ignored), 32-bit
    gvpm_setup(num, stride, 1, 0, 2, addr)
.endf

.func gvpm_setup(num, stride, horiz, laned, size, addr) 
    0x00000000 | (num & 0xf) << 20 |(stride & 0x3f) << 12 | (horiz & 0x1) << 11 | (laned & 0x1) << 10 | (size & 0x3) << 8 | (addr & 0xff)
    # Table 32: VPM Generic Block Write Setup Format
.endf

.func dma_wr_setup(units, depth, laned, horiz, vpmbase, modew)
    0x80000000 | (units & 0x7f) << 23 | (depth & 0x7f) << 16 | (laned & 0x1) << 15 | (horiz & 0x1) << 14 | (vpmbase & 0x7ff) << 3 | (modew & 0x7)
    # Table 34: VCD DMA Store (VDW) Basic Setup Format
.endf

mov r1, unif
mov r3, unif


# Configure the VPM for writing                      
ldi vw_setup, gvpm_wr_setup(1, 0) # Increase addr by 1, start from 0

# Write a full block of VPM memory
.rep i, 64
nop
nop
nop
mov vpm, ((i+1) * 16)
.endr


# Read one vector
ldi vr_setup, gvpm_rd_setup(1, 1, 0)
nop
nop
nop
mov r2, vpm
add r2, r2, r2

# Write one vector back
ldi vw_setup, gvpm_wr_setup(1, 0)
nop
nop
nop
mov vpm, r2


## move 16 words (1 vector) back to the host (DMA)
# ldi vw_setup, vdw_setup_0(1, 16, dma_h32(0, 0))
ldi vw_setup, dma_wr_setup(64, 16, 0, 1, 0, 0)

## initiate the DMA (the next uniform - ra32 - is the host address to write to))
mov vw_addr, unif

# Wait for the DMA to complete
or.setf -, vw_wait, nop

# trigger a host interrupt (writing rb38) to stop the program
mov.setf irq, nop;  read rb0

nop;  thrend
nop
nop
