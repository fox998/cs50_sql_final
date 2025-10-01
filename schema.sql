-- This schema is designed for a simple stock trading service.
-- It models users, their wallets, companies, stocks, and a unified
-- transaction history that handles both money and stock movements.

-- The `users` table stores user account information.
CREATE TABLE users(
    user_id INT AUTO_INCREMENT PRIMARY KEY,

    username VARCHAR(256) NOT NULL UNIQUE,
    email VARCHAR(256) NOT NULL UNIQUE,

    password VARCHAR(256) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL
);

-- `wallets` store the monetary balance for each user.
-- could be added several wallets per user (different currencys or test acount)
-- more secure
CREATE TABLE wallets(
    wallet_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,
    balance DECIMAL(12, 3) NOT NULL DEFAULT 0,

    FOREIGN KEY (user_id) REFERENCES users(user_id)
);


-- `companies` stores details about companies whose stocks are traded.
-- one company could have several stocks
CREATE TABLE companies(
    company_id INT AUTO_INCREMENT PRIMARY KEY,

    c_name VARCHAR(255),
    details TEXT
);


-- `stocks` holds information about each stock.
CREATE TABLE stocks(
    stock_id INT AUTO_INCREMENT PRIMARY KEY,

    ticker VARCHAR(5) NOT NULL UNIQUE,
    company_id INT NOT NULL,
    price DECIMAL(12, 4) NOT NULL CHECK (price > 0),

    FOREIGN KEY (company_id) REFERENCES companies(company_id)
);


-- `transactions` is a unified table for both money and stock transactions.
CREATE TABLE transactions(
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,

    date_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    wallet_id INT NOT NULL,
    asset_type ENUM('stock', 'money') NOT NULL,
    balance_change DECIMAL(10, 3) NOT NULL,
    share_count INT CHECK (share_count != 0),
    stock_id INT,
    transaction_details TINYTEXT,

    FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id),
    FOREIGN KEY (stock_id) REFERENCES stocks(stock_id),

    CONSTRAINT check_transaction_type CHECK (
        (asset_type = 'stock' AND share_count IS NOT NULL AND stock_id IS NOT NULL AND transaction_details IS NULL) OR
        (asset_type = 'money' AND share_count IS NULL AND stock_id IS NULL AND transaction_details IS NOT NULL)
    )
);
CREATE INDEX transaction_time_index ON transactions(date_time);


CREATE VIEW stock_transactions AS
    SELECT transaction_id, date_time, wallet_id, balance_change, share_count, stock_id
    FROM transactions
    WHERE asset_type = 'stock';

CREATE VIEW money_transactions AS
    SELECT transaction_id, date_time, wallet_id, balance_change, transaction_details
    FROM transactions
    WHERE asset_type = 'money';


-- asume for now that user have only one wallet
CREATE VIEW stock_per_user AS
    WITH
        group_by_stock AS (
            SELECT
                wallet_id,
                stock_id,
                SUM(share_count) AS count,
                SUM(balance_change) AS net_balance_change
            FROM stock_transactions
            GROUP BY wallet_id, stock_id
        ),
        join_stocks AS (
            SELECT
                wallet_id,
                stock_id,
                ticker,
                price,
                count,
                net_balance_change / count AS avg_buy,
                price * count AS current_value
            FROM group_by_stock JOIN stocks USING (stock_id)
        )
    SELECT
        w.user_id,
        j.*
    FROM join_stocks AS j JOIN wallets AS w USING (wallet_id);


DELIMITER $$

CREATE TRIGGER insert_transaction_trigger
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE owned_stock_count INT;
    DECLARE current_balance DECIMAL(12, 3);

    SELECT balance INTO current_balance
    FROM wallets
    WHERE wallet_id = NEW.wallet_id;

    -- buy or withdrow operation
    IF NEW.balance_change < 0 AND current_balance < -NEW.balance_change THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough money on balance';

    -- sell stock
    ELSEIF NEW.balance_change > 0 AND NEW.asset_type = 'stock' THEN
        SELECT count INTO owned_stock_count
        FROM transactions_per_wallet
        WHERE wallet_id = NEW.wallet_id AND stock_id = NEW.stock_id;

        IF owned_stock_count IS NULL OR owned_stock_count < -NEW.share_count THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough shares owned';
        END IF;
    END IF;

    -- update actual balanse
    UPDATE wallets SET balance = balance + NEW.balance_change WHERE wallet_id = NEW.wallet_id;
END$$

CREATE TRIGGER insert_user_trigger
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    INSERT INTO wallets(user_id) VALUES (NEW.user_id);
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE process_stock_transaction(
    IN p_username VARCHAR(256),
    IN p_ticker VARCHAR(5),
    IN p_share_count INT
)
BEGIN
    -- Declare local variables to store values from the CTEs.
    DECLARE v_wallet_id INT;
    DECLARE v_stock_id INT;
    DECLARE v_price DECIMAL(12, 4);


    SELECT wallet_id INTO v_wallet_id
    FROM wallets
    WHERE user_id = (SELECT user_id FROM users WHERE username = p_username);

    SELECT stock_id, price INTO v_stock_id, v_price
    FROM stocks
    WHERE ticker = p_ticker;

    -- Insert the new transaction record.
    INSERT INTO transactions (
        wallet_id,
        asset_type,
        balance_change,
        share_count,
        stock_id
    )
    VALUES (
        v_wallet_id,
        'stock',
        v_price * p_share_count * -1,
        p_share_count,
        v_stock_id
    );

END$$

DELIMITER ;
