//===- WASMAsmParser.cpp - WASM Assembly Parser -----------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "llvm/ADT/StringRef.h"
#include "llvm/MC/MCParser/MCAsmParser.h"
#include "llvm/MC/MCParser/MCAsmParserExtension.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/SMLoc.h"

using namespace llvm;

namespace {

class WASMAsmParser : public MCAsmParserExtension {
  template<bool (WASMAsmParser::*HandlerMethod)(StringRef, SMLoc)>
  void addDirectiveHandler(StringRef Directive) {
    MCAsmParser::ExtensionDirectiveHandler Handler = std::make_pair(
        this, HandleDirective<WASMAsmParser, HandlerMethod>);

    getParser().addDirectiveHandler(Directive, Handler);
  }


public:
  WASMAsmParser() { }

  void Initialize(MCAsmParser &Parser) override {
    // Call the base implementation.
    this->MCAsmParserExtension::Initialize(Parser);
    
    addDirectiveHandler<&WASMAsmParser::ParseDirectiveSection>(".section");
  }

  bool ParseDirectiveSection(StringRef, SMLoc);

private:
	bool ParseSectionName(StringRef &SectionName);
  bool ParseSectionArguments(bool IsPush, SMLoc loc);

};

} // end anonymous namespace

bool WASMAsmParser::ParseSectionName(StringRef &SectionName) {
  // A section name can contain -, so we cannot just use
  // parseIdentifier.
  SMLoc FirstLoc = getLexer().getLoc();
  unsigned Size = 0;

  if (getLexer().is(AsmToken::String)) {
    SectionName = getTok().getIdentifier();
    Lex();
    return false;
  }

  while (!getParser().hasPendingError()) {
    SMLoc PrevLoc = getLexer().getLoc();
    if (getLexer().is(AsmToken::Comma) ||
      getLexer().is(AsmToken::EndOfStatement))
      break;
    
    unsigned CurSize;
    if (getLexer().is(AsmToken::String)) {
      CurSize = getTok().getIdentifier().size() + 2;
      Lex();
    } else if (getLexer().is(AsmToken::Identifier)) {
      CurSize = getTok().getIdentifier().size();
      Lex();
    } else {
      CurSize = getTok().getString().size();
      Lex();
    }
    Size += CurSize;
    SectionName = StringRef(FirstLoc.getPointer(), Size);

    // Make sure the following token is adjacent.
    if (PrevLoc.getPointer() + CurSize != getTok().getLoc().getPointer())
      break;
  }
  if (Size == 0)
    return true;

  return false;
}

// FIXME: This is a work in progress.
bool WASMAsmParser::ParseDirectiveSection(StringRef, SMLoc loc) {
  return ParseSectionArguments(/*IsPush=*/false, loc);
}

static unsigned parseSectionFlags(StringRef flagsStr, bool *UseLastGroup) {
  unsigned flags = 0;

  // If a valid numerical value is set for the section flag, use it verbatim
  if (!flagsStr.getAsInteger(0, flags))
    return flags;

  for (char i : flagsStr) {
    switch (i) {
    case 'a': // no idea what to do
    	return flags;
    default:
      return -1U;
    }
  }
  return flags;
}

bool WASMAsmParser::ParseSectionArguments(bool IsPush, SMLoc loc) {
  StringRef SectionName;
  bool UseLastGroup = false;

  if (ParseSectionName(SectionName))
    return TokError("expected identifier in directive");

  unsigned Flags = 0;

  if (getLexer().is(AsmToken::Comma)) {
    Lex();

    if (IsPush && getLexer().isNot(AsmToken::String)) {
      if (getLexer().isNot(AsmToken::Comma))
        goto EndStmt;
      Lex();
    }
  }

  unsigned extraFlags;
  if (getLexer().isNot(AsmToken::String)) {
    return TokError("expected string in directive");
	} else {
      StringRef FlagsStr = getTok().getStringContents();
      Lex();
      extraFlags = parseSectionFlags(FlagsStr, &UseLastGroup);
	}

  if (extraFlags == -1U)
      return TokError("unknown flag");
    Flags |= extraFlags;EndStmt:
  if (getLexer().isNot(AsmToken::EndOfStatement))
    return TokError("unexpected token in directive");
  Lex();

  return false;
}

namespace llvm {

MCAsmParserExtension *createWASMAsmParser() {
  return new WASMAsmParser;
}

} // end namespace llvm
