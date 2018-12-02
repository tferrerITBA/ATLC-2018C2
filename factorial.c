#include <stdio.h>

int factorial(int);

int main() {
	int x = 10;
	printf("Factorial es:\n%d\n", factorial(x));
	return 0;
}

int factorial(int num) {
	if(num == 0) {
		return 1;
	}
	return num * factorial(num - 1);
}
