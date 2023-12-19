USE music_service;
GO

DROP VIEW IF EXISTS UsersPlaylists;
GO

DROP TABLE IF EXISTS Playlists;
GO

DROP TABLE IF EXISTS Users;
GO

CREATE TABLE Users
(
    Id INT IDENTITY PRIMARY KEY,
    Email NVARCHAR(320) UNIQUE NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    PasswordHash NVARCHAR(100) NOT NULL,
    Age INT NOT NULL DEFAULT 18 CHECK(Age > 0),
    AvatarPath NVARCHAR(100) NOT NULL DEFAULT 'default_avatar.jpg',
);
GO

INSERT INTO Users (Email, Name, PasswordHash)
VALUES
('email_1@example.com', 'name_1', 'password hash'),
('email_2@example.com', 'name_2', 'password hash');
GO

SELECT * FROM Users;
GO

-- 1. Исследовать и проиллюстрировать на примерах различные уровни изоляции транзакций MS SQL Server, устанавливаемые с
-- использованием инструкции SET TRANSACTION ISOLATION LEVEL.

-- потерянное обновление (lost update): при одновременном изменении одного блока данных разными транзакциями теряются
-- все изменения, кроме последнего;

-- грязное чтение (dirty read): чтение транзакцией записи, измененной другой транзакцией, при этом эти изменения еще не
-- зафиксированы;

-- невоспроизводимое чтение (non-repeatable read): при повторном чтении транзакция обнаруживает измененные или удаленные
-- данные, зафиксированные другой транзакцией;

-- фантомное чтение (phantom read): при повторном чтении транзакция обнаруживает новые строки, вставленные другой
-- завершенной транзакцией;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
-- Указывает, что инструкции могут считывать строки, которые были изменены другими транзакциями, но еще не были
-- зафиксированы.

-- Защита от потерянного обновления.
-- Уязвимость к грязному, невоспроизводимому, фантомному чтению.

-- Терминал 1
BEGIN TRANSACTION;
UPDATE Users SET Name = 'some_name' WHERE Id = 1;
WAITFOR DELAY '00:00:10';
ROLLBACK TRANSACTION;

-- Терминал 2
BEGIN TRANSACTION;
SELECT * FROM Users WHERE Id = 1;
COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED
-- Указывает, что инструкции не могут считывать данные, которые были изменены другими транзакциями, но еще не были
-- зафиксированы.

-- Защита от грязного чтения, потерянного обновления.
-- Уязвимость к невоспроизводимому, фантомному чтению.

-- Терминал 1
BEGIN TRANSACTION;
SELECT * FROM Users WHERE Id = 1;
WAITFOR DELAY '00:00:10';
SELECT * FROM Users WHERE Id = 1;
COMMIT TRANSACTION;

-- Терминал 2
BEGIN TRANSACTION;
UPDATE Users SET AvatarPath = 'new_avatar.jpg' WHERE Id = 1;
COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
-- Указывает на то, что инструкции не могут считывать данные, которые были изменены, но еще не зафиксированы другими
-- транзакциями, а также на то, что другие транзакции не могут изменять данные, читаемые текущей транзакцией, до ее
-- завершения.

-- Защита от невоспроизводимого, грязного чтения, потерянного обновления.
-- Уязвимость к фантомному чтению.

-- Терминал 1
BEGIN TRANSACTION;
SELECT * FROM Users;
WAITFOR DELAY '00:00:10';
SELECT * FROM Users;
COMMIT TRANSACTION;

-- Терминал 2
BEGIN TRANSACTION;
INSERT INTO Users (Email, Name, PasswordHash)
VALUES
    ('email_3@example.com', 'name_3', 'password hash');
COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
-- Указывает следующее.
-- 1. Инструкции не могут считывать данные, которые были изменены другими транзакциями, но еще не были зафиксированы.
-- 2. Другие транзакции не могут изменять данные, считываемые текущей транзакцией, до ее завершения.
-- 3. Другие транзакции не могут вставлять новые строки со значениями ключа, которые входят в диапазон ключей,
--    считываемых инструкциями текущей транзакции, до ее завершения.

-- Защита от фантомного, невоспроизводимого, грязного чтения, потерянного обновления.

-- 2. Накладываемые блокировки исследовать с использованием sys.dm_tran_locks

-- Мониторить в транзакциях как, например, здесь:

-- Терминал 1
BEGIN TRANSACTION;
UPDATE Users SET Name = 'some_name' WHERE Id = 1;
WAITFOR DELAY '00:00:10';
ROLLBACK TRANSACTION;

-- Терминал 2
BEGIN TRANSACTION;
SELECT * FROM sys.dm_tran_locks;
SELECT * FROM Users WHERE Id = 1;
COMMIT TRANSACTION;
