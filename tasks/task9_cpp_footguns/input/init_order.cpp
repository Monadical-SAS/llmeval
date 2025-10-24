#include <iostream>

// Coordinate system with units
class Point {
public:
    Point(double x, double y, double scale)
        : scale_(scale),
          x_(x * scale_),  // BUG: scale_ used before y_ initialized
          y_(y * scale_)
    {
        // Members initialized in declaration order, not initializer list order!
        // Declaration order: x_, y_, scale_
        // So x_ = x * scale_ uses uninitialized scale_!
    }

    void print() const {
        std::cout << "Point(" << x_ << ", " << y_ << ") scale=" << scale_ << std::endl;
    }

private:
    double x_;      // Initialized first (declaration order)
    double y_;      // Initialized second
    double scale_;  // Initialized third, but used in x_ and y_ init!
};

int main() {
    Point p(3.0, 4.0, 2.0);  // Should be (6.0, 8.0) with scale 2.0

    p.print();
    std::cout << "Done" << std::endl;

    return 0;
}
