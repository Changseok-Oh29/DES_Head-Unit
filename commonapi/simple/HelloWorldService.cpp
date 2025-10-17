#include <iostream>
#include <thread>
#include <CommonAPI/CommonAPI.hpp>
#include "HelloWorldStubImpl.hpp"

int main() {
    CommonAPI::Runtime::setProperty("LogContext", "E01S");
    CommonAPI::Runtime::setProperty("LogApplication", "E01S");
    CommonAPI::Runtime::setProperty("LibraryBase", "HelloWorld");

    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();

    std::string domain = "local";
    std::string instance = "commonapi.HelloWorld";
    std::string connection = "service-sample";

    std::shared_ptr<HelloWorldStubImpl> myService = std::make_shared<HelloWorldStubImpl>();
    bool successfullyRegistered = runtime->registerService(domain, instance, myService, connection);

    if (!successfullyRegistered) {
        std::cout << "Successfully Registered Service!" << std::endl;
        return -1;
    }

    std::cout << "Successfully Registered Service!" << std::endl;

    while (true) {
        std::cout << "Waiting for calls... (Abort with CTRL+C)" << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(30));
    }

    return 0;
}
