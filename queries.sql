-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

INSERT INTO users (username, password, email, first_name, last_name)
VALUES
    ('user1', 'pass1', 'email1@gmail.com', 'first1', 'last1'),
    ('user2', 'pass2', 'email2@gmail.com', 'first2', 'last2'),
    ('user3', 'pass3', 'email3@gmail.com', 'first3', 'last3');


INSERT INTO companies (c_name)
VALUES
    ('company1'),
    ('company2'),
    ('company3');

INSERT INTO stocks(ticker, company_id, price)
VALUES
    ('C1T1', 1, 1),
    ('C1T2', 1, 2),
    ('C2T1', 1, 3),
    ('C3T1', 1, 4);


INSERT INTO transactions(wallet_id, asset_type, balance_change, transaction_details)
VALUES
    (1, 'money', 101, 'first deposit'),
    (2, 'money', 102, 'first deposit'),
    (3, 'money', 103, 'first deposit');


SELECT * FROM users;
SELECT * FROM stocks;
SELECT * FROM companies;
SELECT * FROM transactions;
SELECT * FROM wallets;

SELECT * FROM money_transactions;

CALL process_stock_transaction('user1', 'C1T2', 3);


SELECT * FROM stock_per_user WHERE user_id = (SELECT user_id FROM users WHERE username = 'user1');

