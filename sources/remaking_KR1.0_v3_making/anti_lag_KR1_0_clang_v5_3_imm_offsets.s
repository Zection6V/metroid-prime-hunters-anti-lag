/*************
Metroid Prime Hunters Anti Lag Code (KR 1.0 v5.3 imm-offsets)
- KR Hook Address: 0x037FBBC4
- Return Address:  0x037FBC24

前提:
- v5.2c が安定 (DD発動OK / ブラックアウト無し)

v5.3 の変更点（小さめ、ロジック不変）:
1) hp/dd/sc/playerOffset の .long 定数ロードを減らすため、
   12bit以内のオフセットを "即値の足し算(2段)" で生成してポインタを作る
   - HP 0x0B12 = 0x0B00 + 0x12
   - DD 0x0EE8 = 0x0E00 + 0xE8
   - SC 0x0E74 = 0x0E00 + 0x74
   - stride 0x0F30 = 0x0F00 + 0x30
2) ループ構造は v5.2c の条件実行版を維持（分岐少なめ）
3) CustomStack / tempHP PC相対 / playerId 抽出 / 回復ロジックは維持
*******/

.long 0xE2000000
.long ReferenceLabel-8
ldr r0, CustomStack
stmdb r0!, {r1-r11, lr}

/*********************
MAIN PROGRAM
*********************/
main:
    /* r8 = playerOffset (0xF30) */
    mov r8, #0x0F00
    add r8, r8, #0x30

    /* r9 = baseAddressE (0x020D33A8) */
    ldr r9, baseAddressE

    /* playerId: word@baseE >> 8, keep 0..3 */
    ldr r11, [r9]
    lsr r11, r11, #8
    and r11, r11, #3

    mul r10, r8, r11
    add r10,  r10, r9

    /* precompute pointers via immediates (no .long offset loads) */
    /* r6 = &HP(self) = r10 + 0xB12 */
    add r6, r10, #0x0B00
    add r6, r6,  #0x12

    /* r7 = &DDDuration(self) = r10 + 0xEE8 */
    add r7, r10, #0x0E00
    add r7, r7,  #0xE8

    /* r1 = &SCStrength(p0) = r9 + 0xE74 */
    add r1, r9,  #0x0E00
    add r1, r1,  #0x74

    /* r2 = &DDDuration(p0) = r9 + 0xEE8 */
    add r2, r9,  #0x0E00
    add r2, r2,  #0xE8

loadHP:
    ldrh r5, [r6]                @ currentHp
    ldrh r4, tempHP              @ tmpHp (PC-relative)

checkSC:
    mov r0, #0
SCLoop:
    cmp r0, r11
    ldrne r3, [r1], r8           @ non-self: load + advance
    moveq r3, #0                 @ self: r3=0
    addeq r1, r1, r8             @ self: advance
    cmp r3, #0
    bgt applyEffect
    add r0, r0, #1
    cmp r0, #4
    blt SCLoop

compareHP:
    cmp r5, r4
    bge end

checkThreshold:
    sub r1, r4, r5
    mov r3, #5
    cmp r1, r3
    ble end

applyEffect:
    mov r3, #0xA
    strh r3, [r7]

restoreHP:
    cmp r5, #0
    beq end

    mov r0, #0
    mov r1, r2                   @ r1 = dd ptr cursor
hpRestoreLoop:
    cmp r0, r11
    ldrne r3, [r1], r8           @ non-self: load + advance
    moveq r3, #0                 @ self: r3=0
    addeq r1, r1, r8             @ self: advance
    cmp r3, #0
    bgt doHpRestore
    add r0, r0, #1
    cmp r0, #4
    blt hpRestoreLoop
    b end

doHpRestore:
    sub r1, r4, r5
    add r0, r5, r1, lsr #1
    strh r0, [r6]

end:
    strh r5, tempHP
    b ReturnFromProgram

/******************
VARIABLES
*******************/
baseAddressE:
    .long 0x020D33A8
tempHP:
    .long 0x00000000

/***********
Returning from Main Program
***********/
ReturnFromProgram:
    ldr r0, CustomStack
    sub r0, r0, #0x30
    ldmia r0!, {r1-r11, lr}
    mov r0, #0x5
    ldr r12, Return
    bx r12

Return:
    .long 0x037FBC24

/***************
Cleaning rest up and terminating program
*****************/
CustomStack:
    .long CustomStack+0x200002C
    .space 0x30, 0x00

EndofProgram:
    .balign 8, 0x00

ReferenceLabel:
    .long 0x037FBBC4
    mov pc, #0x2000000
