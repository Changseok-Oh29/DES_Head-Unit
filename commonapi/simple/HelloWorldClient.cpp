#include <iostream>
#include <string>
#include <unistd.h>
#include <CommonAPI/CommonAPI.hpp>
#include <v1/commonapi/HelloWorldProxy.hpp>

using namespace v1_0::commonapi;

int main() {
    CommonAPI::Runtime::setProperty("LogContext", "E01C");
    CommonAPI::Runtime::setProperty("LogApplication", "E01C");
    CommonAPI::Runtime::setProperty("LibraryBase", "HelloWorld");

    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();

    std::string domain = "local";
    std::string instance = "commonapi.HelloWorld";
    std::string connection = "client-sample";

    std::shared_ptr<HelloWorldProxyDefault> myProxy = runtime->buildProxy<HelloWorldProxy>(domain, instance, connection);

    std::cout << "Checking availability!" << std::endl;
    while (!myProxy->isAvailable())
        usleep(10);
    std::cout << "Available..." << std::endl;

    CommonAPI::CallStatus callStatus;
    std::string returnMessage;

    myProxy->sayHello("Bob", callStatus, returnMessage);

    if (callStatus != CommonAPI::CallStatus::SUCCESS) {
        std::cout << "Remote call failed!\n";
        return -1;
    }

    std::cout << "Got message: '" << returnMessage << "'\n";
    
    return 0;
}
