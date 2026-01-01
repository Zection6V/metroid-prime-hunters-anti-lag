/*************
Metroid Prime Hunters Anti Lag Code (KR 1.0 fixed-base v5)

KR Hook Address: 0x037FBBC4
Return Address:  0x037FBC24

KR Base:
- effective baseE = 0x020D33A8  (HP/DD/Coil計算用; base-1)

KR offsets (adjusted):
- HP offset was 0x0B36, but KR HP is at 0x020D3EBA, so offset becomes 0x0B12 (shift -0x24)
- DD duration offset -> 0x0EE8
- Coil strength offset -> 0x0E74

Note:
- playerId extraction remains: word@baseE >> 8 (baseE+1 byte)
- tempHP remains PC-relative
*******/

/*********
@starting main program, setting up custom stack preserving registers.
************/

.long 0xE2000000
.long ReferenceLabel-8
ldr r0, CustomStack
stmdb r0!, {r1-r11, lr}

/*********************
MAIN PROGRAM
*********************/

main:
    ldr r8, playerOffset

    ldr r9, baseAddressE        @ effective base (aligned)

    /* playerId: load word at baseE, take byte at +1 */
    ldr r11, [r9]
    lsr r11, r11, #8
    and r11, r11, #3

    mul r10, r8, r11
    add r10,  r10, r9

loadHP:
    ldr r1, hpOffset
    add r1, r10, r1
    ldrh r5, [r1]               @ currentHp

    ldrh r4, tempHP             @ tmpHp (PC-relative)

checkSC:
    ldr r1, scStrengthOffset
    add r1, r1, r9
    mov r0, #0
SCLoop:
    cmp r0, r11
    beq skipSCLoop
    ldr r2, [r1]
    cmp r2, #0
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
    ldr r2, threshold
    sub r1, r4, r5
    cmp r1, r2
    ble end

applyEffect:
    ldr r1, ddDurationOffset
    add r1, r1, r10
    ldr r2, ddDurarion
    strh r2, [r1]

restoreHP:
    cmp r5, #0
    beq end

    ldr r1, ddDurationOffset
    add r1, r1, r9
    mov r0, #0
hpRestoreLoop:
    cmp r0, r11
    beq skipHpRestoreLoop
    ldr r2, [r1]
    cmp r2, #0
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
    ldr r1, hpOffset
    add r1, r1, r10
    strh r0, [r1]

end:
    strh r5, tempHP
    b ReturnFromProgram

/******************
VARIABLES FOR MAIN PROGRAM
*******************/
baseAddressE:
    .long 0x020D33A8
hpOffset:
    .long 0x0B12
ddDurationOffset:
    .long 0x0EE8
scStrengthOffset:
    .long 0x0E74

ddDurarion:
    .long 0xA
playerOffset:
    .long 0xF30
threshold:
    .long 0x5

tempHP:
    .long 0x0

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
