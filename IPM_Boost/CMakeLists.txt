cmake_minimum_required (VERSION 3.0.0)
project (BoostTestProject)

include(${CMAKE_CURRENT_LIST_DIR}/../../Inquire/inquire.cmake)

#force installation of boost...
set(IPM_install_Boost ON CACHE BOOL "")

add_executable(BoostTest BoostTest.cpp)
# an IPM module repository is a place (folder, GIT repo, etc.) containing CMake modules to "require" projects.
inquire_add_module_repository(moduleRepo FOLDER "${CMAKE_CURRENT_SOURCE_DIR}/../")

# an IPM package repository contains all the built libraries and sources.
inquire_add_package_repository(packageRepo FOLDER "${CMAKE_CURRENT_BINARY_DIR}/packages/")

require_package(Boost VERSION 1.59.0 TARGETS BoostTest COMPONENTS filesystem system REQUIRED)
