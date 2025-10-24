#include <iostream>
#include <string>

// Configuration system
class Config {
public:
    // BUG: Returns reference to temporary
    const std::string& getAppName() {
        return std::string("MyApplication");  // temporary destroyed at end of statement
    }

    int getVersion() {
        return 2;
    }
};

int main() {
    Config config;

    const std::string& appName = config.getAppName();  // Dangling reference!
    int version = config.getVersion();

    std::cout << "Application: " << appName << std::endl;
    std::cout << "Version: " << version << std::endl;
    std::cout << "Done" << std::endl;

    return 0;
}
