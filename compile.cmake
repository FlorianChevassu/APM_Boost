#First check if the package needs to be compiled
IPM_get_subdirectories(${Boost_PACKAGE_VERSION_ROOT}/source l_IPM_version)

string(REPLACE "boost_" "" l_IPM_version ${l_IPM_version})
string(REPLACE "_" ";" l_IPM_version_list ${l_IPM_version})
list(GET l_IPM_version_list 0 l_IPM_boost_major)
list(GET l_IPM_version_list 1 l_IPM_boost_minor)
list(GET l_IPM_version_list 2 l_IPM_boost_patch)

set(l_IPM_source_path ${Boost_PACKAGE_VERSION_ROOT}/source/boost_${l_IPM_boost_major}_${l_IPM_boost_minor}_${l_IPM_boost_patch})

set(l_IPM_install_path ${Boost_PACKAGE_VERSION_ROOT}/install/${IPM_COMPILER_ID})

set(BOOST_ROOT ${l_IPM_install_path})
#set the BOOST_INCLUDEDIR variable to help FindBoost to actually find boost headers...
set(BOOST_INCLUDEDIR ${l_IPM_install_path}/include/boost-${l_IPM_boost_major}_${l_IPM_boost_minor})
set(BOOST_LIBRARYDIR  ${l_IPM_install_path}/lib)

if(DEFINED Boost_COMPONENTS)
	find_package(Boost COMPONENTS ${Boost_COMPONENTS} MODULE QUIET)
else()
	find_package(Boost MODULE QUIET)
endif()

#TODO : Why not write set(${l_IPM_need_compilation} (NOT ${Boost_FOUND}) PARENT_SCOPE) ??
if(${Boost_FOUND})
	set(l_IPM_need_compilation FALSE)
else()
	set(l_IPM_need_compilation TRUE)
endif()

if(${l_IPM_need_compilation})
	inquire_message(INFO "Triggering compilation of Boost...")

	set(BOOST_ROOT ${Boost_PACKAGE_VERSION_ROOT}/source)

	IPM_get_subdirectories(${Boost_PACKAGE_VERSION_ROOT}/source l_IPM_version)
	string(REPLACE "boost_" "" l_IPM_version ${l_IPM_version})
	string(REPLACE "_" ";" l_IPM_version_list ${l_IPM_version})
	list(GET l_IPM_version_list 0 l_IPM_boost_major)
	list(GET l_IPM_version_list 1 l_IPM_boost_minor)
	list(GET l_IPM_version_list 2 l_IPM_boost_patch)

	set(l_IPM_source_path ${Boost_PACKAGE_VERSION_ROOT}/source/boost_${l_IPM_boost_major}_${l_IPM_boost_minor}_${l_IPM_boost_patch})
	set(l_IPM_install_path ${Boost_PACKAGE_VERSION_ROOT}/install/${IPM_COMPILER_ID})

	#-----------------------------------------------------#
	#-                    BOOTSTRAP                      -#
	#-----------------------------------------------------#
	if(CMAKE_SYSTEM_NAME MATCHES "Windows")
		set(l_IPM_BOOSTRAPER ${l_IPM_source_path}/bootstrap.bat)
		set(l_IPM_B2 ${l_IPM_source_path}/b2.exe)
		set(l_IPM_DYNLIB_EXTENSION .dll)
	elseif(CMAKE_SYSTEM_NAME MATCHES "Darwin")
		set(l_IPM_BOOSTRAPER ${l_IPM_source_path}/bootstrap.sh)
		set(l_IPM_B2 ${l_IPM_source_path}/b2)
		set(l_IPM_DYNLIB_EXTENSION .dylib)
	elseif(CMAKE_SYSTEM_NAME MATCHES "Linux")
		set(l_IPM_BOOSTRAPER ${l_IPM_source_path}/bootstrap.sh)
		set(l_IPM_B2 ${l_IPM_source_path}/b2)
		set(l_IPM_DYNLIB_EXTENSION .so)
	else()
		inquire_message(FATAL "Platform not suported. Unable to install boost libraries.")
	endif()

	if(NOT EXISTS ${l_IPM_B2})
		inquire_message(INFO "Bootstrapping Boost...")
		execute_process(COMMAND ${l_IPM_BOOSTRAPER}  --prefix=${l_IPM_install_path}
				WORKING_DIRECTORY ${l_IPM_source_path}
				RESULT_VARIABLE l_IPM_result
				OUTPUT_VARIABLE l_IPM_output
			ERROR_VARIABLE l_IPM_error)
		if(NOT l_IPM_result EQUAL 0)
			inquire_message(FATAL "Failed running bootstrap :\n${l_IPM_output}\n${l_IPM_error}\n")
		endif()
	endif()

	#-------------------------------------------------#
	#-                    BUILD                      -#
	#-------------------------------------------------#

  inquire_message(DEBUG "Boost_COMPONENTS = ${Boost_COMPONENTS}")
	if(DEFINED Boost_COMPONENTS)
		IPM_compute_toolset(l_IPM_toolset)
		inquire_message(INFO "Building Boost components with toolset ${l_IPM_toolset}...")
		#TODO : Add the possibility to launch parallel compilation
		set(l_IPM_B2_call_string  ${l_IPM_B2} install --toolset=${l_IPM_toolset} -j1 --layout=versioned --build-type=complete -d0 --prefix=${l_IPM_install_path})
		foreach(l_IPM_component ${Boost_COMPONENTS})
			set(l_IPM_B2_call_string ${l_IPM_B2_call_string} --with-${l_IPM_component})
		endforeach()

		execute_process(COMMAND ${l_IPM_B2_call_string}
    WORKING_DIRECTORY ${l_IPM_source_path})
	endif()

	inquire_message(INFO "Triggering compilation of Boost... OK")
endif()
