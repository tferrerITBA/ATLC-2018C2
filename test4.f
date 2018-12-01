foo(0)
bar(2)
irrelevant(4)

frozone(){
	x = 0
	y = 0
	print("This was y before calling foo:")
	print(y)
	y = foo()
	print("This is y now:")
	print(y)
	x = bar(x, x)
	z = 0
	z = bar(y, y)
	print("Variable y in its final form:")
	print(y)
	print("Variable z says:")
	print(z)
}

function foo() {
	print("Hello from foo!")
	print("Leaving foo...")
	return 8
}

function bar(a, b) {
	print("Hello from bar!")
	print("This is a:")
	print(a)
	b = 5
	print("And this looks like b but actually is a:")
	print(a)
	print("Leaving bar...")
	return "The end"
}

function irrelevant(a, b, c, d) {
	return 0
}
