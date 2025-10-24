#include <iostream>
#include <string>

// Log formatting system
class Logger {
public:
    // BUG: Returns c_str() of temporary string
    const char* formatMessage(const std::string& msg) {
        std::string formatted = "[LOG] " + msg;
        return formatted.c_str();  // Dangling pointer!
    }

    void log(const std::string& msg) {
        const char* formatted = formatMessage(msg);
        std::cout << formatted << std::endl;
    }
};

int main() {
    Logger logger;

    logger.log("System started");
    logger.log("Loading config");
    logger.log("Ready");

    std::cout << "Done" << std::endl;

    return 0;
}
