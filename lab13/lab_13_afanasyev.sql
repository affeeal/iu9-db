-- 1. Создать две базы данных на одном экземпляре СУБД SQL Server 2012
USE master;
GO

DROP DATABASE IF EXISTS MusicService1;
GO

CREATE DATABASE MusicService1;
GO

DROP DATABASE IF EXISTS MusicService2;
GO

CREATE DATABASE MusicService2;
GO

-- 2. Создать в базах данных п.1. горизонтально фрагментированные таблицы.
USE MusicService1;
GO

DROP TABLE IF EXISTS Users;
GO

CREATE TABLE Users
(
    Id INT PRIMARY KEY CHECK (Id BETWEEN 1 AND 3),
    Email NVARCHAR(320) NOT NULL UNIQUE,
    Name NVARCHAR(50) NOT NULL,
    PasswordHash NVARCHAR(100) NOT NULL,
    BirthDate DATE NOT NULL,
    AvatarPath NVARCHAR(100) NOT NULL,
);
GO

DROP TRIGGER IF EXISTS Users_UPDATE;
GO

CREATE TRIGGER Users_UPDATE
ON Users
AFTER UPDATE
AS
IF UPDATE(Id)
    BEGIN;
    RAISERROR('Users'' Id cannot be updated', 25, 1);
    ROLLBACK TRANSACTION;
    END;
GO

USE MusicService2;
GO

DROP TABLE IF EXISTS Users;
GO

CREATE TABLE Users
(
    Id INT PRIMARY KEY CHECK (Id >= 4),
    Email NVARCHAR(320) NOT NULL UNIQUE,
    Name NVARCHAR(50) NOT NULL,
    PasswordHash NVARCHAR(100) NOT NULL,
    BirthDate DATE NOT NULL,
    AvatarPath NVARCHAR(100) NOT NULL,
);
GO

DROP TRIGGER IF EXISTS Users_UPDATE;
GO

CREATE TRIGGER Users_UPDATE
ON Users
AFTER UPDATE
AS
IF UPDATE(Id)
    BEGIN;
    RAISERROR('Users'' Id cannot be updated', 25, 1);
    ROLLBACK TRANSACTION;
    END;
GO

-- 3. Создать секционированные представления, обеспечивающие работу с данными таблиц (выборку, вставку, изменение,
-- удаление).
DROP VIEW IF EXISTS AllUsers;
GO

CREATE VIEW AllUsers
AS
SELECT * FROM MusicService1.dbo.Users
UNION ALL
SELECT * FROM MusicService2.dbo.Users;
GO

INSERT INTO AllUsers (Id, Email, Name, PasswordHash, BirthDate, AvatarPath)
VALUES
    (1, 'user1@email.com', 'user1', 'password1', '2024-01-01', 'default_avatar.jpg'),
    (2, 'user2@email.com', 'user2', 'password2', '2024-01-01', 'default_avatar.jpg'),
    (3, 'user3@email.com', 'user3', 'password3', '2024-01-01', 'default_avatar.jpg'),
    (4, 'user4@email.com', 'user4', 'password4', '2024-01-01', 'default_avatar.jpg'),
    (5, 'user5@email.com', 'user5', 'password5', '2024-01-01', 'default_avatar.jpg'),
    (6, 'user6@email.com', 'user6', 'password6', '2024-01-01', 'default_avatar.jpg');
GO

UPDATE AllUsers
SET AvatarPath = 'new_avatar.jpg'
WHERE Id % 2 = 0;
GO

DELETE AllUsers
WHERE Id % 2 = 1;
GO

SELECT * FROM MusicService1.dbo.Users;
GO

SELECT * FROM MusicService2.dbo.Users;
GO

SELECT * FROM AllUsers;
GO
