# Uso_Procedimientos_Trigger_Funciones_MySql

Ejercicio donde se expone ejemplo para el uso de Procedimientos, Funciones y Trigger con MySql, base de datos con funciones para lamacenar clientes y ventas, donde el sistema valida si tenemos descuentos, acutaliza el saldo del cliente al momento de realizar una compra y vlaidar si el saldo es suficiente para realizar la compra.

# DDL para la creación de la base de datos y las tablas correspondientess

DROP DATABASE IF EXISTS compras;
CREATE DATABASE compras;
USE compras;

CREATE TABLE cliente(
    id_cli INT PRIMARY KEY,
    nombres VARCHAR(50),
    apellidos VARCHAR(50),
    saldo INT
);

CREATE TABLE compras(
    id_comp INT PRIMARY KEY AUTO_INCREMENT,
    fecha TIMESTAMP,
    valor INT,
    id_cli INT
);

ALTER TABLE compras
    ADD CONSTRAINT addCom
    foreign key (id_cli) REFERENCES cliente(id_cli);

# Crea función para determinar si el cliente ibtiene descuento por su compra

CREATE DEFINER=`root`@`localhost` FUNCTION `fun_desc`(com INT) RETURNS int(11)
BEGIN
    declare des int default 0;
    if com > 200000 THEN /* Valida si la compra supera los 200.000 para mayor descuento*/
        SET des = 15;
        ELSE IF com >= 150000 THEN /*Valida si la compra es mayor a 150.000 para un descuento del 15% */
            SET des = 10;
            ELSE IF com >= 100000 THEN  /*Valida si la compra es mayor a 100.000 para un descuento del 15% */
                SET des = 5;
            END IF;
        END IF;
    END IF;
RETURN com-(com*des)/100 /*retorna el valor total a pagar*/;
END

# Procedimeinto almacenado para registrar una nueva venta

CREATE DEFINER=`root`@`localhost` PROCEDURE `new_compra`(
IN com INT,
IN id_cli int
)
BEGIN
DECLARE compra Int;
Set compra = fun_desc(com);/* actualiza el valor de la compra verificando y cambiando*/
insert into compras (valor,id_cli,fecha) VALUES(compra, id_cli,NOW());
END

# Trigger para validar el saldo del cliente al momento de realizar una compra y si es posillble actualizar el saldo del cliente   
CREATE DEFINER=`root`@`localhost` TRIGGER `compras`.`compras_BEFORE_INSERT` BEFORE INSERT ON `compras` FOR EACH ROW
BEGIN
	declare sal int;      #Devlara variable para almacenar el saldo del cliente
    -- Valida si el cliente tiene saldo suficiente para realizar la compra
	    select saldo into sal FROM cliente
        where new.id_cli = cliente.id_cli;
	    
        IF NEW.valor <=	sal THEN -- Verifica si el valor de la compra es menor o igual al saldo del cliente
		    update cliente SET saldo = saldo - new.valor; --Acstualiza  el slado del cliente
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No cuentas con el saldo suficiente para la compra'; --Lanza un error si el saldo no es suficiente
        END IF; 
	    else
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No cuentas con el saldo suficiente para la compra';
	end if;
END