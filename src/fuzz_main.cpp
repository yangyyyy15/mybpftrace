// main function for fuzzing
// To build this, add -DBUILD_FUZZ=1 CMake option
// The compiled binary name is "bpftrace_fuzz"

#include <array>
#include <csignal>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <getopt.h>
#include <iostream>
#include <limits>
#include <optional>
#include <sys/resource.h>
#include <sys/utsname.h>
#include <time.h>
#include <unistd.h>

#include "ast/passes/codegen_llvm.h"
#include "ast/passes/field_analyser.h"
#include "ast/passes/semantic_analyser.h"
#include "bpftrace.h"
#include "clang_parser.h"
#include "driver.h"
#include "log.h"
#include "output.h"
#include "tracepoint_format_parser.h"

using namespace bpftrace;

int fuzz_main(const char* data, size_t sz);

#ifdef LIBFUZZER
// main entry for libufuzzer
// libfuzzer.a provides main function
extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t sz)
{
  fuzz_main((const char*)data, sz);
  return 0; // Non-zero return values are reserved for future use.
}
#else
// main function for AFL, etc.
int main(int argc, char* argv[])
{
  // Read inputs
  std::stringstream buf;
  std::string line;
  if (argc <= 1) {
    // Input from stdin (AFL's default)
    while (std::getline(std::cin, line))
      buf << line << std::endl;
  } else {
    // Read from file
    std::string filename(argv[1]);
    std::ifstream file(filename);
    if (file.fail())
      return 1;
    buf << file.rdbuf();
  }
  const auto& str = buf.str();
  return fuzz_main(str.c_str(), str.size());
}

#endif // LIBFUZZER

int fuzz_main(const char* data, size_t sz)
{
  if (data == nullptr || sz == 0)
    return 0;

  if (getuid() != 0)
    return 1;

  DISABLE_LOG(DEBUG);
  DISABLE_LOG(WARNING);
  // We can't disable error logs because some functions use a length of error
  // log to see if an error occurs. Instead, suppress error log output at each
  // place.
  // DISABLE_LOG(ERROR);
  std::ofstream devnull;
  devnull.open("/dev/null", std::ofstream::out | std::ofstream::app);

  // reset global states
  TracepointFormatParser::clear_struct_list();

  std::unique_ptr<Output> output;
  std::ostream* os = &std::cout;
  output = std::make_unique<TextOutput>(*os);

  BPFtrace bpftrace(std::move(output));
  bpftrace.safe_mode_ = 0;

  Driver driver(bpftrace);
  std::string script(data, sz);
  driver.source("fuzz", script);

  // Create AST
  auto err = driver.parse();
  if (err)
    return err;

  // Field Analyzer
  ast::FieldAnalyser fields(driver.ctx, bpftrace, devnull);
  err = fields.analyse();
  if (err)
    return err;

  // Tracepoint parser
  if (TracepointFormatParser::parse(driver.ctx, bpftrace) == false)
    return 1;

  // ClangParser
  ClangParser clang;
  std::vector<std::string> extra_flags;
  {
    struct utsname utsname;
    uname(&utsname);
    std::string ksrc, kobj;
    auto kdirs = get_kernel_dirs(utsname);
    ksrc = std::get<0>(kdirs);
    kobj = std::get<1>(kdirs);

    if (ksrc != "")
      extra_flags = get_kernel_cflags(
          utsname.machine, ksrc, kobj, bpftrace.kconfig);
  }
  if (!clang.parse(driver.root.get(), bpftrace, extra_flags))
    return 1;
  err = driver.parse();
  if (err)
    return err;

  // Semantic Analyzer
  ast::SemanticAnalyser semantics(driver.ctx, bpftrace, devnull, false);
  err = semantics.analyse();
  if (err)
    return err;

#if defined(TEST_SEMANTIC)
  return 0;
#endif

  // Create maps
  err = semantics.create_maps(true);
  if (err)
    return err;

  // Codegen
  ast::CodegenLLVM llvm(driver.ctx, bpftrace);
  BpfBytecode bytecode;
  try {
    llvm.generate_ir();
    llvm.optimize();
    bytecode = llvm.emit(false);
  } catch (const std::system_error& ex) {
    return 1;
  } catch (const std::exception& ex) {
    // failed to compile
    return 1;
  }

  return 0;
}
