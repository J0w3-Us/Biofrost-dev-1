nombre = "Jose"
edad = "18"
carrera = "Dsm"
cuidad = "Merida"

print("============\nMi tarjeta\n============")
print("Nombre: "+nombre)
print("Edad: "+edad)
print("Carrera: "+carrera)
print("Ciudad: "+cuidad)

while True:

    print("¿Quiers editar la tarjeta?")
    print("Y: Yes")
    print("N: No")
    option = input("Elija una opcion: ")
    match option:

        case "Y":
            print("Ingrese un dato a modificar")
            print("1. Nombre")
            print("2. Edad")
            print("3. Carrera")
            print("4. Cuidad")
            NumOP = input("Elija una opcion: ").lower()

            match NumOP:
                case "1":
                    print("Ingreese una nueva opcion: ")
                    nombre = input("")

                case "2":
                    print("Ingreese una nueva opcion: ")
                    edad = input("")

                case "3":
                    print("Ingreese una nueva opcion: ")
                    carrera = input("")

                case "4":
                    print("Ingreese una nueva opcion: ")
                    cuidad = input("")
        case "N":
            print("Disfrute de su presentacion")    
            break
        