import pyodbc

# Establecer la conexión
conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=JESUSPC;'
        #'SERVER=ERICKPC;'
        'DATABASE=proyecto3;'
        'UID=sa;' 
        'PWD=12345678'
)

# Leer el archivo XML
with open('SQL\Datos.xml', 'r', encoding='utf-8') as file:
    xml_data = file.read()

# Crear el cursor y ejecutar el procedimiento almacenado
cursor = conn.cursor()
cursor.execute("EXEC CargarDatosDesdeXML ?", xml_data)

# Confirmar los cambios
conn.commit()

# Cerrar la conexión
cursor.close()
conn.close()