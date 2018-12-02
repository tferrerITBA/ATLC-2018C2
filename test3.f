
frozone() {
	x = 0
	first = true
	y = 0
	z = 0
	print("Please enter a number greater than 0. You will then have to enter that amount of numbers.")
	scan(x, 1)
	on (x lt 1) do {
		print("Number must be greater than 1.")
	} else {
		cycle {
			scan(y, 1.0)
			on ((y gt z) or (first eq true)) do {
				z = y
			}
			x = x - 1
			first = false
		} on (x gt 0)
		print("The largest number entered is: ")
		print(z)
	}
}
