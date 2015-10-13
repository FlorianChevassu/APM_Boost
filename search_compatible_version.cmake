set(Boost_COMPATIBLE_VERSION_FOUND FALSE)

IPM_get_compatible_package_version_root_parse_arguments(l_IPM_get_compatible_package_version_root ${ARGN})

IPM_get_subdirectories(${Boost_PACKAGE_ROOT} l_Boost_VERSION_dirs)

#try to find a matching version
foreach(l_Boost_VERSION_dir ${l_Boost_VERSION_dirs})
	# first check that the project has been installed. If so, check version compatibility.
	#TODO add path to test file
	if(EXISTS ${Boost_PACKAGE_ROOT}/${l_Boost_VERSION_dir}/install/)
		if(${l_Boost_VERSION_dir} VERSION_EQUAL ${Boost_VERSION})
			set(Boost_COMPATIBLE_VERSION_FOUND TRUE)
			set(Boost_VERSION_ROOT ${Boost_PACKAGE_ROOT}/${l_Boost_VERSION_dir})
			break()
		else()
			#we assume that greater versions are backward compatible
			if(${l_Boost_VERSION_dir} VERSION_GREATER ${Boost_VERSION} AND NOT ${l_IPM_get_compatible_package_version_root_EXACT})
				set(Boost_COMPATIBLE_VERSION_FOUND TRUE)
				set(Boost_VERSION_ROOT ${Boost_PACKAGE_ROOT}/${l_Boost_VERSION_dir})
				break()
			endif()
		endif()
	endif()
endforeach()

if(NOT ${Boost_COMPATIBLE_VERSION_FOUND})
  inquire_message(INFO "No compatible version of Boost found.")
endif()
