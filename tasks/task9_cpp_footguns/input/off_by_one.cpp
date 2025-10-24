#include <iostream>

// Matrix border detection
class Matrix {
public:
    Matrix() {
        for (int i = 0; i < 5; i++) {
            for (int j = 0; j < 5; j++) {
                data_[i][j] = i * 5 + j;
            }
        }
    }

    void printTopRow() {
        std::cout << "Top row: ";
        // BUG: should be i < 5, not i <= 5
        for (int i = 0; i <= 5; i++) {  // Off-by-one!
            std::cout << data_[0][i] << " ";
        }
        std::cout << std::endl;
    }

private:
    int data_[5][5];
};

int main() {
    Matrix m;
    m.printTopRow();
    std::cout << "Done" << std::endl;

    return 0;
}
