/*************
Metroid Prime Hunters Anti Lag Code (KR 1.0 v5.1 step-opt)
- KR Hook Address: 0x037FBBC4
- Return Address:  0x037FBC24

方針:
- v5の挙動/構造は維持（CustomStack方式も維持）
- 変更は最小限（段階的）
  1) オフセット由来のポインタを main 冒頭で事前計算（addの重複を減らす）
  2) threshold(5) と ddDuration(0xA) は即値化（リテラルを増やさない）
- それ以外はロジックを動かさない

KR fixed:
baseE=0x020D33A8
hpOff=0x0B12 ddOff=0x0EE8 scOff=0x0E74
*******/

.long 0xE2000000
.long ReferenceLabel-8
ldr r0, CustomStack
stmdb r0!, {r1-r11, lr}

/*********************
MAIN PROGRAM
*********************/
main:
    ldr r8, playerOffset
    ldr r9, baseAddressE

    /* playerId: word@baseE >> 8, keep 0..3 */
    ldr r11, [r9]
    lsr r11, r11, #8
    and r11, r11, #3

    mul r10, r8, r11
    add r10,  r10, r9

    /* precompute pointers (step-wise change) */
    ldr r6, hpOffset
    add r6, r10, r6              @ r6 = &HP(self)

    ldr r7, ddDurationOffset
    add r7, r10, r7              @ r7 = &DDDuration(self)

    ldr r1, scStrengthOffset
    add r1, r9, r1               @ r1 = &SCStrength(p0)

    ldr r2, ddDurationOffset
    add r2, r9, r2               @ r2 = &DDDuration(p0)

loadHP:
    ldrh r5, [r6]                @ currentHp
    ldrh r4, tempHP              @ tmpHp (PC-relative)

checkSC:
    mov r0, #0
SCLoop:
    cmp r0, r11
    beq skipSCLoop
    ldr r3, [r1]
    cmp r3, #0
    bgt applyEffect
skipSCLoop:
    add r1, r1, r8
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
    beq skipHpRestoreLoop
    ldr r3, [r1]
    cmp r3, #0
    bgt doHpRestore
skipHpRestoreLoop:
    add r1, r1, r8
    add r0, r0, #1
    cmp r0, #4
    blt hpRestoreLoop
    b end

doHpRestore:
    sub r1, r4, r5
    add r0, r5, r1, lsr #1
    strh r0, [r6]                @ store HP(self)

end:
    strh r5, tempHP
    b ReturnFromProgram

/******************
VARIABLES
*******************/
baseAddressE:
    .long 0x020D33A8
hpOffset:
    .long 0x0B12
ddDurationOffset:
    .long 0x0EE8
scStrengthOffset:
    .long 0x0E74

playerOffset:
    .long 0x00000F30
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
