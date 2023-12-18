USE music_service;
GO

DROP VIEW IF EXISTS UsersPlaylists;
GO

DROP TABLE IF EXISTS Playlists;
GO

-- 1. Для одной из таблиц пункта 2 задания 7 создать триггеры на вставку, удаление и добавление, при выполнении заданных
-- условий один из триггеров должен инициировать возникновение ошибки (RAISERROR / THROW).

DROP TABLE IF EXISTS Users;
GO

CREATE TABLE Users
(
    Id INT IDENTITY PRIMARY KEY,
    DocumentId NVARCHAR(50) NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    BirthDate DATE NOT NULL DEFAULT dateadd(year, -18, getdate()),
    AvatarPath NVARCHAR(100) NOT NULL DEFAULT 'default_avatar.jpg',
    DeletedAt DATETIME,
    UNIQUE (DocumentId, DeletedAt)
);
GO

DROP TRIGGER IF EXISTS Users_INSERT_UPDATE;
GO

CREATE TRIGGER Users_INSERT_UPDATE
ON Users
AFTER INSERT, UPDATE
AS
UPDATE Users
SET DocumentId = upper(DocumentId)
WHERE Id IN (SELECT Id FROM Inserted);
GO

-- При добавлении пользователя DocumentId переводится в верхний регистр
INSERT INTO Users (DocumentId, Name)
VALUES
('aaa-0000', 'name_1'),
('BBB-0000', 'name_2'),
('Ccc-0000', 'name_3');
GO

SELECT * FROM Users;
GO

-- При обновлении пользователя DocumentId переводится в верхний регистр
UPDATE Users
SET DocumentId = 'ccc-0001'
WHERE Id = 3;
GO

SELECT * FROM Users;
GO

DROP TRIGGER IF EXISTS Users_DELETE;
GO

CREATE TRIGGER Users_DELETE
ON Users
INSTEAD OF DELETE
AS
IF EXISTS (
    SELECT 1
    FROM Deleted
    WHERE DeletedAt IS NOT NULL
)
    RAISERROR('Found already deleted user in the query', 5, 1);
ELSE
    UPDATE Users
    SET DeletedAt = getdate()
    WHERE Id in (SELECT Id FROM Deleted);
GO

-- Soft-удаление пользователя
DELETE FROM Users
WHERE Id = 3;
GO

SELECT * FROM Users;
GO

-- Если среди удаляемых записей есть уже удалённая, soft-delete не происходит
DELETE FROM Users
WHERE Id IN (2, 3);
GO

SELECT * FROM Users;
GO

-- 2. Для представления пункта 2 задания 7 создать триггеры на вставку, удаление и добавление, обеспечивающие
-- возможность выполнения операций с данными непосредственно через представление.

CREATE TABLE Playlists
(
    Id INT IDENTITY PRIMARY KEY,
    UserId INT NOT NULL REFERENCES Users(Id),
    Title NVARCHAR(100) NOT NULL,
    CreationDate DATE NOT NULL DEFAULT getdate(),
    Description NVARCHAR(1000),
    CoverPath NVARCHAR(100) NOT NULL DEFAULT 'default_cover.jpg',
    UNIQUE(UserId, Title)
);
GO

INSERT INTO Playlists (UserId, Title, Description)
VALUES
(1, 'title_1', 'description'),
(1, 'title_2', 'description'),
(2, 'title_1', 'description');
GO

SELECT * FROM Playlists;
GO

CREATE VIEW UsersPlaylists
WITH SCHEMABINDING
AS
SELECT
    U.DocumentId,
    U.Name,
    P.Title,
    P.Description
FROM dbo.Users AS U
INNER JOIN dbo.Playlists AS P
ON U.Id = P.UserId
WHERE DeletedAt IS NULL;
GO

SELECT * FROM UsersPlaylists;
GO

DROP TRIGGER IF EXISTS UsersPlaylists_INSERT;
GO

CREATE TRIGGER UsersPlaylists_INSERT
ON UsersPlaylists
INSTEAD OF INSERT
AS
BEGIN;
    INSERT INTO Users (DocumentId, Name)
    SELECT DISTINCT
        I.DocumentId,
        I.Name
    FROM Inserted AS I
    WHERE NOT EXISTS (
        SELECT U.DocumentId
        FROM Users AS U
        WHERE I.DocumentId = U.DocumentId
    );

    INSERT INTO Playlists (UserId, Title, Description)
    SELECT
        U.Id,
        I.Title,
        I.Description
    FROM Inserted AS I
    INNER JOIN Users AS U
    ON I.DocumentId = U.DocumentId
END;
GO

-- Добавление плейлистов новых и существующих пользователей
INSERT INTO UsersPlaylists (DocumentId, Name, Title)
VALUES
('bbb-0000', 'name_2', 'title_2'),
('ddd-0000', 'name_4', 'title_1'),
('ddd-0000', 'name_4', 'title_2'),
('eee-0000', 'name_5', 'title_1');
GO

SELECT * FROM UsersPlaylists;
GO

DROP TRIGGER IF EXISTS UsersPlaylists_UPDATE;
GO

CREATE TRIGGER UsersPlaylists_UPDATE
ON UsersPlaylists
INSTEAD OF UPDATE
AS
BEGIN;
    IF (COLUMNS_UPDATED() & 3 != 0)
    BEGIN;
        RAISERROR('Playlist user information cannot be updated', 5, 1);
        RETURN;
    END;

    IF UPDATE(Title)
    BEGIN;
        RAISERROR('Title is a part of the primary key and cannot be updated', 5, 1);
        RETURN;
    END;

    WITH InsertedUsers AS (
        SELECT
            U.Id,
            I.Title,
            I.Description
        FROM Inserted AS I
        INNER JOIN Users AS U
        ON I.DocumentId = U.DocumentId
    )
    UPDATE P
    SET P.Description = IU.Description
    FROM Playlists AS P
    INNER JOIN InsertedUsers AS IU
    ON P.UserId = IU.Id AND
       P.Title = IU.Title;
END;
GO

-- Обновление неключевого атрибута Playlists
UPDATE UsersPlaylists
SET Description = 'please, enter a description'
WHERE Description IS NULL;
GO

SELECT * FROM UsersPlaylists;
GO

DROP TRIGGER IF EXISTS UsersPlaylists_DELETE;
GO
CREATE TRIGGER UsersPlaylists_DELETE
ON UsersPlaylists
INSTEAD OF DELETE
AS
BEGIN;
    WITH DeletedUsers AS (
        SELECT U.Id, D.Title
        FROM Deleted AS D
        INNER JOIN Users AS U
        ON D.DocumentId = U.DocumentId
    )
    DELETE FROM Playlists
    WHERE EXISTS (
        SELECT * FROM DeletedUsers AS DU
        WHERE Playlists.UserId = DU.Id AND
              Playlists.Title = DU.Title
    );
END;
GO

-- Удаление по имени пользователя.
-- При удалении всех плейлистов пользователя сам пользователь не удаляется.
DELETE FROM UsersPlaylists
WHERE Name = 'name_2';
GO

SELECT * FROM UsersPlaylists;
GO

-- Удаление по имени плейлиста.
DELETE FROM UsersPlaylists
WHERE Title = 'title_2';
GO

SELECT * FROM UsersPlaylists;
GO
