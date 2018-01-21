// WebAssemblyInstrAtomics.td-WebAssembly Atomic codegen support-*- tablegen -*-
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
///
/// \file
/// \brief WebAssembly Atomic operand code-gen constructs.
///
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Atomic loads
//===----------------------------------------------------------------------===//

let Defs = [ARGUMENTS] in {
def ATOMIC_LOAD_I32 : WebAssemblyLoad<I32, "i32.atomic.load", 0xfe10>;
def ATOMIC_LOAD_I64 : WebAssemblyLoad<I64, "i64.atomic.load", 0xfe11>;
} // Defs = [ARGUMENTS]

// Select loads with no constant offset.
let Predicates = [HasAtomics] in {
def : LoadPatNoOffset<i32, atomic_load_32, ATOMIC_LOAD_I32>;
def : LoadPatNoOffset<i64, atomic_load_64, ATOMIC_LOAD_I64>;

// Select loads with a constant offset.

// Pattern with address + immediate offset
def : LoadPatImmOff<i32, atomic_load_32, regPlusImm, ATOMIC_LOAD_I32>;
def : LoadPatImmOff<i64, atomic_load_64, regPlusImm, ATOMIC_LOAD_I64>;
def : LoadPatImmOff<i32, atomic_load_32, or_is_add, ATOMIC_LOAD_I32>;
def : LoadPatImmOff<i64, atomic_load_64, or_is_add, ATOMIC_LOAD_I64>;

def : LoadPatGlobalAddr<i32, atomic_load_32, ATOMIC_LOAD_I32>;
def : LoadPatGlobalAddr<i64, atomic_load_64, ATOMIC_LOAD_I64>;

def : LoadPatExternalSym<i32, atomic_load_32, ATOMIC_LOAD_I32>;
def : LoadPatExternalSym<i64, atomic_load_64, ATOMIC_LOAD_I64>;


// Select loads with just a constant offset.
def : LoadPatOffsetOnly<i32, atomic_load_32, ATOMIC_LOAD_I32>;
def : LoadPatOffsetOnly<i64, atomic_load_64, ATOMIC_LOAD_I64>;

def : LoadPatGlobalAddrOffOnly<i32, atomic_load_32, ATOMIC_LOAD_I32>;
def : LoadPatGlobalAddrOffOnly<i64, atomic_load_64, ATOMIC_LOAD_I64>;

def : LoadPatExternSymOffOnly<i32, atomic_load_32, ATOMIC_LOAD_I32>;
def : LoadPatExternSymOffOnly<i64, atomic_load_64, ATOMIC_LOAD_I64>;

} // Predicates = [HasAtomics]

// Extending loads. Note that there are only zero-extending atomic loads, no
// sign-extending loads.
let Defs = [ARGUMENTS] in {
def ATOMIC_LOAD8_U_I32 : WebAssemblyLoad<I32, "i32.atomic.load8_u", 0xfe12>;
def ATOMIC_LOAD16_U_I32 : WebAssemblyLoad<I32, "i32.atomic.load16_u", 0xfe13>;
def ATOMIC_LOAD8_U_I64 : WebAssemblyLoad<I64, "i64.atomic.load8_u", 0xfe14>;
def ATOMIC_LOAD16_U_I64 : WebAssemblyLoad<I64, "i64.atomic.load16_u", 0xfe15>;
def ATOMIC_LOAD32_U_I64 : WebAssemblyLoad<I64, "i64.atomic.load32_u", 0xfe16>;
} // Defs = [ARGUMENTS]

// Fragments for exending loads. These are different from regular loads because
// the SDNodes are derived from AtomicSDNode rather than LoadSDNode and
// therefore don't have the extension type field. So instead of matching that,
// we match the patterns that the type legalizer expands them to.

// We directly match zext patterns and select the zext atomic loads.
// i32 (zext (i8 (atomic_load_8))) gets legalized to
// i32 (and (i32 (atomic_load_8)), 255)
// These can be selected to a single zero-extending atomic load instruction.
def zext_aload_8 : PatFrag<(ops node:$addr),
                           (and (i32 (atomic_load_8 node:$addr)), 255)>;
def zext_aload_16 : PatFrag<(ops node:$addr),
                            (and (i32 (atomic_load_16 node:$addr)), 65535)>;
// Unlike regular loads, extension to i64 is handled differently than i32.
// i64 (zext (i8 (atomic_load_8))) gets legalized to
// i64 (and (i64 (anyext (i32 (atomic_load_8)))), 255)
def zext_aload_8_64 :
  PatFrag<(ops node:$addr),
          (and (i64 (anyext (i32 (atomic_load_8 node:$addr)))), 255)>;
def zext_aload_16_64 :
  PatFrag<(ops node:$addr),
          (and (i64 (anyext (i32 (atomic_load_16 node:$addr)))), 65535)>;
