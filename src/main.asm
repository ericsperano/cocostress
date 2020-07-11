*********************************************************************************
* CoCo 3 RAM Stress Tester - main.asm
* Copyright (c) 2015-2016, Richard Goedeken
* All rights reserved.
*
*    This file is part of CoCo 3 RAM Stress Tester.
*
*    CoCo 3 RAM Stress Tester is free software: you can redistribute it
*    and/or modify it under the terms of the GNU General Public License
*    as published by the Free Software Foundation, either version 3 of
*    the License, or (at your option) any later version.
*
*    CoCo 3 RAM Stress Tester is distributed in the hope that it will be
*    useful, but WITHOUT ANY WARRANTY; without even the implied warranty
*    of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with CoCo 3 RAM Stress Tester.  If not, see:
*    <http://www.gnu.org/licenses/>.
*
*********************************************************************************

***********************************************************
*
* Logical Memory map:
*
* $0000-$1FFF: BASIC vectors during program load
* $2000-$3FFF: Code/Data/Stack page
* $4000-$5FFF: Read page source
* $6000-$7FFF: Write page dest
* $8000-$9FFF: Graphics draw
* $A000-$BFFF: Graphics draw
* $C000-$DFFF:
* $E000-$FEFF:
* $FF00-$FFFF: IRQ vectors, Hardware mapped i/o
*
* Physical Memory map:
*
* Page $30-$36: 320x200x16 graphics screen
* Page $39:     Code/Data/Stack page
*
***********************************************************
* Loader code
*
            org         $1800

            include     init.asm

start       jsr         Init_SetupHardware
            lds         #$4000                  * move stack to top of primary code page
            lda         #$20
            tfr         a,dp                    * set DP to our Global variables
            * detect installed memory
            ldx         #Test_Line2+0
            jsr         Init_DetectRAM
            * clear screen
            clra                                * clear graphics memory
            ldx         #$30                        ; 30=graphic screen
ClearScreenLoop@
            jsr         MemMgr_BlockStoreConst
            leax        1,x
            cmpx        #$37
            bne         ClearScreenLoop@
            * enable graphics and draw the text messages
            jsr         Init_EnableGraphics
;            jsr         PrintLine00
;            jsr         PrintLine01
;            jsr         PrintLine02
;            jsr         PrintLine03
;            jsr         PrintLine04
;            jsr         PrintLine05
;            jsr         PrintLine06
;            jsr         PrintLine07
            jsr         PrintLine1
            jsr         PrintLine2
            jsr         PrintLine3
            jsr         PrintLine4
            * set the starting page and jump to the main loop for testing
            ldd         <TestPageStart
            std         <CurTestPage
;infinite    jmp         infinite
            jmp         mainloop



***********************************************************
* The Memory Test code/data/stack are in the $2000-$3FFF page

                        org     $2004           ; eric not sure why not 2000??

***********************************************************
* Global variables
*
* start with Direct Page variables

CurCodePage             fdb     $39
TestPageStart           zmd     1
TestPageEnd             zmd     1
CurTestPage             zmd     1
CurVerifyType           zmb     1           * 'I' for immediate verify, 'D' for delayed verify
ErrorRepeatCount        zmb     1           * number of times incorrect value was read (max=3)

ErrorCount              fdb     $0000
PageMegCount            fcb     $00
MegTestedCount          fdb     $0000

PageLastTest            zmb     1024        * elements $30-$36 might also be accessed by DP

* far (not in DP) variables

ErrorInfoList           rmb     8*8
PageRandSeed            rmb     4096
Title_Line00            fcb     $01,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$1F,0
Title_Line01            fcb     $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,$2C,$2D,$2E,$2F,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F,0
Title_Line02            fcb     $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F,$50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$5B,$5C,$5D,$5E,$5F,0
Title_Line03            fcb     $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F,$70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F,0
Title_Line04            fcb     $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8A,$8B,$8C,$8D,$8E,$8F,$90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9E,$9F,0
Title_Line05            fcb     $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF,$B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF,0
Title_Line06            fcb     $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF,$D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF,0
Title_Line07            fcb     $E0,$E1,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF,$F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF,0

;Title_Line0             fcn     'abcdefghijklmnopqrstuvwxyz'
Title_Line1             fcn     'CoCo 3 RAM Stress Test v1.2'
Title_Line2             fcn     'http://github.com/richard42/cocostress'
Test_Line1              fcn     'Testing page: $000'
Test_Line2              fcn     '****KB RAM, 00000MB Tested, 00000 Errors'
Error_Line1             fcn     '** Blk=$XXX Off=$XXXX Wrote=$XX Read=$XX'

***********************************************************
* Library code
*
            include     utility.asm
            include     memory.asm
            include     math.asm
            include     graphics-bkgrnd.asm
            include     graphics-text.asm

***********************************************************
* Main loop
*
mainloop
            * move our code page out of the way if necessary
            ldd         <CurTestPage
            cmpd        <CurCodePage
            bne         >
            tfr         d,x
            eorb        #1
            std         <CurCodePage
            tfr         d,y
            ldu         #PageLastTest           * clear the last test number for the new code page
            clr         d,u
            jsr         MemMgr_CopyPhysicalBlock
            ldd         <CurCodePage
            ldu         #$FFA1
            jsr         MemMgr_MapPage
            * run the test on this page
