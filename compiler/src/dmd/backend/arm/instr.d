/**
 * AArch64 instruction encodings
 *
 * Compiler implementation of the
 * $(LINK2 https://www.dlang.org, D programming language).
 *
 * Copyright:   Copyright (C) 2024 by The D Language Foundation, All Rights Reserved
 * Authors:     $(LINK2 https://www.digitalmars.com, Walter Bright)
 * License:     $(LINK2 https://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:      $(LINK2 https://github.com/dlang/dmd/blob/master/src/dmd/backend/arm/instr.d, backend/cod3.d)
 * Documentation:  https://dlang.org/phobos/dmd_backend_arm_insrt.html
 * Coverage:    https://codecov.io/gh/dlang/dmd/src/master/src/dmd/backend/arm/instr.d
 */

module dmd.backend.arm.instr;

import core.stdc.stdio;

nothrow:
@safe:

/************************
 * AArch64 instructions
 */
struct INSTR
{
  pure nothrow:

    enum uint ret = 0xd65f03c0;
    enum uint nop = 0xD503201F;

    /* STR (immediate) Unsigned offset
     * https://www.scs.stanford.edu/~zyedidia/arm64/str_imm_gen.html
     */
    static uint str_imm_uns_off(uint is64, ubyte Rt, ubyte Rn, ulong offset)
    {
        // str Rt,Rn,#offset
        uint imm12 = cast(uint)offset >> (is64 ? 3 : 2);
        uint ins = (1 << 31) |
                   (is64 << 30) |
                   (7 << 27) |
                   (0 << 26) |
                   (1 << 24) |
                   (0 << 22) |
                   (imm12 << 10) |
                   (Rn << 5) |
                   Rt;
        return ins;
    }

    /* MADD
     * https://www.scs.stanford.edu/~zyedidia/arm64/madd.html
     */
    static uint madd(uint sf, ubyte Rm, ubyte Ra, ubyte Rn, ubyte Rd)
    {
        uint op54   = 0;
        uint opcode = 0x1B;
        uint op31   = 0;
        uint oO     = 0;

        uint ins = (sf   << 31) |
                   (op54 << 29) |
                   (0x1B << 24) |
                   (op31 << 21) |
                   (Rm   << 16) |
                   (oO   << 15) |
                   (Ra   << 10) |
                   (Rn   <<  5) |
                    Rd;
        return ins;
    }

    /* SDIV/UDIV Rd, Rn, Rm
     * http://www.scs.stanford.edu/~zyedidia/arm64/sdiv.html
     * http://www.scs.stanford.edu/~zyedidia/arm64/udiv.html
     */
    static uint sdiv_udiv(uint sf, bool uns, ubyte Rm, ubyte Rn, ubyte Rd)
    {
        uint S = 0;
        uint ins = (sf   << 31) |
                   (0    << 30) |
                   (S    << 29) |
                   (0xD6 << 21) |
                   (Rm   << 16) |
                   (1    << 11) |
                   ((uns ^ 1) << 10) |
                   (Rn   <<  5) |
                    Rd;
        return ins;
    }

    /* MSUB Rd, Rn, Rm, Ra
     * https://www.scs.stanford.edu/~zyedidia/arm64/msub.html
     */
    static uint msub(uint sf, ubyte Rm, ubyte Ra, ubyte Rn, ubyte Rd)
    {
        uint ins = (sf   << 31) |
                   (0    << 29) |
                   (0x1B << 24) |
                   (0    << 21) |
                   (Rm   << 16) |
                   (1    << 15) |
                   (Ra   << 10) |
                   (Rn   <<  5) |
                    Rd;
        return ins;
    }

    /* SUBS Rd, Rn, #imm{, shift }
     * https://www.scs.stanford.edu/~zyedidia/arm64/subs_addsub_imm.html
     */
    static uint subs_imm(uint sf, ubyte sh, uint imm12, ubyte Rn, ubyte Rd)
    {
        return (sf     << 31) |
               (1      << 30) |
               (1      << 29) |
               (0x22   << 23) |
               (sh     << 22) |
               (imm12  << 10) |
               (Rn     <<  5) |
                Rd;
    }

    /* CMP Rn, #imm{, shift}
     * http://www.scs.stanford.edu/~zyedidia/arm64/cmp_subs_addsub_imm.html
     */
    static uint cmp_imm(uint sf, ubyte sh, uint imm12, ubyte Rn)
    {
        return subs_imm(sf, sh, imm12, Rn, 31);
    }

    /* ORR Rd, Rn, Rm{, shift #amount}
     * https://www.scs.stanford.edu/~zyedidia/arm64/orr_log_shift.html
     */
    static uint orr_shifted_register(uint sf, uint shift, ubyte Rm, uint imm6, ubyte Rn, ubyte Rd)
    {
        uint opc = 1;
        uint N = 0;
        return (sf     << 31) |
               (opc    << 29) |
               (0x0A   << 24) |
               (shift  << 22) |
               (N      << 21) |
               (Rm     << 16) |
               (imm6   << 10) |
               (Rn     <<  5) |
                Rd;
    }

    /* MOV Rd, Rn, Rm{, shift #amount}
     * https://www.scs.stanford.edu/~zyedidia/arm64/mov_orr_log_shift.html
     */
    static uint mov_register(uint sf, ubyte Rm, ubyte Rd)
    {
        return orr_shifted_register(sf, 0, Rm, 0, 31, Rd);
    }
}
