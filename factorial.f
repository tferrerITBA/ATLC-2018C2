factorial(1)

frozone() {
	x = 10
	x = factorial(x)
	print("Factorial es:")
	print(x)
}

function factorial(num) {
	on (num eq 0) do {
		return 1
	}
	next_num = num - 1
	acum = factorial(next_num)
	acum = acum * num
	return acum
}
