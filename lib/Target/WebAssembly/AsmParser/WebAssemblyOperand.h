//===- WebAssemblyOperand.h - Parsed WebAssembly machine instruction ------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_WEBASSEMBLY_ASMPARSER_WEBASSEMBLYOPERAND_H
#define LLVM_LIB_TARGET_WEBASSEMBLY_ASMPARSER_WEBASSEMBLYOPERAND_H

#include "llvm/ADT/StringRef.h"
#include "llvm/MC/MCParser/MCParsedAsmOperand.h"
#include "llvm/Support/Casting.h"

namespace llvm {

/// WebAssemblyOperand - Instances of this class represent a parsed WebAssembly machine
/// instruction.
struct WebAssemblyOperand : public MCParsedAsmOperand {
  enum KindTy { Token, Register, Immediate, Memory, Prefix } Kind;

  struct TokOp {
    const char *Data;
    unsigned Length;
  };

  struct RegOp {
    unsigned RegNo;
  };

  struct PrefOp {
    unsigned Prefixes;
  };

  struct ImmOp {
    const MCExpr *Val;
  };

  struct MemOp {
    unsigned SegReg;
    const MCExpr *Disp;
    unsigned BaseReg;
    unsigned IndexReg;
    unsigned Scale;
    unsigned Size;
    unsigned ModeSize;

    /// If the memory operand is unsized and there are multiple instruction
    /// matches, prefer the one with this size.
    unsigned FrontendSize;
  };

  union {
    struct TokOp Tok;
    struct RegOp Reg;
    struct ImmOp Imm;
    struct MemOp Mem;
    struct PrefOp Pref;
  };

  WebAssemblyOperand(KindTy K)
  	: Kind(K) {}

// 146
  StringRef getToken() const {
    assert(Kind == Token && "Invalid access!");
    return StringRef(Tok.Data, Tok.Length);
  }
// 156
  unsigned getReg() const override {
    assert(Kind == Register && "Invalid access!");
    return Reg.RegNo;
  }

// 166
  const MCExpr *getImm() const {
    assert(Kind == Immediate && "Invalid access!");
    return Imm.Val;
  }

// 451
  void addExpr(MCInst &Inst, const MCExpr *Expr) const {
    // Add as immediates when possible.
    if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(Expr))
      Inst.addOperand(MCOperand::createImm(CE->getValue()));
    else
      Inst.addOperand(MCOperand::createExpr(Expr));
  }

// 459
  void addRegOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::createReg(getReg()));
  }

// 500
  void addImmOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    addExpr(Inst, getImm());
  }

};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_WEBASSEMBLY_ASMPARSER_WEBASSEMBLYOPERAND_H
