
frozone(){
  a = 0
  b = 0
  print("Please enter a number. Try to guess what this program does with it :)")
  scan(a, 1)
  on (a lt 0) do {
    print("The input must be an integer greater than 0")
  } else {
    cycle {
      b = b + a
      a = a - 1
    } on (a gt 0)
  }
  print(b)
}
