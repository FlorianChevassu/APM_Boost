function(check_package_compatibility a_IPM_result)
	#This call is useless as we do not handle any argument. However, it could be if we check compiler compatibility.
	#IPM_check_package_compatibility_parse_arguments(l_IPM_check_package_compatibility ${ARGN})
  set(${a_IPM_result} TRUE PARENT_SCOPE)
endfunction()


function(get_compatible_package_version_root a_IPM_package_root a_IPM_version a_IPM_result)
	IPM_get_compatible_package_version_root_parse_arguments(l_IPM_get_compatible_package_version_root ${ARGN})
	IPM_get_subdirectories(${a_IPM_package_root} l_IPM_version_dirs)

	#try to find a matching version
	foreach(l_IPM_version_dir ${l_IPM_version_dirs})
		set(l_IPM_version_compatible FALSE)
		# first check that the project has been installed. If so, check version compatibility.
		#TODO add path to test file
		if(EXISTS ${a_IPM_package_root}/${l_IPM_version_dir}/install/)
			if(${l_IPM_version_dir} VERSION_EQUAL ${a_IPM_version})
				set(l_IPM_version_compatible TRUE)
				set(${a_IPM_result} ${a_IPM_package_root}/${l_IPM_version_dir} PARENT_SCOPE)
				break()
			else()
				#we assume that greater versions are backward compatible
				if(${l_IPM_version_dir} VERSION_GREATER ${a_IPM_version} AND NOT ${l_IPM_get_compatible_package_version_root_EXACT})
					set(l_IPM_version_compatible TRUE)
					set(${a_IPM_result} ${a_IPM_package_root}/${l_IPM_version_dir} PARENT_SCOPE)
					break()
				endif()
			endif()
		endif()
	endforeach()
endfunction()

function(download_package_version a_IPM_package_root a_IPM_result a_IPM_version)
	inquire_message(INFO "Triggering installation of Boost in version ${a_IPM_version}... ")
	string(REPLACE "." "_" l_IPM_underscore_version ${a_IPM_version})

	#---------------------------------------------------------------------------------------#
	#-										DOWNLOAD									   -#
	#---------------------------------------------------------------------------------------#

	set(l_IPM_archive_name "boost_${l_IPM_underscore_version}.tar.gz")
	set(l_IPM_Boost_location "http://sourceforge.net/projects/boost/files/boost/${a_IPM_version}/${l_IPM_archive_name}")
	set(l_IPM_Boost_local_dir ${a_IPM_package_root}/${a_IPM_version})
	set(l_IPM_Boost_local_archive "${l_IPM_Boost_local_dir}/download/${l_IPM_archive_name}")

	if(NOT EXISTS "${l_IPM_Boost_local_archive}")
		inquire_message(INFO "Downloading Boost ${a_IPM_version} from ${l_IPM_Boost_location}.")
		file(DOWNLOAD "${l_IPM_Boost_location}" "${l_IPM_Boost_local_archive}" SHOW_PROGRESS STATUS l_IPM_download_status)
		list(GET l_IPM_download_status 0 l_IPM_download_status_code)
		list(GET l_IPM_download_status 1 l_IPM_download_status_string)
		if(NOT l_IPM_download_status_code EQUAL 0)
			inquire_message(FATAL_ERROR "Error: downloading ${l_IPM_Boost_location} failed with error : ${l_IPM_download_status_string}")
		endif()
	else()
			inquire_message(INFO "Using already downloaded Boost version from ${l_IPM_Boost_local_archive}")
	endif()

	#---------------------------------------------------------------------------------------#
	#-										EXTRACT 									   -#
	#---------------------------------------------------------------------------------------#
	if(EXISTS ${l_IPM_Boost_local_dir}/source/boost_${l_IPM_underscore_version}/)
		inquire_message(INFO "Folder ${l_IPM_Boost_local_dir}/source/boost_${l_IPM_underscore_version}/ already exists. ")
	else()
		inquire_message(INFO "Extracting Boost ${a_IPM_version}...")
		file(MAKE_DIRECTORY ${l_IPM_Boost_local_dir}/source/)
		execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${l_IPM_Boost_local_archive} WORKING_DIRECTORY ${l_IPM_Boost_local_dir}/source/)
		inquire_message(INFO "Extracting Boost ${a_IPM_version}... DONE.")
	endif()

	set(${a_IPM_result} ${l_IPM_Boost_local_dir} PARENT_SCOPE)
endfunction()

function(package_version_need_compilation a_IPM_package_version_root a_IPM_result)
	IPM_package_version_need_compilation_parse_arguments(l_IPM_package_version_need_compilation ${ARGN})

	IPM_get_subdirectories(${a_IPM_package_version_root}/source l_IPM_version)
	string(REPLACE "boost_" "" l_IPM_version ${l_IPM_version})
	string(REPLACE "_" ";" l_IPM_version_list ${l_IPM_version})
	list(GET l_IPM_version_list 0 l_IPM_boost_major)
	list(GET l_IPM_version_list 1 l_IPM_boost_minor)
	list(GET l_IPM_version_list 2 l_IPM_boost_patch)

	set(l_IPM_source_path ${a_IPM_package_version_root}/source/boost_${l_IPM_boost_major}_${l_IPM_boost_minor}_${l_IPM_boost_patch})

	set(l_IPM_install_path ${a_IPM_package_version_root}/install/${IPM_COMPILER_ID})

  set(BOOST_ROOT ${l_IPM_install_path})
	#set the BOOST_INCLUDEDIR variable to help FindBoost to actually find boost headers...
	set(BOOST_INCLUDEDIR ${l_IPM_install_path}/include/boost-${l_IPM_boost_major}_${l_IPM_boost_minor})
	set(BOOST_LIBRARYDIR  ${l_IPM_install_path}/lib)

	if(DEFINED l_IPM_package_version_need_compilation_COMPONENTS)
		find_package(Boost COMPONENTS ${l_IPM_package_version_need_compilation_COMPONENTS} MODULE QUIET)
	else()
		find_package(Boost MODULE QUIET)
	endif()

	#TODO : Why not write set(${a_IPM_result} (NOT ${Boost_FOUND}) PARENT_SCOPE) ??
	if(${Boost_FOUND})
		set(${a_IPM_result} FALSE PARENT_SCOPE)
	else()
		set(${a_IPM_result} TRUE PARENT_SCOPE)
	endif()
