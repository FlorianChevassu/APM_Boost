inquire_message(INFO "Triggering installation of Boost in version ${IPM_VERSION}... ")
string(REPLACE "." "_" l_IPM_underscore_version ${IPM_VERSION})

#---------------------------------------------------------------------------------------#
#-										DOWNLOAD									   -#
#---------------------------------------------------------------------------------------#

set(l_IPM_archive_name "boost_${l_IPM_underscore_version}.tar.gz")
set(l_IPM_Boost_location "http://sourceforge.net/projects/boost/files/boost/${IPM_VERSION}/${l_IPM_archive_name}")
set(l_IPM_Boost_local_dir ${IPM_PACKAGE_ROOT}/${IPM_VERSION})
set(l_IPM_Boost_local_archive "${l_IPM_Boost_local_dir}/download/${l_IPM_archive_name}")

if(NOT EXISTS "${l_IPM_Boost_local_archive}")
  inquire_message(INFO "Downloading Boost ${IPM_VERSION} from ${l_IPM_Boost_location}.")
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
  inquire_message(INFO "Extracting Boost ${IPM_VERSION}...")
  file(MAKE_DIRECTORY ${l_IPM_Boost_local_dir}/source/)
  execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${l_IPM_Boost_local_archive} WORKING_DIRECTORY ${l_IPM_Boost_local_dir}/source/)
  inquire_message(INFO "Extracting Boost ${IPM_VERSION}... DONE.")
endif()

set(IPM_PACKAGE_VERSION_ROOT ${l_IPM_Boost_local_dir})
