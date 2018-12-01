
frozone(){
  a = 0
  b = 0
  scan(a, 1)
  on (a lt 0) do {
    print("El numero ingresado debe ser mayor a 0")
  } else {
    cycle {
      b = b + a
      a = a - 1
    } on (a gt 0)
  }
  print(b)
}
