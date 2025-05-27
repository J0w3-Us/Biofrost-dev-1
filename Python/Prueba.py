Nombre = input("¿como te llamas?")
edad = int(input("¿cuantos años tienes?"))

if edad < 18:
    print("Axceso denegado \nvuelve cuando seas mayor")

elif edad > 80:
    print("Ya descanse anciano")

else:
    print("Bienvenido "+ Nombre)
    contraseña = input("¿Cual es la contraseña?").lower()

    if contraseña == "dragon":
        print ("Bienvenodo a su progrma master")

        while True:
            print("\n--- MENU ---")
            print("1. Suma")
            print("2. Resta")
            print("3. Multiplicacion")
            print("4. Division")
            print("0. Cerrar")

            opcion = input("Escoja una opcion ")

            match opcion:
                case "1":
                    print("Ingrese dos diguitos")
                    Num = int(input("Ingrese el primer diguito: "))
                    num2 = int(input("Ingrese el segundo dígito: "))
                    suma = Num + num2
                    print(f"El resultado es {suma}")
                    
                    opc = input("Quieres continuar (Y/N)")
                    if opc.upper == "N":
                        input("saliendo de la suma")
                        break
                
                case "2":
                    print("Ingrese dos diguitos")
                    Num = int(input("Ingrese el primer diguito: "))
                    num2 = int(input("Ingrese el segundo dígito: "))
                    rest = Num - num2
                    print(f"El resultado es {rest}")

                    opc = input("Quieres continuar (Y/N)")
                    if opc.upper == "N":
                        input("saliendo de la suma")
                        break

                case "3":
                    print("Ingrese dos diguitos")
                    Num = int(input("Ingrese el primer diguito: "))
                    num2 = int(input("Ingrese el segundo dígito: "))
                    mult = Num * num2
                    print(f"El resultado es {mult}")

                    opc = input("Quieres continuar (Y/N)")
                    if opc.upper == "N":
                        input("saliendo de la suma")
                        break

                case "4":
                    print("Ingrese dos diguitos")
                    Num = int(input("Ingrese el primer diguito: "))
                    num2 = int(input("Ingrese el segundo dígito: "))

                    if num2 == 0:
                        print("impusible de dividir....\n intente denuevo")
                    else:
                        div = Num / num2
                        print(f"el reseultado es {div}")

                    sPrograma = input("Quieres continuar (Y/N)"). upper()
                    if sPrograma == "Y":
                        print("saliendo de la division")
                        break

                case "0":
                    break

    else:
        print("Buen intento \n intenta cuendo no seas un wey")