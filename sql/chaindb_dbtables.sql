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
CREATE INDEX TRANSFERS_I04 ON TRANSFERS (network,trx_id(8));
CREATE INDEX TRANSFERS_I05 ON TRANSFERS (network,tx_from, contract, currency, block_num);
CREATE INDEX TRANSFERS_I06 ON TRANSFERS (network,tx_to, contract, currency, block_num);
CREATE INDEX TRANSFERS_I07 ON TRANSFERS (network,tx_to, block_num);
CREATE INDEX TRANSFERS_I08 ON TRANSFERS (network,tx_from, block_num);
CREATE INDEX TRANSFERS_I09 ON TRANSFERS (network,contract, block_num);


CREATE TABLE ISSUANCES
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
 tx_to       VARCHAR(13) NOT NULL,
 memo        TEXT
)  ENGINE=InnoDB;


CREATE UNIQUE INDEX ISSUANCES_i01 ON ISSUANCES (network,seq);
CREATE INDEX ISSUANCES_I02 ON ISSUANCES (network,block_num);
CREATE INDEX ISSUANCES_I04 ON ISSUANCES (network,trx_id(8));
CREATE INDEX ISSUANCES_I05 ON ISSUANCES (network,tx_to, contract, currency, block_num);
CREATE INDEX ISSUANCES_I06 ON ISSUANCES (network,tx_to, block_num);
CREATE INDEX ISSUANCES_I07 ON ISSUANCES (network,contract, block_num);



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

CREATE UNIQUE INDEX BALANCES_I01 ON BALANCES (network, account_name, contract, currency, block_num);
CREATE INDEX BALANCES_I02 ON BALANCES (network, block_num);


CREATE TABLE BALANCES_EXT
 (
 network           VARCHAR(15) NOT NULL,
 account_name      VARCHAR(13) NOT NULL,
 block_num         BIGINT NOT NULL,
 block_time        DATETIME NOT NULL,
 contract          VARCHAR(13) NOT NULL,
 field             VARCHAR(14) NOT NULL,
 value             VARCHAR(256) NOT NULL,
 deleted           TINYINT NOT NULL    
) ENGINE=InnoDB;

CREATE UNIQUE INDEX BALANCES_EXT_I01 ON BALANCES_EXT (network, account_name, contract, field, block_num);
CREATE INDEX BALANCES_EXT_I02 ON BALANCES_EXT (network, account_name, contract, field, value);
CREATE INDEX BALANCES_EXT_I03 ON BALANCES_EXT (network, block_num);



CREATE TABLE DELBAND
(
 network           VARCHAR(15) NOT NULL,
 account_name      VARCHAR(13) NOT NULL,
 del_from          VARCHAR(13) NOT NULL,
 block_num         BIGINT NOT NULL,
 block_time        DATETIME NOT NULL,
 cpu_weight        BIGINT UNSIGNED NOT NULL,
 net_weight        BIGINT UNSIGNED NOT NULL
) ENGINE=InnoDB;

CREATE UNIQUE INDEX DELBAND_I01 ON DELBAND (network, account_name, del_from, block_num);
CREATE INDEX DELBAND_I02 ON DELBAND (network, del_from, block_num);
CREATE INDEX DELBAND_I03 ON DELBAND (network, block_num);


CREATE TABLE USERRES
(
 network           VARCHAR(15) NOT NULL,
 account_name      VARCHAR(13) NOT NULL,
 block_num         BIGINT NOT NULL,
 block_time        DATETIME NOT NULL,
 cpu_weight        BIGINT UNSIGNED NOT NULL,
 net_weight        BIGINT UNSIGNED NOT NULL,
 ram_bytes         BIGINT UNSIGNED NOT NULL
) ENGINE=InnoDB;

CREATE UNIQUE INDEX USERRES_I01 ON USERRES (network, account_name, block_num);
CREATE INDEX USERRES_I02 ON USERRES (network, block_num);




CREATE TABLE REXFUND
 (
 network           VARCHAR(15) NOT NULL,
 account_name      VARCHAR(13) NOT NULL,
 block_num         BIGINT NOT NULL,
 block_time        DATETIME NOT NULL,
 balance           BIGINT UNSIGNED NOT NULL
) ENGINE=InnoDB;

CREATE UNIQUE INDEX REXFUND_I01 ON REXFUND (network, account_name, block_num);
CREATE INDEX REXFUND_I02 ON REXFUND (network, block_num);

CREATE TABLE REXBAL
 (
 network           VARCHAR(15) NOT NULL,
 account_name      VARCHAR(13) NOT NULL,
 block_num         BIGINT NOT NULL,
 block_time        DATETIME NOT NULL,
 vote_stake        BIGINT UNSIGNED NOT NULL,
 rex_balance       BIGINT UNSIGNED NOT NULL
) ENGINE=InnoDB;

CREATE UNIQUE INDEX REXBAL_I01 ON REXBAL (network, account_name, block_num);
CREATE INDEX REXBAL_I02 ON REXBAL (network, block_num);