!           jsr         TestMemoryPage
            * redraw our title page if we just trashed it
            ldd         <CurTestPage
            subd        #$30
            blt         NextPage@
            bne         >
            jsr         PrintLine1
            jsr         PrintLine2
            bra         NextPage@
            * redraw the test message page if we just trashed it
!           cmpd        #$01
            bne         >
            jsr         PrintLine3
            jsr         PrintLine4
            bra         NextPage@
!           cmpd        #5
            bhi         NextPage@
            * redraw any error info if we just trashed it
            subb        #2
            lslb
            cmpd        <ErrorCount
            bge         NextPage@
            pshs        d
            tfr         b,a
            jsr         PrintErrorLine
            puls        d
            addd        #1
            cmpd        <ErrorCount
            bge         NextPage@
            tfr         b,a
            jsr         PrintErrorLine
            * go to the next page
NextPage@   ldd         <CurTestPage
            cmpd        <TestPageEnd
            bne         IncTestPage@
            ldd         <TestPageStart
            bra         StoreTestPage@
IncTestPage@
            addd        #1
StoreTestPage@
            std         <CurTestPage
            * update the test message line 1: page counter
            ldx         #Test_Line1+14
            jsr         Util_WordToAsciiHex
            lda         #'$
            sta         Test_Line1+14
            jsr         PrintLine3
            * update the megabyte counter
            inc         <PageMegCount
            bpl         NoNewMegabyte@
            clr         <PageMegCount
            ldd         <MegTestedCount
            addd        #1
            std         <MegTestedCount
            ldx         #Test_Line2+12
            jsr         Util_WordToAsciiDecimal
            jsr         PrintLine4
NoNewMegabyte@
            jmp         mainloop

***********************************************************
* Line redraw handlers
*
*
PrintLine00
            clra                                * Y = 0
            ldb         #0                     * X = 0
            ldx         #Title_Line00
            jsr         Gfx_DrawTextLine
            rts
PrintLine01
            lda         #$10
            ldb         #0                     * X = 0
            ldx         #Title_Line01
            jsr         Gfx_DrawTextLine
            rts
PrintLine02
            lda         #$20
            ldb         #0                     * X = 0
            ldx         #Title_Line02
            jsr         Gfx_DrawTextLine
            rts
PrintLine03
            lda         #$30
            ldb         #0                     * X = 0
            ldx         #Title_Line03
            jsr         Gfx_DrawTextLine
            rts
PrintLine04
            lda         #$40
            ldb         #0                     * X = 0
            ldx         #Title_Line04
            jsr         Gfx_DrawTextLine
            rts
PrintLine05
            lda         #$50
            ldb         #0                     * X = 0
            ldx         #Title_Line05
            jsr         Gfx_DrawTextLine
            rts
PrintLine06
            lda         #$60
            ldb         #0                     * X = 0
            ldx         #Title_Line06
            jsr         Gfx_DrawTextLine
            rts
PrintLine07
            lda         #$70
            ldb         #0                     * X = 0
            ldx         #Title_Line07
            jsr         Gfx_DrawTextLine
            rts


PrintLine1
            clra                                * Y = 0
            ldb         #26                     * X = 52
            ldx         #Title_Line1
            jsr         Gfx_DrawTextLine
            clr         <PageLastTest+$30       * we just changed page $30
            rts

PrintLine2
            lda         #16                     * Y = 16
            ldb         #4                      * X = 8
            ldx         #Title_Line2
            jsr         Gfx_DrawTextLine
            clr         <PageLastTest+$30       * we just changed page $30
            rts

PrintLine3
            lda         #32                     * Y = 32
            ldb         #44                     * X = 88
            ldx         #Test_Line1
            jsr         Gfx_DrawTextLine
            clr         <PageLastTest+$31       * we just changed page $31
            rts

PrintLine4
            lda         #48                     * Y = 48
            ldb         #0                      * X = 0
            ldx         #Test_Line2
            jsr         Gfx_DrawTextLine
            clr         <PageLastTest+$31       * we just changed page $31
            rts

PrintErrorLine                                  * A has the line number (0-7)
            pshs        a
            ldb         #8                      * get pointer to error info
            mul
            ldx         #ErrorInfoList
            abx
            * write test type value into text message
            ldd         ,x                      * A = 'I' or 'D', B=1-3 (count)
            sta         Error_Line1+0
            addb        #'0
            stb         Error_Line1+1
            * write numeric values into the text message
            ldd         2,x
            ldy         6,x
            ldx         4,x
            pshs        x
            ldx         #Error_Line1+7
            jsr         Util_WordToAsciiHex
            lda         #'$
            sta         Error_Line1+7
            puls        d
            ldx         #Error_Line1+17
            jsr         Util_WordToAsciiHex
            tfr         y,d
            ldx         #Error_Line1+29
            jsr         Util_ByteToAsciiHex
            tfr         y,d
            tfr         b,a
            ldx         #Error_Line1+38
            jsr         Util_ByteToAsciiHex
            * set the Last Test for this graphics page to 0, since we're going to change it
            lda         ,s
            lsra
            ldx         #PageLastTest+$32
            clr         a,x
            * draw the text line
            puls        a
            lsla
            lsla
            lsla
            lsla
            adda        #64                     * Y = 64 + 16 * LineNum
            ldb         #0                      * X = 0
            ldx         #Error_Line1
            jsr         Gfx_DrawTextLine
            rts

