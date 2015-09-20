#include <iostream>
#include "boost/filesystem.hpp"

int main(){

  boost::filesystem::path p("C:\\");

  if (exists(p)){
	  std::cout << "OK" << std::endl;
  }

  return EXIT_SUCCESS;
}
