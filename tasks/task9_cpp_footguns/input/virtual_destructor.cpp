#include <iostream>
#include <string>
#include <vector>

// Plugin system - base interface
class Plugin {
public:
    Plugin(const std::string& name) : name_(name) {
        buffer_ = new char[256];
    }

    ~Plugin() {  // BUG: Missing virtual
        delete[] buffer_;
    }

    virtual std::string getName() const { return name_; }
    virtual void execute() = 0;

protected:
    std::string name_;
    char* buffer_;
};

class ImagePlugin : public Plugin {
public:
    ImagePlugin() : Plugin("ImageProcessor") {
        imageData_ = new int[1024];
    }

    ~ImagePlugin() {
        delete[] imageData_;
    }

    void execute() override {
        std::cout << "Processing images" << std::endl;
    }

private:
    int* imageData_;
};

int main() {
    std::vector<Plugin*> plugins;
    plugins.push_back(new ImagePlugin());

    for (Plugin* p : plugins) {
        std::cout << p->getName() << std::endl;
        p->execute();
    }

    for (Plugin* p : plugins) {
        delete p;  // Derived destructor not called!
    }

    std::cout << "Done" << std::endl;
    return 0;
}
