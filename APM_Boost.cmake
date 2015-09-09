function(check_package_compatibility a_APM_result)
	#This call is useless as we do not handle any argument. However, it could be if we check compiler compatibility.
	#APM_check_package_compatibility_parse_arguments(l_APM_check_package_compatibility ${ARGN})
  set(${a_APM_result} TRUE PARENT_SCOPE)
endfunction()


function(get_compatible_package_version_root a_APM_package_root a_APM_version a_APM_result)
	APM_get_compatible_package_version_root_parse_arguments(l_APM_get_compatible_package_version_root ${ARGN})
	APM_get_subdirectories(${a_APM_package_root} l_APM_version_dirs)

	#try to find a matching version
	foreach(l_APM_version_dir ${l_APM_version_dirs})
		set(l_APM_version_compatible FALSE)
		# first check that the project has been installed. If so, check version compatibility.
		#TODO add path to test file
		if(EXISTS ${a_APM_package_root}/${l_APM_version_dir}/install/)
			if(${l_APM_version_dir} VERSION_EQUAL ${a_APM_version})
				set(l_APM_version_compatible TRUE)
				set(${a_APM_result} ${a_APM_package_root}/${l_APM_version_dir} PARENT_SCOPE)
				break()
			else()
				#we assume that greater versions are backward compatible
				if(${l_APM_version_dir} VERSION_GREATER ${a_APM_version} AND NOT ${l_APM_get_compatible_package_version_root_EXACT})
					set(l_APM_version_compatible TRUE)
					set(${a_APM_result} ${a_APM_package_root}/${l_APM_version_dir} PARENT_SCOPE)
					break()
				endif()
			endif()
		endif()
	endforeach()
endfunction()

function(download_package_version a_APM_package_root a_APM_result a_APM_version)
	APM_message(INFO "Triggering installation of Boost in version ${a_APM_version}... ")
	string(REPLACE "." "_" l_APM_underscore_version ${a_APM_version})

	#---------------------------------------------------------------------------------------#
	#-										DOWNLOAD									   -#
	#---------------------------------------------------------------------------------------#

	set(l_APM_archive_name "boost_${l_APM_underscore_version}.tar.gz")
	set(l_APM_Boost_location "http://sourceforge.net/projects/boost/files/boost/${a_APM_version}/${l_APM_archive_name}")
	set(l_APM_Boost_local_dir ${a_APM_package_root}/${a_APM_version})
	set(l_APM_Boost_local_archive "${l_APM_Boost_local_dir}/download/${l_APM_archive_name}")

	if(NOT EXISTS "${l_APM_Boost_local_archive}")
		APM_message(INFO "Downloading Boost ${a_APM_version} from ${l_APM_Boost_location}.")
		file(DOWNLOAD "${l_APM_Boost_location}" "${l_APM_Boost_local_archive}" SHOW_PROGRESS STATUS l_APM_download_status)
		list(GET l_APM_download_status 0 l_APM_download_status_code)
		list(GET l_APM_download_status 1 l_APM_download_status_string)
		if(NOT l_APM_download_status_code EQUAL 0)
			APM_message(FATAL_ERROR "Error: downloading ${l_APM_Boost_location} failed with error : ${l_APM_download_status_string}")
		endif()
	else()
			APM_message(INFO "Using already downloaded Boost version from ${l_APM_Boost_local_archive}")
	endif()

	#---------------------------------------------------------------------------------------#
	#-										EXTRACT 									   -#
	#---------------------------------------------------------------------------------------#
	if(EXISTS ${l_APM_Boost_local_dir}/source/boost_${l_APM_underscore_version}/)
		APM_message(INFO "Folder ${l_APM_Boost_local_dir}/source/boost_${l_APM_underscore_version}/ already exists. ")
	else()
		APM_message(INFO "Extracting Boost ${a_APM_version}...")
		file(MAKE_DIRECTORY ${l_APM_Boost_local_dir}/source/)
		execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${l_APM_Boost_local_archive} WORKING_DIRECTORY ${l_APM_Boost_local_dir}/source/)
		APM_message(INFO "Extracting Boost ${a_APM_version}... DONE.")
	endif()

	set(${a_APM_result} ${l_APM_Boost_local_dir} PARENT_SCOPE)
endfunction()

