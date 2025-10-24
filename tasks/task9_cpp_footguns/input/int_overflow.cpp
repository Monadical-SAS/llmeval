#include <iostream>

// Bulk price calculator
class PriceCalculator {
public:
    // BUG: No overflow check - will overflow with large inputs
    int calculateTotal(int pricePerUnit, int quantity) {
        return pricePerUnit * quantity;  // Can overflow!
    }

    void printOrder(int price, int qty) {
        int total = calculateTotal(price, qty);
        std::cout << "Price: $" << price << " x " << qty << " = $" << total << std::endl;
    }
};

int main() {
    PriceCalculator calc;

    // Small order - works fine
    calc.printOrder(10, 5);

    // Large order - will overflow
    calc.printOrder(100000, 50000);  // 5 billion - overflows int!

    std::cout << "Done" << std::endl;

    return 0;
}