def zext_aload_32_64 :
  PatFrag<(ops node:$addr),
          (zext (i32 (atomic_load node:$addr)))>;

// We don't have single sext atomic load instructions. So for sext loads, we
// match bare subword loads (for 32-bit results) and anyext loads (for 64-bit
// results) and select a zext load; the next instruction will be sext_inreg
// which is selected by itself.
def anyext_aload_8_64 :
  PatFrag<(ops node:$addr), (anyext (i32 (atomic_load_8 node:$addr)))>;
def anyext_aload_16_64 :
  PatFrag<(ops node:$addr), (anyext (i32 (atomic_load_16 node:$addr)))>;

let Predicates = [HasAtomics] in {
// Select zero-extending loads with no constant offset.
def : LoadPatNoOffset<i32, zext_aload_8, ATOMIC_LOAD8_U_I32>;
def : LoadPatNoOffset<i32, zext_aload_16, ATOMIC_LOAD16_U_I32>;
def : LoadPatNoOffset<i64, zext_aload_8_64, ATOMIC_LOAD8_U_I64>;
def : LoadPatNoOffset<i64, zext_aload_16_64, ATOMIC_LOAD16_U_I64>;
def : LoadPatNoOffset<i64, zext_aload_32_64, ATOMIC_LOAD32_U_I64>;

// Select sign-extending loads with no constant offset
def : LoadPatNoOffset<i32, atomic_load_8, ATOMIC_LOAD8_U_I32>;
def : LoadPatNoOffset<i32, atomic_load_16, ATOMIC_LOAD16_U_I32>;
def : LoadPatNoOffset<i64, anyext_aload_8_64, ATOMIC_LOAD8_U_I64>;
def : LoadPatNoOffset<i64, anyext_aload_16_64, ATOMIC_LOAD16_U_I64>;
// 32->64 sext load gets selected as i32.atomic.load, i64.extend_s/i64


// Zero-extending loads with constant offset
def : LoadPatImmOff<i32, zext_aload_8, regPlusImm, ATOMIC_LOAD8_U_I32>;
def : LoadPatImmOff<i32, zext_aload_16, regPlusImm, ATOMIC_LOAD16_U_I32>;
def : LoadPatImmOff<i32, zext_aload_8, or_is_add, ATOMIC_LOAD8_U_I32>;
def : LoadPatImmOff<i32, zext_aload_16, or_is_add, ATOMIC_LOAD16_U_I32>;
def : LoadPatImmOff<i64, zext_aload_8_64, regPlusImm, ATOMIC_LOAD8_U_I64>;
def : LoadPatImmOff<i64, zext_aload_16_64, regPlusImm, ATOMIC_LOAD16_U_I64>;
def : LoadPatImmOff<i64, zext_aload_32_64, regPlusImm, ATOMIC_LOAD32_U_I64>;
def : LoadPatImmOff<i64, zext_aload_8_64, or_is_add, ATOMIC_LOAD8_U_I64>;
def : LoadPatImmOff<i64, zext_aload_16_64, or_is_add, ATOMIC_LOAD16_U_I64>;
def : LoadPatImmOff<i64, zext_aload_32_64, or_is_add, ATOMIC_LOAD32_U_I64>;

// Sign-extending loads with constant offset
def : LoadPatImmOff<i32, atomic_load_8, regPlusImm, ATOMIC_LOAD8_U_I32>;
def : LoadPatImmOff<i32, atomic_load_16, regPlusImm, ATOMIC_LOAD16_U_I32>;
def : LoadPatImmOff<i32, atomic_load_8, or_is_add, ATOMIC_LOAD8_U_I32>;
def : LoadPatImmOff<i32, atomic_load_16, or_is_add, ATOMIC_LOAD16_U_I32>;
def : LoadPatImmOff<i64, anyext_aload_8_64, regPlusImm, ATOMIC_LOAD8_U_I64>;
def : LoadPatImmOff<i64, anyext_aload_16_64, regPlusImm, ATOMIC_LOAD16_U_I64>;
def : LoadPatImmOff<i64, anyext_aload_8_64, or_is_add, ATOMIC_LOAD8_U_I64>;
def : LoadPatImmOff<i64, anyext_aload_16_64, or_is_add, ATOMIC_LOAD16_U_I64>;
// No 32->64 patterns, just use i32.atomic.load and i64.extend_s/i64

def : LoadPatGlobalAddr<i32, zext_aload_8, ATOMIC_LOAD8_U_I32>;
def : LoadPatGlobalAddr<i32, zext_aload_16, ATOMIC_LOAD16_U_I32>;
def : LoadPatGlobalAddr<i64, zext_aload_8_64, ATOMIC_LOAD8_U_I64>;
def : LoadPatGlobalAddr<i64, zext_aload_16_64, ATOMIC_LOAD16_U_I64>;
def : LoadPatGlobalAddr<i64, zext_aload_32_64, ATOMIC_LOAD32_U_I64>;
def : LoadPatGlobalAddr<i32, atomic_load_8, ATOMIC_LOAD8_U_I32>;
def : LoadPatGlobalAddr<i32, atomic_load_16, ATOMIC_LOAD16_U_I32>;
def : LoadPatGlobalAddr<i64, anyext_aload_8_64, ATOMIC_LOAD8_U_I64>;
def : LoadPatGlobalAddr<i64, anyext_aload_16_64, ATOMIC_LOAD16_U_I64>;

def : LoadPatExternalSym<i32, zext_aload_8, ATOMIC_LOAD8_U_I32>;
def : LoadPatExternalSym<i32, zext_aload_16, ATOMIC_LOAD16_U_I32>;
def : LoadPatExternalSym<i64, zext_aload_8_64, ATOMIC_LOAD8_U_I64>;
def : LoadPatExternalSym<i64, zext_aload_16_64, ATOMIC_LOAD16_U_I64>;
def : LoadPatExternalSym<i64, zext_aload_32_64, ATOMIC_LOAD32_U_I64>;
def : LoadPatExternalSym<i32, atomic_load_8, ATOMIC_LOAD8_U_I32>;
def : LoadPatExternalSym<i32, atomic_load_16, ATOMIC_LOAD16_U_I32>;
def : LoadPatExternalSym<i64, anyext_aload_8_64, ATOMIC_LOAD8_U_I64>;
def : LoadPatExternalSym<i64, anyext_aload_16_64, ATOMIC_LOAD16_U_I64>;


// Extending loads with just a constant offset
def : LoadPatOffsetOnly<i32, zext_aload_8, ATOMIC_LOAD8_U_I32>;
def : LoadPatOffsetOnly<i32, zext_aload_16, ATOMIC_LOAD16_U_I32>;
def : LoadPatOffsetOnly<i64, zext_aload_8_64, ATOMIC_LOAD8_U_I64>;
def : LoadPatOffsetOnly<i64, zext_aload_16_64, ATOMIC_LOAD16_U_I64>;
def : LoadPatOffsetOnly<i64, zext_aload_32_64, ATOMIC_LOAD32_U_I64>;
def : LoadPatOffsetOnly<i32, atomic_load_8, ATOMIC_LOAD8_U_I32>;
def : LoadPatOffsetOnly<i32, atomic_load_16, ATOMIC_LOAD16_U_I32>;
def : LoadPatOffsetOnly<i64, anyext_aload_8_64, ATOMIC_LOAD8_U_I64>;
def : LoadPatOffsetOnly<i64, anyext_aload_16_64, ATOMIC_LOAD16_U_I64>;

def : LoadPatGlobalAddrOffOnly<i32, zext_aload_8, ATOMIC_LOAD8_U_I32>;
def : LoadPatGlobalAddrOffOnly<i32, zext_aload_16, ATOMIC_LOAD16_U_I32>;
def : LoadPatGlobalAddrOffOnly<i64, zext_aload_8_64, ATOMIC_LOAD8_U_I64>;
def : LoadPatGlobalAddrOffOnly<i64, zext_aload_16_64, ATOMIC_LOAD16_U_I64>;
def : LoadPatGlobalAddrOffOnly<i64, zext_aload_32_64, ATOMIC_LOAD32_U_I64>;
def : LoadPatGlobalAddrOffOnly<i32, atomic_load_8, ATOMIC_LOAD8_U_I32>;
def : LoadPatGlobalAddrOffOnly<i32, atomic_load_16, ATOMIC_LOAD16_U_I32>;
def : LoadPatGlobalAddrOffOnly<i64, anyext_aload_8_64, ATOMIC_LOAD8_U_I64>;
def : LoadPatGlobalAddrOffOnly<i64, anyext_aload_16_64, ATOMIC_LOAD16_U_I64>;

def : LoadPatExternSymOffOnly<i32, zext_aload_8, ATOMIC_LOAD8_U_I32>;
def : LoadPatExternSymOffOnly<i32, zext_aload_16, ATOMIC_LOAD16_U_I32>;
def : LoadPatExternSymOffOnly<i64, zext_aload_8_64, ATOMIC_LOAD8_U_I64>;
def : LoadPatExternSymOffOnly<i64, zext_aload_16_64, ATOMIC_LOAD16_U_I64>;
def : LoadPatExternSymOffOnly<i64, zext_aload_32_64, ATOMIC_LOAD32_U_I64>;
def : LoadPatExternSymOffOnly<i32, atomic_load_8, ATOMIC_LOAD8_U_I32>;
def : LoadPatExternSymOffOnly<i32, atomic_load_16, ATOMIC_LOAD16_U_I32>;
def : LoadPatExternSymOffOnly<i64, anyext_aload_8_64, ATOMIC_LOAD8_U_I64>;
def : LoadPatExternSymOffOnly<i64, anyext_aload_16_64, ATOMIC_LOAD16_U_I64>;


} // Predicates = [HasAtomics]

