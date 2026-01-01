/*************
Metroid Prime Hunters Anti-Lag Code (AUTO BASE v4, US/EU/JP 1.0/1.1)
- Reference structure: matches the "Dalle" style you posted
- clang-safe: replaces .org usage by explicit layout to keep baseAddress at CustomStack+0x34

Candidates:
EU1.0 0x020DA558
EU1.1 0x020DA5D8
US1.0 0x020D9CB8
US1.1 0x020DA538
JP1.0 0x020DBB78
JP1.1 0x020DBB38

Detection rule:
- HP (base + 0xB36) == 99  -> lock baseAddress

Hook:
ReferenceLabel = 0x037FBACC
Return         = 0x037FBB2C
*******/

.long 0xE2000000
.long ReferenceLabel-8
ldr r0, CustomStack
stmdb r0!, {r1-r11, lr}

/*********************
MAIN PROGRAM
*********************/
main:
    /* Check region base address candidates (only if baseAddress == 0) */
    ldr r4, euBase10
    bl checkBasicAddress
    ldr r4, euBase11
    bl checkBasicAddress

    ldr r4, usBase10
    bl checkBasicAddress
    ldr r4, usBase11
    bl checkBasicAddress

    ldr r4, jpBase10
    bl checkBasicAddress
    ldr r4, jpBase11
    bl checkBasicAddress

    /* setup offset */
    ldr r8, playerOffset
    ldr r9, baseAddress          @ r9 = base address (0 if undecided)

    /* if base is not decided yet, exit safely */
    cmp r9, #0
    beq ReturnFromProgram

    ldr r11, [r9]                @ r11 = player number
    mul r10, r8, r11
    add r10,  r10, r9            @ r10 = base + playerNum * offset

loadHP:
    ldr r1, hpOffset
    add r1, r10, r1
    ldrh r5, [r1]                @ currentHp
    ldrh r4, tempHP              @ tmpHp (PC-relative)

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
CONSTANTS & VARIABLES
******************/
hpOffset:           .long 0x00000B36
ddDurationOffset:   .long 0x00000F0C
scStrengthOffset:   .long 0x00000E98

ddDurarion:         .long 0x0000000A
playerOffset:       .long 0x00000F30
threshold:          .long 0x00000005

tempHP:             .long 0x00000000

/* Region bases */
euBase10: .long 0x020DA558
euBase11: .long 0x020DA5D8
usBase10: .long 0x020D9CB8
usBase11: .long 0x020DA538
jpBase10: .long 0x020DBB78
jpBase11: .long 0x020DBB38

/******************
CUSTOM FUNCTIONS
******************/
checkBasicAddress:
    /* if baseAddress != 0 : skip */
    ldr r2, baseAddress
    cmp r2, #0
    bne checkBasicAddressEnd

    /* if *(base + hpOffset) == 99 : baseAddress = base */
    ldr r0, hpOffset
    add r1, r0, r4
    ldrh r0, [r1]
    cmp r0, #99
    bne checkBasicAddressEnd

    /* store r4 into baseAddress (keep baseAddress at CustomStack+0x34 layout) */
    adr r3, baseAddress
    str r4, [r3]

checkBasicAddressEnd:
    bx lr

/******************
RETURN FROM PROGRAM
******************/
ReturnFromProgram:
    ldr r0, CustomStack
    sub r0, r0, #0x30
    ldmia r0!, {r1-r11, lr}
    mov r0, #0x5
    ldr r12, Return
    bx r12

Return:
    .long 0x037FBB2C

/******************
CUSTOM STACK / LAYOUT
******************/
CustomStack:
    .long CustomStack+0x200002C

    /* Reserve 0x30 bytes so that baseAddress becomes CustomStack+0x34 exactly */
    .space 0x30, 0x00

baseAddress:
    .long 0x00000000

EndofProgram:
    .balign 8, 0x00

ReferenceLabel:
    .long 0x037FBACC
    mov pc, #0x2000000
