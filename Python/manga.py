import requests
import time #necesario para poner tiempo
import pyodbc #coneccion de bd con python
import json #para generar jason 
import datetime # Necesario para la conversión de fechas

def Obtener_Manga(num_paginas):
    mangas_list = []
    nombres_vistos = set()  # Para controlar duplicados
    for i in range(1, num_paginas + 1):
        url = f"https://api.jikan.moe/v4/manga?page={i}&limit=25"
        try:
            print(f"Obteniendo página {i} de {num_paginas}...")
            resp = requests.get(url, timeout=10) # Añadir timeout para evitar esperas infinitas
            resp.raise_for_status() 

            datos = resp.json()['data']
            if not datos:
                print(f"No hay más datos en la página {i}. Deteniendo la obtención.")
                break # Salir del bucle si la API ya no devuelve datos

            for manga_data in datos:
                # --- Procesamiento y conversión de Fechas ---
                fecha_emision_str = manga_data.get('published', {}).get('from')
                fecha_emision_obj = None
                if fecha_emision_str:
                    try:
                        # Jikan API ramplaza la forma de tiempo a una que se pueda ver en la db
                        fecha_emision_obj = datetime.datetime.fromisoformat(fecha_emision_str.replace('Z', '+00:00'))
                        fecha_emision_obj = fecha_emision_obj.date() # Convertir a solo fecha para tipo 'date'
                    except ValueError:
                        print(f"Advertencia: No se pudo parsear Fecha_Emision: '{fecha_emision_str}'. Se usará NULL.")
                        fecha_emision_obj = None

                fecha_registro_str = manga_data.get('published', {}).get('to')
                fecha_registro_obj = None
                if fecha_registro_str:
                    try:
                        fecha_registro_obj = datetime.datetime.fromisoformat(fecha_registro_str.replace('Z', '+00:00'))
                    except ValueError:
                        print(f"Advertencia: No se pudo parsear Fecha_Registro: '{fecha_registro_str}'. Se usará NULL.")
                        fecha_registro_obj = None

                nombre = manga_data.get('title', None)
                autor = manga_data.get('authors', [{}])[0].get('name', None) if manga_data.get('authors') else None

                # FILTRO: No permitir datos nulos en ningún campo
                if not (nombre and autor and fecha_emision_obj and fecha_registro_obj):
                    print(f"Manga descartado por datos nulos: Nombre={nombre}, Autor={autor}, Fecha_Emision={fecha_emision_obj}, Fecha_Registro={fecha_registro_obj}")
                    continue

                # Si el nombre ya existe, eliminar el anterior y agregar el nuevo
                if nombre in nombres_vistos:
                    # Eliminar el manga anterior con ese nombre
                    mangas_list = [m for m in mangas_list if m['Nombre'] != nombre]
                    print(f"Nombre duplicado detectado: '{nombre}'. Se reemplaza por el nuevo registro.")
                else:
                    nombres_vistos.add(nombre)

                manga_info = {
                    'Nombre': nombre,
                    'Autor': autor,
                    'Fecha_Emision': fecha_emision_obj,
                    'Fecha_Registro': fecha_registro_obj
                }
                mangas_list.append(manga_info)
            time.sleep(1)  # Esperar 1 segundo entre solicitudes para respetar el rate limit de Jikan
        except requests.exceptions.RequestException as e:
            print(f"Error de red o HTTP en la página {i}: {str(e)}")
            continue
        except KeyError as e:
            print(f"Error de estructura de datos de la API en la página {i}: Clave faltante - {str(e)}")
            continue
        except Exception as e:
            print(f"Error inesperado en la página {i}: {str(e)}")
            continue
    return mangas_list


    

# --- Lógica principal del script ---
try:
    print("Conectando con somme......")
    conn = pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=ServidorMangas.mssql.somee.com;'
        'DATABASE=ServidorMangas;'
        'UID=L00pSsu_SQLLogin_1;'
        'PWD=Joweskate;'
        'TrustServerCertificate=yes;'
        'Encrypt=no;'
    )
    cursor = conn.cursor()

    # Define cuántas páginas de mangas reales quieres obtener
    # Cada página tiene 25 mangas. Para 1000 mangas, serían 40 páginas.
    # Para 3000 mangas, serían 120 páginas.


    PAGINAS_A_OBTENER = 120 # Puedes ajustar este número

    print(f"Obteniendo mangas reales de Jikan API (aproximadamente {PAGINAS_A_OBTENER * 25} registros)...")
    Mangas = Obtener_Manga(PAGINAS_A_OBTENER) 

    if not Mangas:
        print("No se obtuvieron mangas para insertar. Terminando el proceso.")
    else:
        print(f"Insertando {len(Mangas)} mangas en la base de datos...")
        data_to_insert = [
            (manga['Nombre'], manga['Autor'], manga['Fecha_Emision'], manga['Fecha_Registro'])
            for manga in Mangas
        ]

        cursor.executemany(
            """INSERT INTO Mangas(Nombre, Autor, Fecha_Emision, Fecha_Registro) 
            VALUES(?, ?, ?, ?)""",
            data_to_insert
        )

        conn.commit()
        print("¡Datos reales guardados con éxito!")

    cursor.close()
    conn.close()

    print("Guardando backup en JSON...")
    with open('mangas_reales_backup.json', 'w', encoding='utf-8') as f: # Cambiado nombre del archivo
        json.dump(Mangas, f, ensure_ascii=False, indent=4)
    print("¡Proceso completado!")

except pyodbc.Error as ex:
    sqlstate = ex.args[0]
    print(f"Error de conexión o base de datos: SQLSTATE={sqlstate} - {ex.args[1]}")
    if 'conn' in locals() and conn:
        conn.rollback()
except Exception as e:
    print(f"Error inesperado durante el proceso: {str(e)}")