***********************************************************
* Helper functions
*
*

TestMemoryPage
            * validate stability of results from last time we tested this page
            lda         #'D                     * Delayed verification test
            sta         <CurVerifyType
            ldd         #PageLastTest
            ldx         <CurTestPage
            lda         d,x
            beq         SkipPreCheck@
            deca
            bne         PreCheckNot1@
            lda         #$00                    * Test 1: constant 00
            jsr         MemMgr_BlockCheckConst
            bra         SkipPreCheck@
PreCheckNot1@
            deca
            bne         PreCheckNot2@
            lda         #$55                    * Test 2: constant 55
            jsr         MemMgr_BlockCheckConst
            bra         SkipPreCheck@
PreCheckNot2@
            deca
            bne         PreCheckNot3@
            lda         #$AA                    * Test 3: constant AA
            jsr         MemMgr_BlockCheckConst
            bra         SkipPreCheck@
PreCheckNot3@
            deca
            bne         PreCheckNot4@
            lda         #$FF                    * Test 4: constant FF
            jsr         MemMgr_BlockCheckConst
            bra         SkipPreCheck@
PreCheckNot4@
            pshs        a
            ldd         <CurTestPage
            lslb
            rola
            lslb
            rola
            ldy         #PageRandSeed
            leay        d,y
            puls        a
            deca
            bne         PreCheckNot5@
            lda         ,y                      * Test 5: constant rand(255)
            jsr         MemMgr_BlockCheckConst
            bra         SkipPreCheck@
PreCheckNot5@
            ldd         Util_VarX               * save current PRNG seed
            ldu         Util_VarB
            pshs        u,d
            ldd         ,y                      * set PRNG seed to starting value when this page was last tested
            ldu         2,y
            std         Util_VarX
            stu         Util_VarB
            jsr         MemMgr_BlockCheckRandom * Test 6: Random
            puls        u,d
            std         Util_VarX               * restore original PRNG seed
            stu         Util_VarB
SkipPreCheck@
            lda         #'I                     * Immediate verification test
            sta         <CurVerifyType
            * pick a random test (1-6) to run which is different from the last one
            ldx         #PageLastTest
            ldd         <CurTestPage
            leax        d,x
!           jsr         Util_Random
            ldb         #6
            mul
            inca                                * test number (1-6) in A
            cmpa        ,x
            beq         <
            sta         ,x                      * remember the test number for this page
            * now do the test
            ldx         <CurTestPage
            deca
            bne         TestNot1@
            lda         #$00                    * Test 1: constant 00
            jsr         MemMgr_BlockStoreConst
            jsr         MemMgr_BlockCheckConst
            bra         TestDone@
TestNot1@
            deca
            bne         TestNot2@
            lda         #$55                    * Test 2: constant 55
            jsr         MemMgr_BlockStoreConst
            jsr         MemMgr_BlockCheckConst
            bra         TestDone@
TestNot2@
            deca
            bne         TestNot3@
            lda         #$AA                    * Test 3: constant AA
            jsr         MemMgr_BlockStoreConst
            jsr         MemMgr_BlockCheckConst
            bra         TestDone@
TestNot3@
            deca
            bne         TestNot4@
            lda         #$FF                    * Test 4: constant FF
            jsr         MemMgr_BlockStoreConst
            jsr         MemMgr_BlockCheckConst
            bra         TestDone@
TestNot4@
            pshs        a
            tfr         x,d
            lslb
            rola
            lslb
            rola
            ldy         #PageRandSeed
            leay        d,y
            puls        a
            deca
            bne         TestNot5@
            jsr         Util_Random
            sta         ,y                      * save rand(255)
            jsr         MemMgr_BlockStoreConst  * Test 5: constant rand(255)
            jsr         MemMgr_BlockCheckConst
            bra         TestDone@
TestNot5@
            * save the state of the PRNG before writing the bytes
            ldd         Util_VarX
            ldu         Util_VarB
            std         ,y                      * also save in our state buffer
            stu         2,y
            pshs        u,d
            jsr         MemMgr_BlockStoreRandom
            * then restore the state of the PRNG before reading/checking bytes
            puls        u,d
            std         Util_VarX
            stu         Util_VarB
            jsr         MemMgr_BlockCheckRandom
TestDone@
            rts

***********************************************************
*           The stack grows downwards from $4000
*           We should save at least 64 bytes for the stack
            rmb        $3FC0-*                  * throw an error if code page overflowed


***********************************************************
*           Postlog: auto-execution

            org         $0176           ; Hook to allow closing of the file opened to a specified device n1.1nber. called fran $A42D.
            jmp         start

            end         start

