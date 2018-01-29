//===-- WebAssemblyAsmParser.cpp - Parse WebAssembly to MCInst instructions ------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "InstPrinter/WebAssemblyInstPrinter.h"
#include "MCTargetDesc/WebAssemblyMCTargetDesc.h"
#include "MCTargetDesc/WebAssemblyTargetStreamer.h"
#include "WebAssemblyOperand.h"
#include "llvm/MC/MCParser/MCTargetAsmParser.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/ADT/Twine.h"
#include "llvm/MC/MCParser/MCAsmLexer.h"
#include "llvm/MC/MCParser/MCAsmParser.h"
#include "llvm/MC/MCParser/MCParsedAsmOperand.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

namespace {
class WebAssemblyAsmParser : public MCTargetAsmParser {
  ParseInstructionInfo *InstInfo;

private:
#define GET_ASSEMBLER_HEADER
#include "WebAssemblyGenAsmMatcher.inc"

// 866
  bool MatchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                               OperandVector &Operands, MCStreamer &Out,
                               uint64_t &ErrorInfo,
                               bool MatchingInlineAsm) override;


// 939
public:

	WebAssemblyAsmParser(const MCSubtargetInfo &sti, MCAsmParser &Parser,
           const MCInstrInfo &mii, const MCTargetOptions &Options)
  	: MCTargetAsmParser(Options, sti, mii) {

		// Initialize the set of available features.
		setAvailableFeatures(ComputeAvailableFeatures(getSTI().getFeatureBits()));
  }

  bool ParseRegister(unsigned &RegNo, SMLoc &StartLoc, SMLoc &EndLoc) override;

  bool ParseInstruction(ParseInstructionInfo &Info, StringRef Name,
                        SMLoc NameLoc, OperandVector &Operands) override;

  bool ParseDirective(AsmToken DirectiveID) override;
};
} // end anonymous namespace

/// @name Auto-generated Match Functions
/// {

static unsigned MatchRegisterName(StringRef Name);

/// }

// 1013
bool WebAssemblyAsmParser::ParseRegister(unsigned &RegNo,
                                 SMLoc &StartLoc, SMLoc &EndLoc) {
  MCAsmParser &Parser = getParser();

  Parser.Lex(); // Eat identifier token.
  return false;
}

// 2199
bool WebAssemblyAsmParser::ParseInstruction(ParseInstructionInfo &Info, StringRef Name,
                                    SMLoc NameLoc, OperandVector &Operands) {
  MCAsmParser &Parser = getParser();
  InstInfo = &Info;
  StringRef PatchedName = Name;

	return false;
}

// 2719
static const char *getSubtargetFeatureName(uint64_t Val);

// 2728
bool WebAssemblyAsmParser::MatchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                                           OperandVector &Operands,
                                           MCStreamer &Out, uint64_t &ErrorInfo,
                                           bool MatchingInlineAsm) {
	return true;
}

// 3154
bool WebAssemblyAsmParser::ParseDirective(AsmToken DirectiveID) {
	return true;
}

// Force static initialization.
extern "C" void LLVMInitializeWebAssemblyAsmParser() {
  RegisterMCAsmParser<WebAssemblyAsmParser> X(getTheWebAssemblyTarget32());
  RegisterMCAsmParser<WebAssemblyAsmParser> Y(getTheWebAssemblyTarget64());
}

#define GET_REGISTER_MATCHER
#define GET_MATCHER_IMPLEMENTATION
#define GET_SUBTARGET_FEATURE_NAME
#include "WebAssemblyGenAsmMatcher.inc"