//===----------------------------------------------------------------------===//
// Atomic stores
//===----------------------------------------------------------------------===//

let Defs = [ARGUMENTS] in {

class WebAssemblyAtomicStore<int Opcode, WebAssemblyRegClass rc, string Name> :
  I<(outs),
    (ins P2Align:$p2align, offset32_op:$off, I32:$addr, rc:$val),
    [], !strconcat(Name, "\t${off}(${addr})${p2align}, $val"), Opcode>;

def ATOMIC_STORE_I32 : WebAssemblyAtomicStore<0xfe17, I32, "i32.atomic.store">;
def ATOMIC_STORE_I64 : WebAssemblyAtomicStore<0xfe18, I64, "i64.atomic.store">;

def ATOMIC_STORE8_I32  : WebAssemblyAtomicStore<0xfe19, I32, "i32.atomic.store8">;
def ATOMIC_STORE16_I32 : WebAssemblyAtomicStore<0xfe1A, I32, "i64.atomic.store16">;

def ATOMIC_STORE8_I64  : WebAssemblyAtomicStore<0xfe1B, I64, "i64.atomic.store8">;
def ATOMIC_STORE16_I64 : WebAssemblyAtomicStore<0xfe1C, I64, "i64.atomic.store16">;
def ATOMIC_STORE32_I64 : WebAssemblyAtomicStore<0xfe1D, I64, "i64.atomic.store32">;

} // Defs = [ARGUMENTS]


