#----------------------------------------------------------------
# Generated CMake target import file for configuration "RelWithDebInfo".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "CommonAPI-SomeIP" for configuration "RelWithDebInfo"
set_property(TARGET CommonAPI-SomeIP APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(CommonAPI-SomeIP PROPERTIES
  IMPORTED_LINK_INTERFACE_LIBRARIES_RELWITHDEBINFO "CommonAPI;vsomeip3"
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib/libCommonAPI-SomeIP.so.3.2.4"
  IMPORTED_SONAME_RELWITHDEBINFO "libCommonAPI-SomeIP.so.3.2.4"
  )

list(APPEND _IMPORT_CHECK_TARGETS CommonAPI-SomeIP )
list(APPEND _IMPORT_CHECK_FILES_FOR_CommonAPI-SomeIP "${_IMPORT_PREFIX}/lib/libCommonAPI-SomeIP.so.3.2.4" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
