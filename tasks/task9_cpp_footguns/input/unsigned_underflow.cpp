#include <iostream>
#include <vector>

// Ring buffer implementation
class RingBuffer {
public:
    RingBuffer(size_t capacity) : capacity_(capacity), head_(0), tail_(0) {}

    void push(int value) {
        buffer_.push_back(value);
        tail_ = (tail_ + 1) % capacity_;
    }

    size_t available() const {
        // BUG: Unsigned underflow when tail < head
        return tail_ - head_;  // Wraps around to huge number!
    }

    bool isEmpty() const {
        return head_ == tail_;
    }

private:
    std::vector<int> buffer_;
    size_t capacity_;
    size_t head_;
    size_t tail_;
};

int main() {
    RingBuffer buffer(10);

    buffer.push(1);
    buffer.push(2);
    buffer.push(3);

    std::cout << "Available: " << buffer.available() << std::endl;
    std::cout << "Empty: " << (buffer.isEmpty() ? "yes" : "no") << std::endl;
    std::cout << "Done" << std::endl;

    return 0;
}
