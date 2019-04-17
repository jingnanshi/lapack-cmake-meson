# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:

FindLapack
----------

* Michael Hirsch, Ph.D. www.scivision.dev
* David Eklund

Let Michael know if there are more MKL / Lapack / compiler combination you want.
Refer to https://software.intel.com/en-us/articles/intel-mkl-link-line-advisor

Finds LAPACK libraries for C / C++ / Fortran.
Works with Netlib Lapack / LapackE, Atlas and Intel MKL.
Intel MKL relies on having environment variable MKLROOT set, typically by sourcing
mklvars.sh beforehand.

Why not the FindLapack.cmake built into CMake? It has a lot of old code for
infrequently used Lapack libraries and is unreliable for me.

Tested on Linux, MacOS and Windows with:
* GCC / Gfortran
* Clang / Flang
* PGI (pgcc, pgfortran)
* Intel (icc, ifort)


Parameters
^^^^^^^^^^

COMPONENTS default to Netlib LAPACK / LapackE, otherwise:

``IntelPar``
  Intel MKL with Intel OpenMP for ICC, GCC and PGCC
``IntelSeq``
  Intel MKL without threading for ICC, GCC, and PGCC
``MKL64``
  MKL only: 64-bit integers  (default is 32-bit integers)

``LAPACKE``
  Netlib LapackE for C / C++
``Netlib``
  Netlib Lapack for Fortran

``LAPACK95``
  get Lapack95 interfaces for MKL or Netlib (must also specify one of IntelPar, IntelSeq, Netlib)


Result Variables
^^^^^^^^^^^^^^^^

``LAPACK_FOUND``
  Lapack libraries were found
``LAPACK_<component>_FOUND``
  LAPACK <component> specified was found