endfunction()


function(compile_package_version a_IPM_package_version_root a_IPM_result)
	IPM_compile_package_version_parse_arguments(l_IPM_compile_package ${ARGN})

	inquire_message(INFO "Triggering compilation of Boost...")

	set(BOOST_ROOT ${a_IPM_package_version_root}/source)

	IPM_get_subdirectories(${a_IPM_package_version_root}/source l_IPM_version)
	string(REPLACE "boost_" "" l_IPM_version ${l_IPM_version})
	string(REPLACE "_" ";" l_IPM_version_list ${l_IPM_version})
	list(GET l_IPM_version_list 0 l_IPM_boost_major)
	list(GET l_IPM_version_list 1 l_IPM_boost_minor)
	list(GET l_IPM_version_list 2 l_IPM_boost_patch)

	set(l_IPM_source_path ${a_IPM_package_version_root}/source/boost_${l_IPM_boost_major}_${l_IPM_boost_minor}_${l_IPM_boost_patch})
	set(l_IPM_install_path ${a_IPM_package_version_root}/install/${IPM_COMPILER_ID})

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

	if(DEFINED l_IPM_compile_package_COMPONENTS)
		IPM_compute_toolset(l_IPM_toolset)
		inquire_message(INFO "Building Boost components with toolset ${l_IPM_toolset}...")
		#TODO : Add the possibility to launch parallel compilation
		set(l_IPM_B2_call_string  ${l_IPM_B2} install --toolset=${l_IPM_toolset} -j1 --layout=versioned --build-type=complete -d0 --prefix=${l_IPM_install_path})
		foreach(l_IPM_component ${l_IPM_compile_package_COMPONENTS})
			set(l_IPM_B2_call_string ${l_IPM_B2_call_string} --with-${l_IPM_component})
		endforeach()

		execute_process(COMMAND ${l_IPM_B2_call_string}
    WORKING_DIRECTORY ${l_IPM_source_path})
	endif()

	inquire_message(INFO "Triggering compilation of Boost... OK")
endfunction()


function(configure_package_version a_IPM_package_version_root)
	IPM_configure_package_version_parse_arguments(l_IPM_configure_package_version ${ARGN})

	IPM_get_subdirectories(${a_IPM_package_version_root}/source l_IPM_version)
	string(REPLACE "boost_" "" l_IPM_version ${l_IPM_version})
	string(REPLACE "_" ";" l_IPM_version_list ${l_IPM_version})
	list(GET l_IPM_version_list 0 l_IPM_boost_major)
	list(GET l_IPM_version_list 1 l_IPM_boost_minor)
	list(GET l_IPM_version_list 2 l_IPM_boost_patch)

	set(l_IPM_source_path ${a_IPM_package_version_root}/source/boost_${l_IPM_boost_major}_${l_IPM_boost_minor}_${l_IPM_boost_patch})

	set(l_IPM_install_path ${a_IPM_package_version_root}/install/${IPM_COMPILER_ID})

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

	if(DEFINED l_IPM_configure_package_version_COMPONENTS)
		find_package(Boost COMPONENTS ${l_IPM_configure_package_version_COMPONENTS} MODULE QUIET)
	else()
		#if no components have been set, we have nothing to build. As b2 cannot easily generate an install with no library selected, we just include the source dir.
		set(Boost_INCLUDE_DIRS ${l_IPM_source_path})
	endif()

	#add include directories to targets
	if(NOT l_IPM_configure_package_version_TARGETS)
		inquire_message(WARN "Including directory ${Boost_INCLUDE_DIRS} globally.")
		include_directories(${Boost_INCLUDE_DIRS})
		if(DEFINED Boost_LIBRARIES)
			inquire_message(WARN "Libraries ${Boost_LIBRARIES} will no be usable unless you specify some targets to link to.")
		endif()
	else()
		inquire_message(INFO "Including directory ${Boost_INCLUDE_DIRS} for targets ${l_IPM_configure_package_version_TARGETS}.")
		foreach(l_IPM_target ${l_IPM_configure_package_version_TARGETS})
			target_include_directories(${l_IPM_target} PUBLIC ${Boost_INCLUDE_DIRS})
			list(LENGTH Boost_LIBRARIES l_IPM_boost_libs_count)
			if(DEFINED Boost_LIBRARIES AND l_IPM_boost_libs_count GREATER 0)
				inquire_message(INFO "Linking libraries ${l_IPM_configure_package_version_COMPONENTS} to targets ${l_IPM_configure_package_version_TARGETS}.")
				target_link_libraries(${l_IPM_target} PUBLIC ${Boost_LIBRARIES})
			endif()
		endforeach(l_IPM_target)
	endif()

	if(MSVC)
		add_definitions(-DBOOST_ALL_NO_LIB)
		#add_definitions(-DBOOST_ALL_DYN_LINK)
	endif(MSVC)

endfunction()
