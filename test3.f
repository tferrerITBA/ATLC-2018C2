
frozone() {
	x = 0
	y = 0
	z = 0
	print("Please enter a number. You will then have to enter that amount of numbers.")
	scan(x, 1)
	on (x lt 0) do {
		print("Number must be greater than 0.")
	} else {
		cycle {
			scan(y, 1.0)
			on (y gt z) do {
				z = y + 0
			}
			x = x - 1
		} on (x gt 0)
	}
	print("The largest number entered is: ")
	print(z)
}
