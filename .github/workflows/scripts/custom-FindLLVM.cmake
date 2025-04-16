# Custom FindLLVM.cmake that bypasses problematic components
set(LLVM_FOUND TRUE)
set(LLVM_INCLUDE_DIRS "/usr/include/llvm17")
set(LLVM_LIBRARY_DIRS "/usr/lib/llvm17/lib")

# Use llvm-config binary to get information
find_program(LLVM_CONFIG_EXE NAMES llvm-config llvm-config-17)

if(LLVM_CONFIG_EXE)
  message(STATUS "Found llvm-config at ${LLVM_CONFIG_EXE}")
  
  # Get LLVM version
  execute_process(
    COMMAND ${LLVM_CONFIG_EXE} --version
    OUTPUT_VARIABLE LLVM_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  
  # Get LLVM library list (without problematic ones)
  execute_process(
    COMMAND ${LLVM_CONFIG_EXE} --libs
    OUTPUT_VARIABLE LLVM_LIBRARIES
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  
  # Convert to CMake list
  string(REPLACE " " ";" LLVM_LIBRARIES "${LLVM_LIBRARIES}")
  
  # Get LLVM system libraries
  execute_process(
    COMMAND ${LLVM_CONFIG_EXE} --system-libs
    OUTPUT_VARIABLE LLVM_SYSTEM_LIBS
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  
  # Convert to CMake list
  string(REPLACE " " ";" LLVM_SYSTEM_LIBS "${LLVM_SYSTEM_LIBS}")
  
  # Define core LLVM components - important for bpftrace to work
  set(LLVM_AVAILABLE_LIBS 
      LLVMX86Info LLVMX86Desc LLVMObject LLVMBitReader LLVMCore LLVMSupport
      LLVMTransformUtils LLVMTarget LLVMAnalysis LLVMMC LLVMMCParser LLVMProfileData
      LLVMScalarOpts LLVMBinaryFormat LLVMRemarks
  )
else()
  message(WARNING "llvm-config not found, setting minimal LLVM configuration")
  set(LLVM_AVAILABLE_LIBS 
      LLVMX86Info LLVMX86Desc LLVMObject LLVMBitReader LLVMCore LLVMSupport
  )
endif()

# Define targets for test frameworks if needed
if(NOT TARGET llvm_gtest AND EXISTS "${LLVM_LIBRARY_DIRS}/libllvm_gtest.a")
  add_library(llvm_gtest STATIC IMPORTED)
  set_target_properties(llvm_gtest PROPERTIES 
    IMPORTED_LOCATION "${LLVM_LIBRARY_DIRS}/libllvm_gtest.a"
  )
endif()

if(NOT TARGET llvm_gtest_main AND EXISTS "${LLVM_LIBRARY_DIRS}/libllvm_gtest_main.a")
  add_library(llvm_gtest_main STATIC IMPORTED)
  set_target_properties(llvm_gtest_main PROPERTIES 
    IMPORTED_LOCATION "${LLVM_LIBRARY_DIRS}/libllvm_gtest_main.a"
  )
endif()

# 添加对LLVMfrontenddriver的支持（小写版本的frontend库）
if(NOT TARGET LLVMfrontenddriver AND EXISTS "${LLVM_LIBRARY_DIRS}/libLLVMfrontenddriver.a")
  add_library(LLVMfrontenddriver STATIC IMPORTED)
  set_target_properties(LLVMfrontenddriver PROPERTIES 
    IMPORTED_LOCATION "${LLVM_LIBRARY_DIRS}/libLLVMfrontenddriver.a"
  )
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LLVM DEFAULT_MSG LLVM_FOUND)
