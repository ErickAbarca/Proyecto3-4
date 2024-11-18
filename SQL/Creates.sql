CREATE TABLE TipoCuentaMaestra (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre_tipo_tcm VARCHAR(16) NOT NULL
);


CREATE TABLE TipoMovimiento (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre_tipo_movimiento VARCHAR(64) NOT NULL,
    accion VARCHAR(16) NOT NULL  -- Débito o Crédito
);


CREATE TABLE MotivoInvalidacionTarjeta (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre_motivo VARCHAR(32) NOT NULL
);

CREATE TABLE UsuarioAdministrador (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre_usuario VARCHAR(64) NOT NULL,
    password VARCHAR(128) NOT NULL
);

CREATE TABLE TipoDocumento (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre_tipo_documento VARCHAR(64) NOT NULL,
    formato VARCHAR(32) NOT NULL
);

CREATE TABLE TipoReglasNegocio (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(64) NOT NULL,
    tipo VARCHAR(16) NOT NULL
);

CREATE TABLE Tarjetahabiente (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(128) NOT NULL,
    id_tipo_documento INT,
    documento_identidad VARCHAR(32) NOT NULL UNIQUE,
    nombre_usuario VARCHAR(64) NOT NULL,
    password VARCHAR(128) NOT NULL,
    FOREIGN KEY (id_tipo_documento) REFERENCES TipoDocumento(id)
);

CREATE TABLE CuentaTarjetaMaestra (
    id INT PRIMARY KEY IDENTITY(1,1),
    codigo_tcm VARCHAR(32) NOT NULL UNIQUE,
    tipo_tcm INT,  -- Referencia a catálogo
    limite_credito DECIMAL(18,2) NOT NULL,
    saldo_actual DECIMAL(18,2) NOT NULL DEFAULT 0,
    id_th INT NOT NULL,  -- Relación con Tarjetahabiente
    fecha_creacion DATE NOT NULL,
    FOREIGN KEY (id_th) REFERENCES Tarjetahabiente(id),
    FOREIGN KEY (tipo_tcm) REFERENCES TipoCuentaMaestra(id)
);

CREATE TABLE CuentaTarjetaAdicional (
    id INT PRIMARY KEY IDENTITY(1,1),
    codigo_tca VARCHAR(32) NOT NULL UNIQUE,
    id_tcm INT NOT NULL,  -- Relación con Cuenta Maestra
    id_th INT NOT NULL,  -- Relación con Tarjetahabiente que usa la TCA
    FOREIGN KEY (id_tcm) REFERENCES CuentaTarjetaMaestra(id),
    FOREIGN KEY (id_th) REFERENCES Tarjetahabiente(id)
);

CREATE TABLE TarjetaFisica (
    id INT PRIMARY KEY IDENTITY(1,1),
    numero_tarjeta VARCHAR(16) NOT NULL UNIQUE,
    cvv VARCHAR(4) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    id_tca INT,  -- Puede estar asociada a una TCA o TCM
    id_tcm INT,
    estado VARCHAR(16) NOT NULL DEFAULT 'Activa',  -- Activa o No Activa
    FOREIGN KEY (id_tca) REFERENCES CuentaTarjetaAdicional(id),
    FOREIGN KEY (id_tcm) REFERENCES CuentaTarjetaMaestra(id)
);

CREATE TABLE Movimiento (
    id INT PRIMARY KEY IDENTITY(1,1),
    id_tf INT NOT NULL,  -- Relación con Tarjeta Física
    fecha_movimiento DATETIME NOT NULL,
    tipo_movimiento INT,  -- Referencia a catálogo
    monto DECIMAL(18,2) NOT NULL,
    descripcion VARCHAR(256),
    referencia VARCHAR(64),
    FOREIGN KEY (id_tf) REFERENCES TarjetaFisica(id),
    FOREIGN KEY (tipo_movimiento) REFERENCES TipoMovimiento(id)
);

CREATE TABLE ReglaNegocio (
    id INT PRIMARY KEY IDENTITY(1,1),
    tipo_regla INT,  -- Referencia a catálogo
    tipo_tcm VARCHAR(16) NOT NULL,  -- Corporativo, Oro, Platino
    limite_credito_max DECIMAL(18,2) NOT NULL,
    tasa_interes_mensual DECIMAL(5,2) NOT NULL,
    tasa_interes_mora DECIMAL(5,2) NOT NULL,
    cargo_servicio_tcm DECIMAL(10,2) NOT NULL,
    cargo_servicio_tca DECIMAL(10,2) NOT NULL,
    plazo_meses INT NOT NULL,
    FOREIGN KEY (tipo_regla) REFERENCES TipoReglasNegocio(id)
);

CREATE TABLE InteresCorriente (
    id INT PRIMARY KEY IDENTITY(1,1),
    id_tcm INT NOT NULL,  -- Relación con Cuenta Maestra
    fecha_operacion DATE NOT NULL,
    monto_interes DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (id_tcm) REFERENCES CuentaTarjetaMaestra(id)
);

CREATE TABLE InteresMoratorio (
    id INT PRIMARY KEY IDENTITY(1,1),
    id_tcm INT NOT NULL,  -- Relación con Cuenta Maestra
    fecha_operacion DATE NOT NULL,
    monto_interes DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (id_tcm) REFERENCES CuentaTarjetaMaestra(id)
);

CREATE TABLE EstadoCuenta (
    id INT PRIMARY KEY IDENTITY(1,1),
    id_tcm INT NOT NULL,  -- Relación con Cuenta Maestra
    fecha_corte DATE NOT NULL,
    saldo_actual DECIMAL(18,2) NOT NULL,
    pago_minimo DECIMAL(18,2) NOT NULL,
    pago_contado DECIMAL(18,2) NOT NULL,
    intereses_corrientes DECIMAL(18,2) NOT NULL,
    intereses_moratorios DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (id_tcm) REFERENCES CuentaTarjetaMaestra(id)
);

CREATE TABLE SubEstadoCuenta (
    id INT PRIMARY KEY IDENTITY(1,1),
    id_tcm INT NOT NULL,                 
    id_tca INT NOT NULL,                
    fecha_corte DATE NOT NULL,          
    saldo_actual DECIMAL(18,2) NOT NULL, 
    pago_minimo DECIMAL(18,2) NOT NULL,  
    pago_contado DECIMAL(18,2) NOT NULL, 
    intereses_corrientes DECIMAL(18,2),
    intereses_moratorios DECIMAL(18,2),
    FOREIGN KEY (id_tcm) REFERENCES CuentaTarjetaMaestra(id),
    FOREIGN KEY (id_tca) REFERENCES CuentaTarjetaAdicional(id) 
);

CREATE TABLE HistorialEstadoTarjeta (
    id INT PRIMARY KEY IDENTITY(1,1),
    id_tarjeta INT NOT NULL,
    estado_anterior VARCHAR(16),
    nuevo_estado VARCHAR(16),
    fecha_cambio DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (id_tarjeta) REFERENCES TarjetaFisica(id)
);

CREATE TABLE [dbo].[DBErrors](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [varchar](128) NULL,
	[Number] [int] NULL,
	[State] [int] NULL,
	[Severity] [int] NULL,
	[Line] [int] NULL,
	[Procedure] [varchar](64) NULL,
	[Message] [varchar](512) NULL,
	[DateTime] [datetime] NULL
);