multiclass StorePatAddr<WebAssemblyRegClass rc, PatFrag node, I inst> {
  def : // _PatNoOffset
    Pat<(node I32:$addr, rc:$val), (inst 0, 0, $addr, rc:$val)>;
  
  def  : // _PatRegPlusImmOff
    Pat<(node (regPlusImm I32:$addr, imm:$off), rc:$val),
        (inst 0, imm:$off, I32:$addr, rc:$val)>;

  def : // _PatOrIsAddImmOff
    Pat<(node (or_is_add I32:$addr, imm:$off), rc:$val),
        (inst 0, imm:$off, I32:$addr, rc:$val)>;

  def  : // _PatGlobalAddr
    Pat<(node (regPlusGA I32:$addr, (WebAssemblywrapper tglobaladdr:$off)), rc:$val),
        (inst 0, tglobaladdr:$off, I32:$addr, rc:$val)>;

  def  : // _PatExternalSym
    Pat<(node (add I32:$addr, (WebAssemblywrapper texternalsym:$off)), rc:$val),
      (inst 0, texternalsym:$off, I32:$addr, rc:$val)>;

  //Assertion failed: (isValueTypeByHwMode(true) && "The type set has multiple types for at least one HW mode"), fu
   def : // _PatOffsetOnly
     Pat<(node imm:$off, rc:$val), 
         (inst 0, imm:$off, (CONST_I32 0), $val)>;

  def : // _PatGlobalAddrOffOnly
    Pat<(node (WebAssemblywrapper tglobaladdr:$off), rc:$val),
        (inst 0, tglobaladdr:$off, (CONST_I32 0), rc:$val)>;

  def : // _PatExternSymOffOnly
    Pat<(node (WebAssemblywrapper texternalsym:$off), rc:$val),
        (inst 0, texternalsym:$off, (CONST_I32 0), rc:$val)>;
}

let Predicates = [HasAtomics] in {

defm : StorePatAddr<I32, atomic_store_32, ATOMIC_STORE_I32>;
defm : StorePatAddr<I64, atomic_store_64, ATOMIC_STORE_I64>;

} // Predicates = [HasAtomics]


def trunc_astore : PatFrag<(ops node:$val, node:$addr),
                           (atomic_store node:$val, node:$addr)> {
  let IsStore = 1;
  let IsTruncStore = 1;
}
def trunc_astorei8 : PatFrag<(ops node:$val, node:$addr),
                               (atomic_store node:$val, node:$addr)> {
  let IsStore = 1;
  let MemoryVT = i8;
}
def trunc_astorei16 : PatFrag<(ops node:$val, node:$addr),
                                (atomic_store node:$val, node:$addr)> {
  let IsStore = 1;
  let MemoryVT = i16;
}
def trunc_astorei32 : PatFrag<(ops node:$val, node:$addr),
                                (atomic_store node:$val, node:$addr)> {
  let IsStore = 1;
  let MemoryVT = i32;
}

let Predicates = [HasAtomics] in {

defm : StorePatAddr<I32, trunc_astorei8, ATOMIC_STORE8_I32>;
defm : StorePatAddr<I32, trunc_astorei16, ATOMIC_STORE16_I32>;
defm : StorePatAddr<I64, trunc_astorei8, ATOMIC_STORE8_I64>;
defm : StorePatAddr<I64, trunc_astorei16, ATOMIC_STORE16_I64>;
defm : StorePatAddr<I64, trunc_astorei32, ATOMIC_STORE32_I64>;

} // Predicates = [HasAtomics]

