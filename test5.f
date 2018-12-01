foo(1)

frozone(){
	x = 5
	y = 0
	y = foo(x)
	print(y)
	x = -10
	y = foo(x)
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
