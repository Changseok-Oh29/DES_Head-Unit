#----------------------------------------------------------------
# Generated CMake target import file for configuration "RelWithDebInfo".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "CommonAPI" for configuration "RelWithDebInfo"
set_property(TARGET CommonAPI APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(CommonAPI PROPERTIES
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib/libCommonAPI.so.3.2.4"
  IMPORTED_SONAME_RELWITHDEBINFO "libCommonAPI.so.3.2.4"
  )

list(APPEND _IMPORT_CHECK_TARGETS CommonAPI )
list(APPEND _IMPORT_CHECK_FILES_FOR_CommonAPI "${_IMPORT_PREFIX}/lib/libCommonAPI.so.3.2.4" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