//possible type contradiction in the pattern below (use -print-records with llvm-tblgen to see all expanded records).

// let Defs = [ARGUMENTS] in {
// def ATOMIC_STORE8_I64  : I<(outs), (ins P2Align:$p2align, offset32_op:$off, I32:$addr,
//                             I64:$val), [],
//                    "i64.atomic.store8\t${off}(${addr})${p2align}, $val", 0xfe1B>;
// def ATOMIC_STORE16_I64  : I<(outs), (ins P2Align:$p2align, offset32_op:$off, I32:$addr,
//                             I64:$val), [],
//                    "i64.atomic.store16\t${off}(${addr})${p2align}, $val", 0xfe1C>;
// def ATOMIC_STORE32_I64  : I<(outs), (ins P2Align:$p2align, offset32_op:$off, I32:$addr,
//                             I64:$val), [],
//                    "i64.atomic.store32\t${off}(${addr})${p2align}, $val", 0xfe1D>;
// } // Defs = [ARGUMENTS]

// let Predicates = [HasAtomics] in {
// // Select truncating stores with no constant offset.
// def : Pat<(atomic_store_8 I32:$val, I32:$addr),
//           (ATOMIC_STORE8_I64 0, 0, I32:$addr, I64:$val)>;
// def : Pat<(atomic_store_16 I32:$val, I32:$addr),
//           (ATOMIC_STORE16_I64 0, 0, I32:$addr, I64:$val)>;
// def : Pat<(atomic_store_32 I64:$val, I32:$addr),
//           (ATOMIC_STORE32_I64 0, 0, I32:$addr, I64:$val)>;

// } // Predicates = [HasAtomics]

//===----------------------------------------------------------------------===//
// Low-level exclusive operations
//===----------------------------------------------------------------------===//

// TODO: add exclusive operations here...

// Load-exclusives.

// Store-exclusives.

// Store-release-exclusives.

// And clear exclusive.

//===----------------------------------
// Atomic cmpxchg for -O0
//===----------------------------------

let Defs = [ARGUMENTS] in {

class WebAssemblyAtomicCmpXChg<int Opcode, WebAssemblyRegClass rc, string Name> :
  I<(outs rc:$oldval), 
    (ins P2Align:$p2align, offset32_op:$off, I32:$addr, rc:$cmpval, rc:$newval), 
    [], 
    !strconcat(Name, "\t$oldval, ${off}(${addr})${p2align}, $cmpval, $newval"), Opcode>;

def ATOMIC_RMW_CMPXCHG_I32 : WebAssemblyAtomicCmpXChg<0xfe48, I32, "i32.atomic.rmw.cmpxchg">;
def ATOMIC_RMW_CMPXCHG_I64 : WebAssemblyAtomicCmpXChg<0xfe49, I64, "i64.atomic.rmw.cmpxchg">;

def ATOMIC_RMW_CMPXCHG8_U_I32  : WebAssemblyAtomicCmpXChg<0xfe4A, I32, "i32.atomic.rmw8_u.cmpxchg">;
def ATOMIC_RMW_CMPXCHG16_U_I32 : WebAssemblyAtomicCmpXChg<0xfe4B, I32, "i32.atomic.rmw16_u.cmpxchg">;
def ATOMIC_RMW_CMPXCHG8_U_I64  : WebAssemblyAtomicCmpXChg<0xfe4C, I64, "i64.atomic.rmw8_u.cmpxchg">;
def ATOMIC_RMW_CMPXCHG16_U_I64 : WebAssemblyAtomicCmpXChg<0xfe4D, I64, "i64.atomic.rmw16_u.cmpxchg">;
def ATOMIC_RMW_CMPXCHG32_U_I64 : WebAssemblyAtomicCmpXChg<0xfe4E, I64, "i64.atomic.rmw32_u.cmpxchg">;

} // Defs = [ARGUMENTS]

