CREATE DATABASE chaindb;

CREATE USER 'chaindb'@'localhost' IDENTIFIED BY 'ce5Sxish';
GRANT ALL ON chaindb.* TO 'chaindb'@'localhost';
grant SELECT on chaindb.* to 'chaindbro'@'%' identified by 'chaindbro';

use chaindb;



CREATE TABLE TRANSFERS
(
 network     VARCHAR(15) NOT NULL,
 seq         BIGINT UNSIGNED NOT NULL,
 block_num   BIGINT NOT NULL,
 block_time  DATETIME NOT NULL,
 trx_id      VARCHAR(64) NOT NULL,
 contract    VARCHAR(13) NOT NULL,
 currency    VARCHAR(8) NOT NULL,
 amount      BIGINT NOT NULL,
 decimals    TINYINT NOT NULL,
 tx_from     VARCHAR(13) NULL,
 tx_to       VARCHAR(13) NOT NULL,
 memo        TEXT
)  ENGINE=InnoDB;


CREATE UNIQUE INDEX TRANSFERS_i01 ON TRANSFERS (network,seq);
CREATE INDEX TRANSFERS_I02 ON TRANSFERS (network,block_num);
CREATE INDEX TRANSFERS_I03 ON TRANSFERS (network,block_time);
CREATE INDEX TRANSFERS_I04 ON TRANSFERS (network,trx_id(8));
CREATE INDEX TRANSFERS_I05 ON TRANSFERS (network,tx_from, contract, currency, block_num);
CREATE INDEX TRANSFERS_I06 ON TRANSFERS (network,tx_to, contract, currency, block_num);
CREATE INDEX TRANSFERS_I07 ON TRANSFERS (network,tx_to, block_num);
CREATE INDEX TRANSFERS_I08 ON TRANSFERS (network,tx_from, block_num);
CREATE INDEX TRANSFERS_I09 ON TRANSFERS (network,contract, block_num);



CREATE TABLE BALANCES
 (
 network           VARCHAR(15) NOT NULL,
 account_name      VARCHAR(13) NOT NULL,
 block_num         BIGINT NOT NULL,
 block_time        DATETIME NOT NULL,
 contract          VARCHAR(13) NOT NULL,
 currency          VARCHAR(8) NOT NULL,
 amount            BIGINT NOT NULL,
 decimals          TINYINT NOT NULL,
 deleted           TINYINT NOT NULL    
) ENGINE=InnoDB;

CREATE UNIQUE INDEX BALANCES_I01 ON BALANCES (network, account_name, contract, currency, block_num );






