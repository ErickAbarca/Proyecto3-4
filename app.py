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
        #'SERVER=ERICKPC;'
        'SERVER=JESUSPC;'
        'DATABASE=proyecto3;'
        'UID=sa;' 
        #'UID=hola;' 
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


@app.route('/cuentasTH', methods=['GET'])
def abrir_movimiento_empleado():
    username = request.args.get('username')
    documento = request.args.get('documento')
    return render_template('detalle.html', username=username, documento=documento)

@app.route('/tarjetas', methods=['GET'])
def get_tarjetas():
    documento_identidad = request.args.get('documento')
    print(documento_identidad)

    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            DECLARE	@OutResultCode int

            EXEC	[dbo].[SP_ConsultarTarjetasPorTarjetahabiente]
		    @documentoIdentidad = ?,
		    @OutResultCode = @OutResultCode OUTPUT

            SELECT	@OutResultCode as N'@OutResultCode'
        """ , documento_identidad)
        rows = cursor.fetchall()    
        
        tarjetas = []
        for row in rows:
            tarjetas.append({
                'numero_tarjeta': row[0],
                'estado': row[1],
                'fecha_vencimiento': row[2],
                'tipo_cuenta': row[3]
            })
        
        cursor.execute("""
        EXEC [dbo].[SP_ObtenerCuentasPorTarjetahabiente]
		@documento_identidad = ?
        """, documento_identidad)

        rows = cursor.fetchall()

        cuentas = []
        for row in rows:
            cuentas.append({
                'nombre': row[1],
                'cuenta': row[3],
                'limite': row[4],
                'saldo': row[5],
                'fecha_apertura': row[6],
                'tipo_cuenta': row[7]
            })

        cursor.execute("""
        EXEC [dbo].[SP_ConsultarCuentaAdicional]
		@documento_identidad = ?
        """, documento_identidad)

        rows = cursor.fetchall()

        adicionales = []
        for row in rows:
            adicionales.append({
                'cuenta': row[0],
                'maestra': row[1],
                'documento': row[2],
                'nombre': row[3]
            })

        conn.commit()

        return jsonify({'tarjetas': tarjetas, 'cuenta': cuentas, 'adicionales': adicionales})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
    finally:
        cursor.close()
        conn.close()

@app.route('/estadosTH', methods=['GET'])
def abrirEstados():
    username = request.args.get('username')
    documento = request.args.get('documento')
    return render_template('estados.html', username=username, documento=documento)

@app.route('/estados', methods=['GET'])
def get_estados():
    cuentaId = request.args.get('documento')

    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            EXEC	[dbo].[SP_ObtenerEstadoCuenta]
            @id_cuenta = ?
        """ , cuentaId)
        rows = cursor.fetchall()    
        
        estados = []
        for row in rows:
            estados.append({
                'id_cuenta': row[0],
                'fecha': row[1],
                'saldo': row[2],
                'pago_minimo': row[3],
                'pago_contado': row[4],
                'intereses_corrientes': row[5],
                'intereses_moratorios': row[6]
            })
        
        conn.commit()

        return jsonify({'estados': estados})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
    finally:
        cursor.close()
        conn.close()

@app.route('/subEstadosTH', methods=['GET'])
def abrirSubEstados():
    username = request.args.get('username')
    documento = request.args.get('documento')
    return render_template('subEstados.html', username=username, documento=documento)

@app.route('/subEstados', methods=['GET'])
def get_Subestados():
    cuentaId = request.args.get('documento')

    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            EXEC	[dbo].[SP_ConsultarSubEstadoCuenta]
            @num_cuenta = ?
        """ , cuentaId)
        rows = cursor.fetchall()    
        
        estados = []
        for row in rows:
            estados.append({
                'id_cuenta': row[0],
                'fecha': row[1],
                'saldo': row[2],
                'pago_minimo': row[3],
                'pago_contado': row[4],
                'intereses_corrientes': row[5],
                'intereses_moratorios': row[6]
            })
        
        conn.commit()

        return jsonify({'estados': estados})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
    finally:
        cursor.close()
        conn.close()


if __name__ == '__main__':
    app.run(debug=True)
