foo(1)

frozone(){
	x = 5
	y = x + 2.5
	y = foo(y)
	print(y)
	x = -10 + 5
	y = x + 2.5
	y = foo(y)
	print(y)
}

function foo(x) {
	print(x)
	on (x gt 0) do {
		return "Great! Positive integers are the best!"
	} else {
		return "I don't like negative numbers..."
	}
	return 0
}