multiclass CmpXchgPatMemarg<ValueType ty, WebAssemblyRegClass rc, PatFrag node, I inst> {
  def : // _PatNoOffset
    Pat<(ty (node I32:$addr, rc:$cmpval, rc:$newval)), (inst 0, 0, $addr, rc:$cmpval, rc:$newval)>;
  
  def  : // _PatRegPlusImmOff
    Pat<(ty (node (regPlusImm I32:$addr, imm:$off), rc:$cmpval, rc:$newval)),
        (inst 0, imm:$off, I32:$addr, rc:$cmpval, rc:$newval)>;

  def : // _PatOrIsAddImmOff
    Pat<(ty (node (or_is_add I32:$addr, imm:$off), rc:$cmpval, rc:$newval)),
        (inst 0, imm:$off, I32:$addr, rc:$cmpval, rc:$newval)>;

  def  : // _PatGlobalAddr
    Pat<(ty (node (regPlusGA I32:$addr, (WebAssemblywrapper tglobaladdr:$off)), rc:$cmpval, rc:$newval)),
        (inst 0, tglobaladdr:$off, I32:$addr, rc:$cmpval, rc:$newval)>;

  def  : // _PatExternalSym
    Pat<(ty (node (add I32:$addr, (WebAssemblywrapper texternalsym:$off)), rc:$cmpval, rc:$newval)),
      (inst 0, texternalsym:$off, I32:$addr, rc:$cmpval, rc:$newval)>;

  //Assertion failed: (isValueTypeByHwMode(true) && "The type set has multiple types for at least one HW mode"), fu
   def : // _PatOffsetOnly
     Pat<(ty (node imm:$off, rc:$cmpval, rc:$newval)), 
         (inst 0, imm:$off, (CONST_I32 0), rc:$cmpval, rc:$newval)>;

  def : // _PatGlobalAddrOffOnly
    Pat<(ty (node (WebAssemblywrapper tglobaladdr:$off), rc:$cmpval, rc:$newval)),
        (inst 0, tglobaladdr:$off, (CONST_I32 0), rc:$cmpval, rc:$newval)>;

  def : // _PatExternSymOffOnly
    Pat<(ty (node (WebAssemblywrapper texternalsym:$off), rc:$cmpval, rc:$newval)),
        (inst 0, texternalsym:$off, (CONST_I32 0), rc:$cmpval, rc:$newval)>;
}

let Predicates = [HasAtomics] in {
defm : CmpXchgPatMemarg<i32, I32, atomic_cmp_swap_32, ATOMIC_RMW_CMPXCHG_I32>;
defm : CmpXchgPatMemarg<i64, I64, atomic_cmp_swap_64, ATOMIC_RMW_CMPXCHG_I64>;

} // Predicates = [HasAtomics]


// AtomicLoadAdd
let Defs = [ARGUMENTS] in {

class WebAssemblyAtomicRmwOp<int Opcode, WebAssemblyRegClass rc, string Name> :
  I<(outs rc:$val), 
    (ins P2Align:$p2align, offset32_op:$off, I32:$addr, rc:$delta), 
    [], 
    !strconcat(Name, "\t$val, ${off}(${addr})${p2align}, $delta"), Opcode>;


def ATOMIC_RMW_ADD_I32     : WebAssemblyAtomicRmwOp<0xfe1e, I32, "i32.atomic.rmw.add">;
def ATOMIC_RMW_ADD_I64     : WebAssemblyAtomicRmwOp<0xfe1f, I64, "i64.atomic.rmw.add">;
def ATOMIC_RMW8_U_ADD_I32  : WebAssemblyAtomicRmwOp<0xfe20, I32, "i32.atomic.rmw8_u.add">;
def ATOMIC_RMW16_U_ADD_I32 : WebAssemblyAtomicRmwOp<0xfe21, I32, "i32.atomic.rmw16_u.add">;
def ATOMIC_RMW8_U_ADD_I64  : WebAssemblyAtomicRmwOp<0xfe22, I64, "i64.atomic.rmw8_u.add">;
def ATOMIC_RMW16_U_ADD_I64 : WebAssemblyAtomicRmwOp<0xfe23, I64, "i64.atomic.rmw16_u.add">;
def ATOMIC_RMW32_U_ADD_I64 : WebAssemblyAtomicRmwOp<0xfe24, I64, "i64.atomic.rmw32_u.add">;

} // Defs = [ARGUMENTS]

let Predicates = [HasAtomics] in {

multiclass LoadAddPatMemarg<ValueType ty, WebAssemblyRegClass rc, PatFrag node, I inst> {
  def : // _PatNoOffset
    Pat<(ty (node I32:$addr, rc:$delta)), (inst 0, 0, I32:$addr, rc:$delta)>;
  
  def  : // _PatRegPlusImmOff
    Pat<(ty (node (regPlusImm I32:$addr, imm:$off), rc:$delta)),
        (inst 0, imm:$off, I32:$addr, rc:$delta)>;

  def : // _PatOrIsAddImmOff
    Pat<(ty (node (or_is_add I32:$addr, imm:$off), rc:$delta)),
        (inst 0, imm:$off, I32:$addr, rc:$delta)>;

  def  : // _PatGlobalAddr
    Pat<(ty (node (regPlusGA I32:$addr, (WebAssemblywrapper tglobaladdr:$off)), rc:$delta)),
        (inst 0, tglobaladdr:$off, I32:$addr, rc:$delta)>;

  def  : // _PatExternalSym
    Pat<(ty (node (add I32:$addr, (WebAssemblywrapper texternalsym:$off)), rc:$delta)),
      (inst 0, texternalsym:$off, I32:$addr, rc:$delta)>;

  //Assertion failed: (isValueTypeByHwMode(true) && "The type set has multiple types for at least one HW mode"), fu
   def : // _PatOffsetOnly
     Pat<(ty (node imm:$off, rc:$delta)), 
         (inst 0, imm:$off, (CONST_I32 0), rc:$delta)>;

  def : // _PatGlobalAddrOffOnly
    Pat<(ty (node (WebAssemblywrapper tglobaladdr:$off), rc:$delta)),
        (inst 0, tglobaladdr:$off, (CONST_I32 0), rc:$delta)>;

  def : // _PatExternSymOffOnly
    Pat<(ty (node (WebAssemblywrapper texternalsym:$off), rc:$delta)),
        (inst 0, texternalsym:$off, (CONST_I32 0), rc:$delta)>;
}

defm : LoadAddPatMemarg<i32, I32, atomic_load_add_32, ATOMIC_RMW_ADD_I32>;
defm : LoadAddPatMemarg<i64, I64, atomic_load_add_64, ATOMIC_RMW_ADD_I64>; 

} // Predicates = [HasAtomics]


