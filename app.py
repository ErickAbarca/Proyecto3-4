from datetime import datetime
from flask import Flask, jsonify, redirect, render_template, request, url_for
import pyodbc
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Configuración de la conexión a la base de datos
def get_db_connection():
    connection = pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=JESUSPC;'
        'DATABASE=proyecto3;'
        'UID=sa;'
        'PWD=12345678'
    )
    return connection

@app.route('/')
def index():
    return render_template('index.html')

# Ruta para obtener todos los tarjetahabientes
@app.route('/tarjetahabientes', methods=['GET'])
def get_tarjetahabientes():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, nombre, documento_identidad, nombre_usuario FROM Tarjetahabiente")
    rows = cursor.fetchall()
    conn.close()
    
    tarjetahabientes = []
    for row in rows:
        tarjetahabientes.append({
            'id': row[0],
            'nombre': row[1],
            'documento_identidad': row[2],
            'nombre_usuario': row[3]
        })
    
    return jsonify(tarjetahabientes)

# Ruta para procesar la acción seleccionada
@app.route('/accion', methods=['POST'])
def accion():
    accion = request.json.get('accion')
    id_tarjetahabiente = request.json.get('id')
    
    # Aquí puedes añadir las acciones específicas según el valor de `accion`
    # Por ejemplo, eliminar, actualizar, bloquear, etc.
    # Retornamos una respuesta de ejemplo
    return jsonify({'message': f'Acción {accion} realizada en tarjetahabiente {id_tarjetahabiente}'})

if __name__ == '__main__':
    app.run(debug=True)
