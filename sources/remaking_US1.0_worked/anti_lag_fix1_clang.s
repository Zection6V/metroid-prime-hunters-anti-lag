/*************
Metroid Prime Hunters Anti Lag Code
Impementation by Dalle

Addresses
playerId = base
HP           = base + 0xB36
DD Duration  = base + 0xF0C
Coil Strength= base + 0xE98

EU Base = 0x020DA558
JP Base = 0x020DBB78
US Base = 0x020D9CB8
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
    /* setup offset */
    ldr r8, playerOffset        @ r8 = player offset
    ldr r9, baseAddress         @ r9 = base address
    ldr r11, [r9]               @ r11 = player number
    mul r10, r8, r11
    add r10,  r10, r9           @ r10 = base address + player number * offset

loadHP:
    /* load current hp and temp hp */
    ldr r1, hpOffset
    add r1, r10, r1
    ldrh r5, [r1]               @ r5 = currentHp

    /* 重要: tempHPはPC相対で読む(常駐コードの相対配置を維持) */
    ldrh r4, tempHP             @ r4 = tmpHp

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
    /* currentHp < tmpHp ? */
    cmp r5, r4
    bge end

checkThreshold:
    /* skip if dmg is <= threshold */
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
    sub r1, r4, r5             @ temphp-currenthp
    add r0, r5, r1, lsr #1
    ldr r1, hpOffset
    add r1, r1, r10
    strh r0, [r1]

end:
    /* 重要: tempHPもPC相対で書く */
    strh r5, tempHP             @ tempHP = currentHp

/******************
VARIABLES FOR MAIN PROGRAM
*******************/

@ Offset Constants
baseAddress:
    .long 0x020d9cb8
hpOffset:
    .long 0xB36
ddDurationOffset:
    .long 0xF0C
scStrengthOffset:
    .long 0xE98

@ Other Constants
ddDurarion:
    .long 0xA
playerOffset:
    .long 0xF30
threshold:
    .long 0x5

@ Variables
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
    .long 0x37FBB2C

/***************
Cleaning rest up and terminating program
*****************/
CustomStack:
    .long CustomStack+0x200002C

    /* 元コードの ".org CustomStack+0x34" 相当: CustomStack先頭から合計0x34バイト確保 */
    .space 0x30, 0x00

EndofProgram:
    /* 元コードの ".org (EndofProgram+4)&0xFFFFFFF8" をclang互換で再現: 8バイト境界に揃える */
    .balign 8, 0x00

ReferenceLabel:
    .long 0x037FBACC
    mov pc, #0x2000000