// AtomicLoadAdd
let Defs = [ARGUMENTS] in {

def ATOMIC_RMW_AND_I32     : WebAssemblyAtomicRmwOp<0xfe2c, I32, "i32.atomic.rmw.and">;
def ATOMIC_RMW_AND_I64     : WebAssemblyAtomicRmwOp<0xfe2d, I64, "i64.atomic.rmw.and">;
def ATOMIC_RMW8_U_AND_I32  : WebAssemblyAtomicRmwOp<0xfe2e, I32, "i32.atomic.rmw8_u.and">;
def ATOMIC_RMW16_U_AND_I32 : WebAssemblyAtomicRmwOp<0xfe2f, I32, "i32.atomic.rmw16_u.and">;
def ATOMIC_RMW8_U_AND_I64  : WebAssemblyAtomicRmwOp<0xfe30, I64, "i64.atomic.rmw8_u.and">;
def ATOMIC_RMW16_U_AND_I64 : WebAssemblyAtomicRmwOp<0xfe31, I64, "i64.atomic.rmw16_u.and">;
def ATOMIC_RMW32_U_AND_I64 : WebAssemblyAtomicRmwOp<0xfe32, I64, "i64.atomic.rmw32_u.and">;

} // Defs = [ARGUMENTS]

let Predicates = [HasAtomics] in {

defm : LoadAddPatMemarg<i32, I32, atomic_load_and_32, ATOMIC_RMW_AND_I32>;
defm : LoadAddPatMemarg<i64, I64, atomic_load_and_64, ATOMIC_RMW_AND_I64>; 

} // Predicates = [HasAtomics]

// AtomicLoadAdd
let Defs = [ARGUMENTS] in {

def ATOMIC_RMW_OR_I32     : WebAssemblyAtomicRmwOp<0xfe33, I32, "i32.atomic.rmw.or">;
def ATOMIC_RMW_OR_I64     : WebAssemblyAtomicRmwOp<0xfe34, I64, "i64.atomic.rmw.or">;
def ATOMIC_RMW8_U_OR_I32  : WebAssemblyAtomicRmwOp<0xfe35, I32, "i32.atomic.rmw8_u.or">;
def ATOMIC_RMW16_U_OR_I32 : WebAssemblyAtomicRmwOp<0xfe36, I32, "i32.atomic.rmw16_u.or">;
def ATOMIC_RMW8_U_OR_I64  : WebAssemblyAtomicRmwOp<0xfe37, I64, "i64.atomic.rmw8_u.or">;
def ATOMIC_RMW16_U_OR_I64 : WebAssemblyAtomicRmwOp<0xfe38, I64, "i64.atomic.rmw16_u.or">;
def ATOMIC_RMW32_U_OR_I64 : WebAssemblyAtomicRmwOp<0xfe39, I64, "i64.atomic.rmw32_u.or">;

} // Defs = [ARGUMENTS]

let Predicates = [HasAtomics] in {
defm : LoadAddPatMemarg<i32, I32, atomic_load_or_32, ATOMIC_RMW_OR_I32>;
defm : LoadAddPatMemarg<i64, I64, atomic_load_or_64, ATOMIC_RMW_OR_I64>; 

defm : LoadAddPatMemarg<i32, I32, atomic_load_or_8,  ATOMIC_RMW8_U_OR_I32>;
defm : LoadAddPatMemarg<i32, I32, atomic_load_or_16, ATOMIC_RMW16_U_OR_I32>;
defm : LoadAddPatMemarg<i64, I64, atomic_load_or_8,  ATOMIC_RMW8_U_OR_I64>; 
defm : LoadAddPatMemarg<i64, I64, atomic_load_or_16, ATOMIC_RMW16_U_OR_I64>; 
defm : LoadAddPatMemarg<i64, I64, atomic_load_or_32, ATOMIC_RMW32_U_OR_I64>; 

} // Predicates = [HasAtomics]

