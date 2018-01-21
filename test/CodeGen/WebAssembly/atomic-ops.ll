; RUN: llc < %s -asm-verbose=false -disable-wasm-fallthrough-return-opt| FileCheck %s
; RUN: llc < %s -asm-verbose=false -disable-wasm-fallthrough-return-opt -fast-isel -fast-isel-abort=1 | FileCheck %s

; Test that basic loads are assembled properly.

target datalayout = "e-m:e-p:32:32-i64:64-n32:64-S128"
target triple = "wasm32-unknown-unknown-wasm"

@var32 = global i32 0

; CHECK-LABEL: atomic_store_i32:
; CHECK-NEXT: .param i32, i32{{$}}
; CHECK-NEXT: get_local $push[[L0:[0-9]+]]=, 0{{$}}
; CHECK-NEXT: get_local $push[[L0:[0-9]+]]=, 0{{$}}
; CHECK-NEXT: i32.atomic.store 0($pop[[L0]]){{$}}, $pop[[L0]]
; CHECK-NEXT return
define void @atomic_store_release_i32(i32 *%p, i32 %v) {
  store atomic i32 %v, i32* %p release, align 4
  ret void
}