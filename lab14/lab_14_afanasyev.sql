-- 1. Создать в базах данных пункта 1 задания 13 таблицы, содержащие вертикально фрагментированные данные.

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

DROP TABLE IF EXISTS MusicService1.dbo.Users;
GO

CREATE TABLE MusicService1.dbo.Users
(
    Id INT PRIMARY KEY,
    Email NVARCHAR(320) NOT NULL UNIQUE,
    Name NVARCHAR(50) NOT NULL,
    PasswordHash NVARCHAR(100) NOT NULL,
);
GO

DROP TABLE IF EXISTS MusicService2.dbo.Users;
GO

CREATE TABLE MusicService2.dbo.Users
(
    Id INT PRIMARY KEY,
    BirthDate DATE NOT NULL,
    AvatarPath NVARCHAR(100) NOT NULL,
);
GO

-- 2. Создать необходимые элементы базы данных (представления, триггеры), обеспечивающие работу с данными вертикально
-- фрагментированных таблиц (выборку, вставку, изменение, удаление).

DROP VIEW IF EXISTS Users;
GO

CREATE VIEW Users
AS
SELECT
    U1.Id,
    U1.Email,
    U1.Name,
    U1.PasswordHash,
    U2.BirthDate,
    U2.AvatarPath
FROM
    MusicService1.dbo.Users U1
INNER JOIN
    MusicService2.dbo.Users U2
ON U1.Id = U2.Id;
GO

DROP TRIGGER IF EXISTS Users_INSERT;
GO

CREATE TRIGGER Users_INSERT
ON Users
INSTEAD OF INSERT
AS
BEGIN;
    INSERT INTO MusicService1.dbo.Users (Id, Email, Name, PasswordHash)
    SELECT Id, Email, Name, PasswordHash
    FROM Inserted;

    INSERT INTO MusicService2.dbo.Users (Id, BirthDate, AvatarPath)
    SELECT Id, BirthDate, AvatarPath
    FROM Inserted;
END;
GO

DROP TRIGGER IF EXISTS Users_UPDATE;
GO

CREATE TRIGGER Users_UPDATE
ON Users
INSTEAD OF UPDATE
AS
BEGIN;
    IF UPDATE(Id)
        THROW 51000, 'User id is immutable', 1;

    UPDATE U1
    SET U1.Email = I.Email,
        U1.Name = I.Name,
        U1.PasswordHash = I.PasswordHash
    FROM MusicService1.dbo.Users U1
    INNER JOIN Inserted I
    ON U1.Id = I.Id;

    UPDATE U2
    SET U2.BirthDate = I.BirthDate,
        U2.AvatarPath = I.AvatarPath
    FROM MusicService2.dbo.Users U2
    INNER JOIN Inserted I
    ON U2.Id = I.Id;
END;
GO

DROP TRIGGER IF EXISTS Users_DELETE;
GO

CREATE TRIGGER Users_DELETE
ON Users
INSTEAD OF DELETE
AS
BEGIN;
    DELETE FROM MusicService1.dbo.Users
    WHERE Id IN (
        SELECT Id
        FROM Deleted
    );

    DELETE FROM MusicService2.dbo.Users
    WHERE Id IN (
        SELECT Id
        FROM Deleted
    );
END;
GO

INSERT INTO Users (Id, Email, Name, PasswordHash, AvatarPath, BirthDate)
VALUES
    (1, 'user1@email.com', 'user1', 'password1', 'default_avatar.jpg', '2000-01-01'),
    (2, 'user2@email.com', 'user2', 'password2', 'default_avatar.jpg', '2000-01-01'),
    (3, 'user3@email.com', 'user3', 'password3', 'default_avatar.jpg', '2000-01-01'),
    (4, 'user4@email.com', 'user4', 'password4', 'default_avatar.jpg', '2000-01-01');
GO

UPDATE Users
SET AvatarPath = 'new_avatar'
WHERE Id % 2 = 0;
GO

UPDATE Users
SET PasswordHash = 'some password'
WHERE Id % 2 = 1;
GO

DELETE FROM Users
WHERE Id BETWEEN 2 AND 3;
GO

SELECT * FROM Users;
GO