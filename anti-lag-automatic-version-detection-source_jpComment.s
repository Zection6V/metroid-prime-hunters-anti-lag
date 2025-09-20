@==============================
@ Metroid Prime Hunters Anti-Lag Code
@ Implementation by Dalle
@ ラグ対策コード：被弾時に一時的にダブルダメージ状態にしてヒットを可視化
@==============================

@----------
@ Addresses / アドレス一覧
@----------
@ playerId = base
@ HP = base + 0xB36
@ DD Duration = base + 0xF0C
@ Coil Strength = base + 0xE98

@ EU Base = 0x020da558
@ JP Base = 0x020dbb78
@ US Base = 0x020d9cb8

@==============================
@ Program Start / プログラム開始
@ スタックの初期化とレジスタ保存
@==============================
.long 0xE2000000
.long ReferenceLabel-8

ldr r0, CustomStack
stmdb r0!, {r1-r11, lr}          @ Save registers / レジスタ保存

@==============================
@ MAIN PROGRAM / メイン処理
@==============================
main:                           @ メイン処理本体

	@ Check region base address / リージョン判定
	ldr r4, euBase
	bl checkBasicAddress
	ldr r4, usBase
	bl checkBasicAddress
	ldr r4, jpBase
	bl checkBasicAddress

	@ Setup base address / プレイヤーごとのベース計算
	ldr r8, playerOffset         @ プレイヤー間のオフセット
	ldr r9, baseAddress
	ldr r11, [r9]                @ プレイヤー番号
	mul r10, r8, r11
	add r10,  r10, r9            @ アドレス = base + playerNum * offset

loadHP:                         @ HPの読み込み
	ldr r1, hpOffset
	add r1, r10, r1
	ldrh r5, [r1]                @ r5 = 現在HP
	ldrh r4, tempHP              @ r4 = 一時保存された前回HP

checkSC:                        @ Shock Coilのチェック
	ldr r1, scStrengthOffset
	add r1, r1, r9
	mov r0, #0                   @ プレイヤーインデックス初期化

SCLoop:                         @ Shock Coilループ（敵のSC確認）
	cmp r0, r11                  @ 自分はスキップ
	beq skipSCLoop
	ldr r2, [r1]
	cmp r2, #0
	bgt applyEffect              @ SCが当たっていれば効果適用

skipSCLoop:                     @ SCループスキップ処理
	add r1, r1, r8
	add r0, #1
	cmp r0, #4
	blt SCLoop

compareHP:                      @ HPを比較してダメージ判定
	cmp r5, r4
	bge end                      @ ダメージを受けていない

checkThreshold:                 @ 最小ダメージ閾値チェック
	ldr r2, threshold
	sub r1, r4, r5
	cmp r1, r2
	ble end                      @ 閾値以下のダメージは無視

applyEffect:                    @ ダブルダメージ効果を適用
	ldr r1, ddDurationOffset
	add r1, r1, r10
	ldr r2, ddDurarion
	strh r2, [r1]                @ 効果時間セット

restoreHP:                      @ HP回復処理の開始
	cmp r5, #0
	beq end                      @ 死亡していれば回復スキップ

	ldr r1, ddDurationOffset
	add r1, r1, r9
	mov r0, #0

hpRestoreLoop:                  @ DD状態の敵確認ループ
	cmp r0, r11
	beq skipHpRestoreLoop
	ldr r2, [r1]
	cmp r2, #0
	bgt doHpRestore

skipHpRestoreLoop:              @ 自分はスキップ
	add r1, r1, r8
	add r0, #1
	cmp r0, #4
	blt hpRestoreLoop
	b end

doHpRestore:                    @ HP回復処理（半分回復）
	sub r1, r4, r5               @ ダメージ量 = tempHP - currentHP
	add r0, r5, r1, lsr #1       @ 回復 = currentHP + damage / 2
	ldr r1, hpOffset
	add r1, r1, r10
	strh r0, [r1]                @ 回復HPを保存

end:                            @ メイン処理終了
	strh r5, tempHP              @ tempHP = currentHP（次回比較用）

@==============================
@ CONSTANTS & VARIABLES / 定数と変数
@==============================

@ オフセット定数
hpOffset:           .long 0xB36
ddDurationOffset:   .long 0xF0C
scStrengthOffset:   .long 0xE98

@ その他定数
ddDurarion:         .long 0xA          @ DDの持続時間
playerOffset:       .long 0xF30        @ 各プレイヤー間のアドレス間隔
threshold:          .long 0x5          @ ダメージ閾値（これ以下は無視）

@ 一時変数
tempHP:             .long 0x0

@==============================
@ RETURN FROM PROGRAM / 終了処理
@==============================
ReturnFromProgram:              @ レジスタをスタックから復元してリターン
	ldr r0, CustomStack
	sub r0, r0, #0x30
	ldmia r0!, {r1-r11, lr}
	mov r0, #0x5
	ldr r12, Return
	bx r12

Return:
	.long 0x37FBB2C

@==============================
@ CUSTOM FUNCTIONS / カスタム関数
@==============================

checkBasicAddress:              @ リージョンベースアドレスの検出
	ldr r2, baseAddress
	cmp r2, #0
	bne checkBasicAddressEnd

	ldr r0, hpOffset
	add r1, r0, r4
	ldrh r0, [r1]
	cmp r0, #99
	streq r4, baseAddress
checkBasicAddressEnd:
	bx lr

debug:                          @ デバッグ用（r0を死亡数に書き込む）
	ldr r1, deathsAddress
	strh r0, [r1]
	bx lr

@==============================
@ DEBUG VARIABLES / デバッグ用アドレス
@==============================
deathsAddress:
	.long 0x020e855c             @ EU Death Count Address

@==============================
@ REGION BASE ADDRESSES / リージョンごとのベースアドレス
@==============================
euBase: .long 0x020da558
jpBase: .long 0x020dbb78
usBase: .long 0x020d9cb8

@==============================
@ CUSTOM STACK / カスタムスタック
@==============================
CustomStack:
	.long CustomStack + 0x200002C

@==============================
@ PROGRAM TERMINATION / プログラム終了設定
@==============================
EndofProgram:
	.org (EndofProgram + 4) & 0xFFFFFFF8

ReferenceLabel:
	.long 0x037FBACC
	mov pc, #0x2000000

@ ベースアドレス格納用
.org CustomStack + 0x34
baseAddress:
	.long 0x0