// AtomicLoadAdd
let Defs = [ARGUMENTS] in {

def ATOMIC_RMW_XOR_I32     : WebAssemblyAtomicRmwOp<0xfe3a, I32, "i32.atomic.rmw.xor">;
def ATOMIC_RMW_XOR_I64     : WebAssemblyAtomicRmwOp<0xfe3b, I64, "i64.atomic.rmw.xor">;
def ATOMIC_RMW8_U_XOR_I32  : WebAssemblyAtomicRmwOp<0xfe3c, I32, "i32.atomic.rmw8_u.xor">;
def ATOMIC_RMW16_U_XOR_I32 : WebAssemblyAtomicRmwOp<0xfe3d, I32, "i32.atomic.rmw16_u.xor">;
def ATOMIC_RMW8_U_XOR_I64  : WebAssemblyAtomicRmwOp<0xfe3e, I64, "i64.atomic.rmw8_u.xor">;
def ATOMIC_RMW16_U_XOR_I64 : WebAssemblyAtomicRmwOp<0xfe3f, I64, "i64.atomic.rmw16_u.xor">;
def ATOMIC_RMW32_U_XOR_I64 : WebAssemblyAtomicRmwOp<0xfe40, I64, "i64.atomic.rmw32_u.xor">;

} // Defs = [ARGUMENTS]

let Predicates = [HasAtomics] in {
defm : LoadAddPatMemarg<i32, I32, atomic_load_xor_32, ATOMIC_RMW_XOR_I32>;
defm : LoadAddPatMemarg<i64, I64, atomic_load_xor_64, ATOMIC_RMW_XOR_I64>; 

defm : LoadAddPatMemarg<i32, I32, atomic_load_xor_8,  ATOMIC_RMW8_U_XOR_I32>;
defm : LoadAddPatMemarg<i32, I32, atomic_load_xor_16, ATOMIC_RMW16_U_XOR_I32>;
defm : LoadAddPatMemarg<i64, I64, atomic_load_xor_8,  ATOMIC_RMW8_U_XOR_I64>; 
defm : LoadAddPatMemarg<i64, I64, atomic_load_xor_16, ATOMIC_RMW16_U_XOR_I64>; 
defm : LoadAddPatMemarg<i64, I64, atomic_load_xor_32, ATOMIC_RMW32_U_XOR_I64>; 

} // Predicates = [HasAtomics]

// AtomicLoadAdd
let Defs = [ARGUMENTS] in {

def ATOMIC_RMW_XCHG_I32     : WebAssemblyAtomicRmwOp<0xfe3a, I32, "i32.atomic.rmw.xchg">;
def ATOMIC_RMW_XCHG_I64     : WebAssemblyAtomicRmwOp<0xfe3b, I64, "i64.atomic.rmw.xchg">;
def ATOMIC_RMW8_U_XCHG_I32  : WebAssemblyAtomicRmwOp<0xfe3c, I32, "i32.atomic.rmw8_u.xchg">;
def ATOMIC_RMW16_U_XCHG_I32 : WebAssemblyAtomicRmwOp<0xfe3d, I32, "i32.atomic.rmw16_u.xchg">;
def ATOMIC_RMW8_U_XCHG_I64  : WebAssemblyAtomicRmwOp<0xfe3e, I64, "i64.atomic.rmw8_u.xchg">;
def ATOMIC_RMW16_U_XCHG_I64 : WebAssemblyAtomicRmwOp<0xfe3f, I64, "i64.atomic.rmw16_u.xchg">;
def ATOMIC_RMW32_U_XCHG_I64 : WebAssemblyAtomicRmwOp<0xfe40, I64, "i64.atomic.rmw32_u.xchg">;

} // Defs = [ARGUMENTS]

let Predicates = [HasAtomics] in {
defm : LoadAddPatMemarg<i32, I32, atomic_swap_32, ATOMIC_RMW_XCHG_I32>;
defm : LoadAddPatMemarg<i64, I64, atomic_swap_64, ATOMIC_RMW_XCHG_I64>; 

defm : LoadAddPatMemarg<i32, I32, atomic_swap_8,  ATOMIC_RMW8_U_XCHG_I32>;
defm : LoadAddPatMemarg<i32, I32, atomic_swap_16, ATOMIC_RMW16_U_XCHG_I32>;
defm : LoadAddPatMemarg<i64, I64, atomic_swap_8,  ATOMIC_RMW8_U_XCHG_I64>; 
defm : LoadAddPatMemarg<i64, I64, atomic_swap_16, ATOMIC_RMW16_U_XCHG_I64>; 
defm : LoadAddPatMemarg<i64, I64, atomic_swap_32, ATOMIC_RMW32_U_XCHG_I64>; 

} // Predicates = [HasAtomics]