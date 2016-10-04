cmake_minimum_required( VERSION 3.0 FATAL_ERROR )

cmake_policy( SET CMP0022 NEW )

set( CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CINDER_PATH}/${CINDER_LIB_DIRECTORY} )
set( CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CINDER_PATH}/${CINDER_LIB_DIRECTORY} )

if( CINDER_VERBOSE )
	message( "CMAKE_ARCHIVE_OUTPUT_DIRECTORY: ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}" )
endif()

# The type is based on the value of the BUILD_SHARED_LIBS variable.
# When OFF ( default value ) Cinder will be built as a static lib
# and when ON as a shared library.
# See https://cmake.org/cmake/help/v3.0/command/add_library.html for more info.
add_library(
	cinder
    ${CINDER_SRC_FILES}
)

target_include_directories( cinder BEFORE INTERFACE ${CINDER_INCLUDE_USER_INTERFACE} )
target_include_directories( cinder SYSTEM BEFORE INTERFACE ${CINDER_INCLUDE_SYSTEM_INTERFACE} )

target_include_directories( cinder BEFORE PRIVATE ${CINDER_INCLUDE_USER_PRIVATE} )
target_include_directories( cinder SYSTEM BEFORE PRIVATE ${CINDER_INCLUDE_SYSTEM_PRIVATE} )

target_link_libraries( cinder PUBLIC ${CINDER_LIBS_DEPENDS}  )
target_link_libraries( cinder LINK_PRIVATE Ws2_32.lib  )

target_compile_definitions( cinder PUBLIC ${CINDER_DEFINES} )

# MSVC specific options
if( MSVC )
	# Force the library output directory
    set_target_properties( cinder PROPERTIES LIBRARY_OUTPUT_DIRECTORY_DEBUG          "${CINDER_PATH}/${CINDER_LIB_DIRECTORY}/Debug/$(PlatformToolset)" )	
    set_target_properties( cinder PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELEASE        "${CINDER_PATH}/${CINDER_LIB_DIRECTORY}/Release/$(PlatformToolset)" )	
    set_target_properties( cinder PROPERTIES LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL     "${CINDER_PATH}/${CINDER_LIB_DIRECTORY}/Release/$(PlatformToolset)" )	
    set_target_properties( cinder PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CINDER_PATH}/${CINDER_LIB_DIRECTORY}/Release/$(PlatformToolset)" )	
	# Force the archive output directory
    set_target_properties( cinder PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_DEBUG          "${CINDER_PATH}/${CINDER_LIB_DIRECTORY}/Debug/$(PlatformToolset)" )	
    set_target_properties( cinder PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_RELEASE        "${CINDER_PATH}/${CINDER_LIB_DIRECTORY}/Release/$(PlatformToolset)" )	
    set_target_properties( cinder PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL     "${CINDER_PATH}/${CINDER_LIB_DIRECTORY}/Release/$(PlatformToolset)" )	
    set_target_properties( cinder PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CINDER_PATH}/${CINDER_LIB_DIRECTORY}/Release/$(PlatformToolset)" )
	# Remove and set default libs to shut up link warnings 
	set_target_properties( cinder PROPERTIES STATIC_LIBRARY_FLAGS "/REMOVE:LIBCMT /REMOVE:LIBCPMT /NODEFAULTLIB:LIBCMT /NODEFAULTLIB:LIBCPMT" )
endif()

# Check compiler support for enabling c++11 or c++14.
if( CINDER_MSW AND MSVC )
    if( MSVC_VERSION LESS 1800 ) # Older version of Visual Studio
        message( FATAL "Unsupported MSVC version: ${MSVC_VERSION}" )
    elseif( MSVC_VERSION LESS 1900 ) # Visual Studio 2013
        set( COMPILER_SUPPORTS_CXX11 true )
    else() # Visual Studio 2015
        set( COMPILER_SUPPORTS_CXX14 true )
        set( COMPILER_SUPPORTS_CXX11 true )
    endif()
elseif( CINDER_ANDROID )
	# Assume true for Android since compiler is Clang 3.8 at minimum
   	set( COMPILER_SUPPORTS_CXX14 true )
    set( COMPILER_SUPPORTS_CXX11 true )
else()
    include( CheckCXXCompilerFlag )
    CHECK_CXX_COMPILER_FLAG( "-std=c++14" COMPILER_SUPPORTS_CXX14 )
    CHECK_CXX_COMPILER_FLAG( "-std=c++11" COMPILER_SUPPORTS_CXX11 )
endif()

if( COMPILER_SUPPORTS_CXX14 )
    if( NOT MSVC )
    	set( CINDER_CXX_FLAGS "-std=c++14" )
    endif()
elseif( COMPILER_SUPPORTS_CXX11 )
    if( NOT MSVC )
        set( CINDER_CXX_FLAGS "-std=c++11" )
    endif()
else()
	message( FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has neither C++11 or C++14 support. Please use a different C++ compiler." )
endif()

# TODO: it would be nice to the following, but we can't until min required cmake is 3.3
#target_compile_options( cinder PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${CINDER_CXX_FLAGS}> )
set( CMAKE_CXX_FLAGS ${CINDER_CXX_FLAGS} ${CMAKE_CXX_FLAGS} )
target_compile_options( cinder INTERFACE ${CINDER_CXX_FLAGS} )

# This file will contain all dependencies, includes, definition, compiler flags and so on..
export( TARGETS cinder FILE ${PROJECT_BINARY_DIR}/${CINDER_LIB_DIRECTORY}/cinderTargets.cmake )

# And this command will generate a file on the ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}
# that applications have to pull in order to link successfully with Cinder and its dependencies.
# This specific cinderConfig.cmake file will just hold a path to the above mention cinderTargets.cmake file which holds the actual info.
configure_file( ${CMAKE_CURRENT_LIST_DIR}/modules/cinderConfig.buildtree.cmake.in
	${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/cinderConfig.cmake
)
