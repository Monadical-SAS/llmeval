#include <iostream>
#include <vector>
#include <string>

// Event queue that processes and filters events
class EventQueue {
public:
    void addEvent(const std::string& event) {
        events_.push_back(event);
    }

    void processEvents() {
        std::cout << "Processing events..." << std::endl;

        // BUG: Iterator invalidated by push_back
        for (auto it = events_.begin(); it != events_.end(); ++it) {
            std::cout << "Event: " << *it << std::endl;

            // Add derived event during iteration
            if (*it == "user_login") {
                events_.push_back("log_analytics");  // Invalidates iterator!
            }
        }
    }

    int getEventCount() const {
        return events_.size();
    }

private:
    std::vector<std::string> events_;
};

int main() {
    EventQueue queue;

    queue.addEvent("user_login");
    queue.addEvent("page_view");

    queue.processEvents();

    std::cout << "Total events: " << queue.getEventCount() << std::endl;
    std::cout << "Done" << std::endl;

    return 0;
}