``LAPACK_LIBRARIES``
  Lapack library files (including BLAS
``LAPACK_INCLUDE_DIRS``
  Lapack include directories (for C/C++)


References
^^^^^^^^^^

* Pkg-Config and MKL:  https://software.intel.com/en-us/articles/intel-math-kernel-library-intel-mkl-and-pkg-config-tool
* MKL for Windows: https://software.intel.com/en-us/mkl-windows-developer-guide-static-libraries-in-the-lib-intel64-win-directory
* MKL Windows directories: https://software.intel.com/en-us/mkl-windows-developer-guide-high-level-directory-structure
* Atlas http://math-atlas.sourceforge.net/errata.html#LINK
* MKL LAPACKE (C, C++): https://software.intel.com/en-us/mkl-linux-developer-guide-calling-lapack-blas-and-cblas-routines-from-c-c-language-environments
#]=======================================================================]

# ===== functions ==========

function(atlas_libs)

if(NOT WIN32)
  find_package(Threads)  # not required--for example Flang
endif()

find_library(ATLAS_LIB
  NAMES atlas)

pkg_check_modules(LAPACK_ATLAS lapack-atlas)

find_library(LAPACK_ATLAS
  NAMES ptlapack lapack_atlas lapack
  HINTS ${LAPACK_ATLAS_LIBRARY_DIRS})

pkg_check_modules(LAPACK_BLAS blas-atlas)

find_library(BLAS_LIBRARY
  NAMES ptf77blas f77blas blas
  HINTS ${LAPACK_BLAS_LIBRARY_DIRS})
# === C ===
find_library(BLAS_C_ATLAS
  NAMES ptcblas cblas
  HINTS ${LAPACK_BLAS_LIBRARY_DIRS})

find_path(LAPACK_INCLUDE_DIR
  NAMES cblas.h clapack.h
  HINTS ${LAPACK_BLAS_INCLUDE_DIRS})

#===========
if(LAPACK_ATLAS AND BLAS_C_ATLAS AND BLAS_LIBRARY AND ATLAS_LIB)
  set(LAPACK_Atlas_FOUND true PARENT_SCOPE)
  set(LAPACK_LIBRARY ${LAPACK_ATLAS} ${BLAS_C_ATLAS} ${BLAS_LIBRARY} ${ATLAS_LIB})
  if(NOT WIN32)
    list(APPEND LAPACK_LIBRARY ${CMAKE_THREAD_LIBS_INIT})
  endif()
endif()

set(LAPACK_LIBRARY ${LAPACK_LIBRARY} PARENT_SCOPE)
set(LAPACK_INCLUDE_DIR ${LAPACK_INCLUDE_DIR} PARENT_SCOPE)

endfunction(atlas_libs)

#=======================

function(netlib_libs)

if(LAPACK95 IN_LIST LAPACK_FIND_COMPONENTS)
  find_path(LAPACK95_INCLUDE_DIR
              NAMES f95_lapack.mod
              PATHS ${LAPACK95_ROOT})

  find_library(LAPACK95_LIBRARY
                 NAMES lapack95
                 PATHS ${LAPACK95_ROOT})

  if(LAPACK95_LIBRARY AND LAPACK95_INCLUDE_DIR)
    set(LAPACK_INCLUDE_DIR ${LAPACK95_INCLUDE_DIR})
    set(LAPACK_LAPACK95_FOUND true PARENT_SCOPE)
    set(LAPACK_LIBRARY ${LAPACK95_LIBRARY})
  else()
    return()
  endif()
endif()

pkg_check_modules(LAPACK lapack-netlib)
find_library(LAPACK_LIB
  NAMES lapack
  HINTS ${LAPACK_LIBRARY_DIRS})
if(LAPACK_LIB)
  list(APPEND LAPACK_LIBRARY ${LAPACK_LIB})
else()
  return()
endif()

if(LAPACKE IN_LIST LAPACK_FIND_COMPONENTS)
  pkg_check_modules(LAPACKE lapacke)
  find_library(LAPACKE_LIBRARY
    NAMES lapacke
    HINTS ${LAPACKE_LIBRARY_DIRS})

  find_path(LAPACKE_INCLUDE_DIR
    NAMES lapacke.h
    HINTS ${LAPACKE_INCLUDE_DIRS})

  if(LAPACKE_LIBRARY AND LAPACKE_INCLUDE_DIR)
    set(LAPACK_LAPACKE_FOUND true PARENT_SCOPE)
    list(APPEND LAPACK_INCLUDE_DIR ${LAPACKE_INCLUDE_DIR})
    list(APPEND LAPACK_LIBRARY ${LAPACKE_LIBRARY})
  else()
    message(WARNING "Trouble finding LAPACKE:
      include: ${LAPACKE_INCLUDE_DIR}
      libs: ${LAPACKE_LIBRARY}")
    return()
  endif()

  mark_as_advanced(LAPACKE_LIBRARY LAPACKE_INCLUDE_DIR)
endif()

pkg_check_modules(BLAS blas-netlib)
find_library(BLAS_LIBRARY
  NAMES refblas blas
  HINTS ${BLAS_LIBRARY_DIRS})

if(BLAS_LIBRARY)
  list(APPEND LAPACK_LIBRARY ${LAPACK_LIB} ${BLAS_LIBRARY})
  set(LAPACK_Netlib_FOUND true PARENT_SCOPE)
else()
  return()
endif()

if(NOT WIN32)
  list(APPEND LAPACK_LIBRARY ${CMAKE_THREAD_LIBS_INIT})
endif()

set(LAPACK_LIBRARY ${LAPACK_LIBRARY} PARENT_SCOPE)
set(LAPACK_INCLUDE_DIR ${LAPACK_INCLUDE_DIR} PARENT_SCOPE)

endfunction(netlib_libs)

#===============================

function(find_mkl_libs)
# https://software.intel.com/en-us/articles/intel-mkl-link-line-advisor

set(_mkl_libs ${ARGV})
if(NOT WIN32 AND CMAKE_Fortran_COMPILER_ID STREQUAL GNU AND Fortran IN_LIST project_languages)
  list(INSERT _mkl_libs 0 mkl_gf_${_mkl_bitflag}lp64)
endif()

foreach(s ${_mkl_libs})
  find_library(LAPACK_${s}_LIBRARY
           NAMES ${s}
           PATHS ENV MKLROOT
           PATH_SUFFIXES
             lib lib/intel64 lib/intel64_win
             ../compiler/lib ../compiler/lib/intel64 ../compiler/lib/intel64_win
           HINTS ${MKL_LIBRARY_DIRS}
           NO_DEFAULT_PATH)

  if(NOT LAPACK_${s}_LIBRARY)
    message(WARNING "MKL component not found: " ${s})
    return()
  endif()

  list(APPEND LAPACK_LIB ${LAPACK_${s}_LIBRARY})
endforeach()

if(NOT BUILD_SHARED_LIBS AND (UNIX AND NOT APPLE))
  set(LAPACK_LIB -Wl,--start-group ${LAPACK_LIB} -Wl,--end-group)
endif()

if(NOT WIN32)
  list(APPEND LAPACK_LIB ${CMAKE_THREAD_LIBS_INIT} ${CMAKE_DL_LIBS} m)
endif()

set(LAPACK_LIBRARY ${LAPACK_LIB} PARENT_SCOPE)
set(LAPACK_INCLUDE_DIR
  $ENV{MKLROOT}/include
  $ENV{MKLROOT}/include/intel64/${_mkl_bitflag}lp64
  ${MKL_INCLUDE_DIRS}
  PARENT_SCOPE)

endfunction(find_mkl_libs)

# ========== main program

cmake_policy(VERSION 3.3)

unset(LAPACK_LIBRARY)

if(NOT (Netlib IN_LIST LAPACK_FIND_COMPONENTS OR Atlas IN_LIST LAPACK_FIND_COMPONENTS
        OR IntelPar IN_LIST LAPACK_FIND_COMPONENTS OR IntelSeq IN_LIST LAPACK_FIND_COMPONENTS))
  if(NOT DEFINED USEMKL AND DEFINED ENV{MKLROOT})
    set(USEMKL 1)
    list(APPEND LAPACK_FIND_COMPONENTS IntelPar)
  else()
    list(APPEND LAPACK_FIND_COMPONENTS Netlib)
  endif()
endif()

message(STATUS "Finding LAPACK components: ${LAPACK_FIND_COMPONENTS}")

get_property(project_languages GLOBAL PROPERTY ENABLED_LANGUAGES)

find_package(PkgConfig)

# ==== generic MKL variables ====

if(IntelPar IN_LIST LAPACK_FIND_COMPONENTS OR IntelSeq IN_LIST LAPACK_FIND_COMPONENTS)
  if(NOT WIN32)
    find_package(Threads)  # not required--for example Flang
  endif()

  if(BUILD_SHARED_LIBS)
    set(_mkltype dynamic)
  else()
    set(_mkltype static)
  endif()

  if(MKL64 IN_LIST LAPACK_FIND_COMPONENTS)
    set(_mkl_bitflag i)
  else()
    set(_mkl_bitflag)
  endif()
endif()

#=== switchyard

if(IntelPar IN_LIST LAPACK_FIND_COMPONENTS)
  pkg_check_modules(MKL mkl-${_mkltype}-${_mkl_bitflag}lp64-iomp)

  if(WIN32)
    set(_mp libiomp5md)  # "lib" is indeed necessary, verified by multiple people on CMake 3.14.0
  else()
    set(_mp iomp5)
  endif()

  unset(_mkl_libs)
  if(LAPACK95 IN_LIST LAPACK_FIND_COMPONENTS)
    list(APPEND _mkl_libs mkl_blas95_${_mkl_bitflag}lp64 mkl_lapack95_${_mkl_bitflag}lp64)
  endif()
  list(APPEND _mkl_libs mkl_intel_${_mkl_bitflag}lp64 mkl_intel_thread mkl_core ${_mp})

  find_mkl_libs(${_mkl_libs})

  if(LAPACK_LIBRARY)
    set(LAPACK_IntelPar_FOUND true)
    if(MKL64 IN_LIST LAPACK_FIND_COMPONENTS)
      set(LAPACK_MKL64_FOUND true)
    endif()
    if(LAPACK95 IN_LIST LAPACK_FIND_COMPONENTS)
      set(LAPACK_LAPACK95_FOUND true)
    endif()
  endif()
elseif(IntelSeq IN_LIST LAPACK_FIND_COMPONENTS)
  pkg_check_modules(MKL mkl-${_mkltype}-${_mkl_bitflag}lp64-seq)

  unset(_mkl_libs)
  if(LAPACK95 IN_LIST LAPACK_FIND_COMPONENTS)
    list(APPEND _mkl_libs mkl_blas95_${_mkl_bitflag}lp64 mkl_lapack95_${_mkl_bitflag}lp64)
  endif()
  list(APPEND _mkl_libs mkl_intel_${_mkl_bitflag}lp64 mkl_sequential mkl_core)
  mkl_libs(${_mkl_libs})

  if(LAPACK_LIBRARY)
    set(LAPACK_IntelSeq_FOUND true)
    if(MKL64 IN_LIST LAPACK_FIND_COMPONENTS)
      set(LAPACK_MKL64_FOUND true)
    endif()
    if(LAPACK95 IN_LIST LAPACK_FIND_COMPONENTS)
      set(LAPACK_LAPACK95_FOUND true)
    endif()
  endif()
elseif(Atlas IN_LIST LAPACK_FIND_COMPONENTS)

  atlas_libs()

elseif(Netlib IN_LIST LAPACK_FIND_COMPONENTS)

  netlib_libs()

endif()

# verify LAPACK
set(CMAKE_REQUIRED_INCLUDES ${LAPACK_INCLUDE_DIR})
set(CMAKE_REQUIRED_LIBRARIES ${LAPACK_LIBRARY})

set(_lapack_ok true)
if(CMAKE_Fortran_COMPILER AND LAPACK_LIBRARY)
  include(CheckFortranFunctionExists)
  check_fortran_function_exists(sgemm BLAS_OK)
  check_fortran_function_exists(sgesv LAPACK_OK)
  if(NOT (BLAS_OK AND LAPACK_OK))
    set(_lapack_ok false)
  endif()
endif()

if(_lapack_ok)
  if(MSVC OR (CMAKE_C_COMPILER AND USEMKL) OR LAPACKE IN_LIST LAPACK_FIND_COMPONENTS)
    include(CheckSymbolExists)
    if(USEMKL)
      check_symbol_exists(LAPACKE_cheev mkl_lapacke.h _lapack_ok)
    else()
      check_symbol_exists(LAPACKE_cheev lapacke.h _lapack_ok)
    endif()
  endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  LAPACK
  REQUIRED_VARS LAPACK_LIBRARY _lapack_ok
  HANDLE_COMPONENTS)

if(LAPACK_FOUND)
  set(LAPACK_LIBRARIES ${LAPACK_LIBRARY})
  set(LAPACK_INCLUDE_DIRS ${LAPACK_INCLUDE_DIR})
endif()

mark_as_advanced(LAPACK_LIBRARY LAPACK_INCLUDE_DIR)
