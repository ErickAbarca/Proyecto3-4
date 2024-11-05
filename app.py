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
        'PWD=12345678'
    )
    return connection

@app.route('/')
def index():
    return render_template('login.html')


if __name__ == '__main__':
    app.run(debug=True)