function(package_version_need_compilation a_APM_package_version_root a_APM_result)
	APM_package_version_need_compilation_parse_arguments(l_APM_package_version_need_compilation ${ARGN})

	APM_get_subdirectories(${a_APM_package_version_root}/source l_APM_version)
	string(REPLACE "boost_" "" l_APM_version ${l_APM_version})
	string(REPLACE "_" ";" l_APM_version_list ${l_APM_version})
	list(GET l_APM_version_list 0 l_APM_boost_major)
	list(GET l_APM_version_list 1 l_APM_boost_minor)
	list(GET l_APM_version_list 2 l_APM_boost_patch)

	set(l_APM_source_path ${a_APM_package_version_root}/source/boost_${l_APM_boost_major}_${l_APM_boost_minor}_${l_APM_boost_patch})

	set(l_APM_install_path ${a_APM_package_version_root}/install/${APM_COMPILER_ID})

  set(BOOST_ROOT ${l_APM_install_path})
	#set the BOOST_INCLUDEDIR variable to help FindBoost to actually find boost headers...
	set(BOOST_INCLUDEDIR ${l_APM_install_path}/include/boost-${l_APM_boost_major}_${l_APM_boost_minor})
	set(BOOST_LIBRARYDIR  ${l_APM_install_path}/lib)

	if(DEFINED l_APM_package_version_need_compilation_COMPONENTS)
		find_package(Boost COMPONENTS ${l_APM_package_version_need_compilation_COMPONENTS} MODULE QUIET)
	else()
		find_package(Boost MODULE QUIET)
	endif()

	#TODO : Why not write set(${a_APM_result} (NOT ${Boost_FOUND}) PARENT_SCOPE) ??
	if(${Boost_FOUND})
		set(${a_APM_result} FALSE PARENT_SCOPE)
	else()
		set(${a_APM_result} TRUE PARENT_SCOPE)
	endif()
endfunction()


function(compile_package_version a_APM_package_version_root a_APM_result)
	APM_compile_package_version_parse_arguments(l_APM_compile_package ${ARGN})

	APM_message(INFO "Triggering compilation of Boost...")

	set(BOOST_ROOT ${a_APM_package_version_root}/source)

	APM_get_subdirectories(${a_APM_package_version_root}/source l_APM_version)
	string(REPLACE "boost_" "" l_APM_version ${l_APM_version})
	string(REPLACE "_" ";" l_APM_version_list ${l_APM_version})
	list(GET l_APM_version_list 0 l_APM_boost_major)
	list(GET l_APM_version_list 1 l_APM_boost_minor)
	list(GET l_APM_version_list 2 l_APM_boost_patch)

	set(l_APM_source_path ${a_APM_package_version_root}/source/boost_${l_APM_boost_major}_${l_APM_boost_minor}_${l_APM_boost_patch})
	set(l_APM_install_path ${a_APM_package_version_root}/install/${APM_COMPILER_ID})

	#-----------------------------------------------------#
	#-                    BOOTSTRAP                      -#
	#-----------------------------------------------------#
	if(CMAKE_SYSTEM_NAME MATCHES "Windows")
		set(l_APM_BOOSTRAPER ${l_APM_source_path}/bootstrap.bat)
		set(l_APM_B2 ${l_APM_source_path}/b2.exe)
		set(l_APM_DYNLIB_EXTENSION .dll)
	elseif(CMAKE_SYSTEM_NAME MATCHES "Darwin")
		set(l_APM_BOOSTRAPER ${l_APM_source_path}/bootstrap.sh)
		set(l_APM_B2 ${l_APM_source_path}/b2)
		set(l_APM_DYNLIB_EXTENSION .dylib)
	elseif(CMAKE_SYSTEM_NAME MATCHES "Linux")
		set(l_APM_BOOSTRAPER ${l_APM_source_path}/bootstrap.sh)
		set(l_APM_B2 ${l_APM_source_path}/b2)
		set(l_APM_DYNLIB_EXTENSION .so)
	else()
		APM_message(FATAL "Platform not suported. Unable to install boost libraries.")
	endif()

	if(NOT EXISTS ${l_APM_B2})
		APM_message(INFO "Bootstrapping Boost...")
		execute_process(COMMAND ${l_APM_BOOSTRAPER}  --prefix=${l_APM_install_path}
				WORKING_DIRECTORY ${l_APM_source_path}
				RESULT_VARIABLE l_APM_result
				OUTPUT_VARIABLE l_APM_output
			ERROR_VARIABLE l_APM_error)
		if(NOT l_APM_result EQUAL 0)
			APM_message(FATAL "Failed running bootstrap :\n${l_APM_output}\n${l_APM_error}\n")
		endif()
	endif()

	#-------------------------------------------------#
	#-                    BUILD                      -#
	#-------------------------------------------------#

	if(DEFINED l_APM_compile_package_COMPONENTS)
		APM_compute_toolset(l_APM_toolset)
		APM_message(INFO "Building Boost components with toolset ${l_APM_toolset}...")
		#TODO : Add the possibility to launch parallel compilation
		set(l_APM_B2_call_string  ${l_APM_B2} install --toolset=${l_APM_toolset} -j1 --layout=versioned --build-type=complete -d0 --prefix=${l_APM_install_path})
		foreach(l_APM_component ${l_APM_compile_package_COMPONENTS})
			set(l_APM_B2_call_string ${l_APM_B2_call_string} --with-${l_APM_component})
		endforeach()

		execute_process(COMMAND ${l_APM_B2_call_string}
    WORKING_DIRECTORY ${l_APM_source_path})
	endif()

	APM_message(INFO "Triggering compilation of Boost... OK")
