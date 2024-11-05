import pyodbc

# Establecer la conexión
conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=JESUSPC;'
    'DATABASE=Proyecto3BD;'
    'UID=sa;' 
    'PWD=12345678'
)


# Leer el archivo XML y convertirlo a UTF-16
with open('SQL\Datos.xml', 'r', encoding='utf-8') as file:
    xml_data = file.read()


# Crear el cursor y ejecutar el procedimiento almacenado
cursor = conn.cursor()
cursor.execute("EXEC CargarDatosDesdeXML ?", xml_data)  # Pasar xml_data como texto (str)

# Confirmar los cambios
conn.commit()

# Cerrar la conexión
cursor.close()
conn.close()