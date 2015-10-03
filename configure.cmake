IPM_get_subdirectories(${IPM_PACKAGE_VERSION_ROOT}/source l_IPM_version)


string(REPLACE "boost_" "" l_IPM_version ${l_IPM_version})
string(REPLACE "_" ";" l_IPM_version_list ${l_IPM_version})
list(GET l_IPM_version_list 0 l_IPM_boost_major)
list(GET l_IPM_version_list 1 l_IPM_boost_minor)
list(GET l_IPM_version_list 2 l_IPM_boost_patch)

set(l_IPM_source_path ${IPM_PACKAGE_VERSION_ROOT}/source/boost_${l_IPM_boost_major}_${l_IPM_boost_minor}_${l_IPM_boost_patch})

set(l_IPM_install_path ${IPM_PACKAGE_VERSION_ROOT}/install/${IPM_COMPILER_ID})

set(BOOST_ROOT ${l_IPM_install_path})

#set the BOOST_INCLUDEDIR variable to help FindBoost to actually find boost headers...
set(BOOST_INCLUDEDIR ${l_IPM_install_path}/include/boost-${l_IPM_boost_major}_${l_IPM_boost_minor})
set(BOOST_LIBRARYDIR  ${l_IPM_install_path}/lib)
set(Boost_USE_STATIC_LIBS ON)


#TODO : ca sert � quoi �a ???
# FindBoost auto-compute does not care about Clang?
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
	IPM_boost_set_clang_compiler("${BOOST_LIBRARYDIR}" Boost_COMPILER)
endif()

if(DEFINED IPM_COMPONENTS)
	find_package(Boost COMPONENTS ${IPM_COMPONENTS} MODULE QUIET)
else()
	#if no components have been set, we have nothing to build. As b2 cannot easily generate an install with no library selected, we just include the source dir.
	set(Boost_INCLUDE_DIRS ${l_IPM_source_path})
endif()

#add include directories to targets
if(NOT IPM_TARGETS)
	inquire_message(WARN "Including directory ${Boost_INCLUDE_DIRS} globally.")
	include_directories(${Boost_INCLUDE_DIRS})
	if(DEFINED Boost_LIBRARIES)
		inquire_message(WARN "Libraries ${Boost_LIBRARIES} will no be usable unless you specify some targets to link to.")
	endif()
else()
	inquire_message(INFO "Including directory ${Boost_INCLUDE_DIRS} for targets ${IPM_TARGETS}.")
	foreach(l_IPM_target ${IPM_TARGETS})
		target_include_directories(${l_IPM_target} PUBLIC ${Boost_INCLUDE_DIRS})
		list(LENGTH Boost_LIBRARIES l_IPM_boost_libs_count)
		if(DEFINED Boost_LIBRARIES AND l_IPM_boost_libs_count GREATER 0)
			inquire_message(INFO "Linking libraries ${IPM_COMPONENTS} to targets ${IPM_TARGETS}.")
			target_link_libraries(${l_IPM_target} PUBLIC ${Boost_LIBRARIES})
		endif()
	endforeach(l_IPM_target)
endif()

if(MSVC)
	add_definitions(-DBOOST_ALL_NO_LIB)
	#add_definitions(-DBOOST_ALL_DYN_LINK)
endif(MSVC)