endfunction()


function(configure_package_version a_APM_package_version_root)
	APM_configure_package_version_parse_arguments(l_APM_configure_package_version ${ARGN})

	APM_get_subdirectories(${a_APM_package_version_root}/source l_APM_version)
	string(REPLACE "boost_" "" l_APM_version ${l_APM_version})
	string(REPLACE "_" ";" l_APM_version_list ${l_APM_version})
	list(GET l_APM_version_list 0 l_APM_boost_major)
	list(GET l_APM_version_list 1 l_APM_boost_minor)
	list(GET l_APM_version_list 2 l_APM_boost_patch)

	set(l_APM_source_path ${a_APM_package_version_root}/source/boost_${l_APM_boost_major}_${l_APM_boost_minor}_${l_APM_boost_patch})

	set(l_APM_install_path ${a_APM_package_version_root}/install/${APM_COMPILER_ID})

  set(BOOST_ROOT ${l_APM_install_path})

	#set the BOOST_INCLUDEDIR variable to help FindBoost to actually find boost headers...
	set(BOOST_INCLUDEDIR ${l_APM_install_path}/include/boost-${l_APM_boost_major}_${l_APM_boost_minor})
	set(BOOST_LIBRARYDIR  ${l_APM_install_path}/lib)
	set(Boost_USE_STATIC_LIBS ON)


	#TODO : ca sert à quoi ça ???
	# FindBoost auto-compute does not care about Clang?
	if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		APM_boost_set_clang_compiler("${BOOST_LIBRARYDIR}" Boost_COMPILER)
	endif()

	if(DEFINED l_APM_configure_package_version_COMPONENTS)
		find_package(Boost COMPONENTS ${l_APM_configure_package_version_COMPONENTS} MODULE QUIET)
	else()
		#if no components have been set, we have nothing to build. As b2 cannot easily generate an install with no library selected, we just include the source dir.
		set(Boost_INCLUDE_DIRS ${l_APM_source_path})
	endif()

	#add include directories to targets
	if(NOT l_APM_configure_package_version_TARGETS)
		APM_message(WARN "Including directory ${Boost_INCLUDE_DIRS} globally.")
		include_directories(${Boost_INCLUDE_DIRS})
		if(DEFINED Boost_LIBRARIES)
			APM_message(WARN "Libraries ${Boost_LIBRARIES} will no be usable unless you specify some targets to link to.")
		endif()
	else()
		APM_message(INFO "Including directory ${Boost_INCLUDE_DIRS} for targets ${l_APM_configure_package_version_TARGETS}.")
		foreach(l_APM_target ${l_APM_configure_package_version_TARGETS})
			target_include_directories(${l_APM_target} PUBLIC ${Boost_INCLUDE_DIRS})
			list(LENGTH Boost_LIBRARIES l_APM_boost_libs_count)
			if(DEFINED Boost_LIBRARIES AND l_APM_boost_libs_count GREATER 0)
				APM_message(INFO "Linking libraries ${l_APM_configure_package_version_COMPONENTS} to targets ${l_APM_configure_package_version_TARGETS}.")
				target_link_libraries(${l_APM_target} PUBLIC ${Boost_LIBRARIES})
			endif()
		endforeach(l_APM_target)
	endif()

	if(MSVC)
		add_definitions(-DBOOST_ALL_NO_LIB)
		#add_definitions(-DBOOST_ALL_DYN_LINK)
	endif(MSVC)

endfunction()
