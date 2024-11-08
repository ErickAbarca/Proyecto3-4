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
        'SERVER=ERICKPC;'
        'DATABASE=proyecto3;'
        'UID=hola;' 
        'PWD=12345678'
    )
    return connection

@app.route('/')
def index():
    return render_template('login.html')

@app.route('/login', methods=['GET'])
def login():
    username = request.args.get('usuario')
    password = request.args.get('contrasena')

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
                DECLARE	@OutResultCode int

EXEC	[dbo].[ValidarUsuario]
		@username = ?,
		@password = ?,
		@OutResultCode = @OutResultCode OUTPUT

SELECT	@OutResultCode as N'@OutResultCode'

                """, (username, password))

        out_result_code = cursor.fetchone()[0]
        print('hola',out_result_code)


        conn.commit()

        if out_result_code == 50005:
            return redirect(url_for('pagina_principal', username=username))
        else:
            return jsonify({'OutResultCode': out_result_code})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/pagina_principal/<username>')
def pagina_principal(username):
    return render_template('index.html', username=username)


@app.route('/tarjetahabientes', methods=['GET'])
def get_tarjetahabientes():

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
        EXEC [dbo].[getTHs]
        """)
        tarjetahabientes = cursor.fetchall()

        res = []

        for t in tarjetahabientes:
            res.append({
                'id': t[0],
                'nombre': t[1],
                'documento_identidad': t[2],
            })

        conn.commit()

        return jsonify(res)
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()



@app.route('/accion', methods=['POST'])
def accion():
    accion = request.json.get('accion')
    id_tarjetahabiente = request.json.get('id')
    
    return jsonify({'message': f'Acción {accion} realizada en tarjetahabiente {id_tarjetahabiente}'})

if __name__ == '__main__':
    app.run(debug=True)
