-- 1. Создать в базах данных пункта 1 задания 13 связанные таблицы.
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

USE MusicService1;
GO

DROP TABLE IF EXISTS Users;
GO

CREATE TABLE Users
(
    UserId       INT IDENTITY PRIMARY KEY,
    Email        NVARCHAR(320) NOT NULL UNIQUE,
    Name         NVARCHAR(50)  NOT NULL,
    PasswordHash NVARCHAR(100) NOT NULL,
    BirthDate    DATE          NOT NULL,
    AvatarPath   NVARCHAR(100) NOT NULL,
);
GO

DROP TRIGGER IF EXISTS Users_UPDATE;
GO

CREATE TRIGGER Users_UPDATE
    ON Users
    AFTER UPDATE
    AS
    IF UPDATE(UserId)
        THROW 51000, 'User id is immutable', 1;
GO

DROP TRIGGER IF EXISTS Users_DELETE;
GO

CREATE TRIGGER Users_DELETE
    ON Users
    AFTER DELETE
    AS
    DELETE
    FROM MusicService2.dbo.Playlists
    WHERE UserId IN (SELECT UserId
                     FROM Deleted);
GO

INSERT INTO Users (Email, Name, PasswordHash, BirthDate, AvatarPath)
VALUES ('user1@email.com', 'user1', 'password1', '1990-01-01', 'default_avatar.jpg'),
       ('user2@email.com', 'user2', 'password2', '1995-05-05', 'user2_avatar.png'),
       ('user3@email.com', 'user3', 'password3', '2000-10-10', 'new_avatar.jpg');
GO

USE MusicService2;
GO

DROP TABLE IF EXISTS Playlists;
GO

CREATE TABLE Playlists
(
    PlaylistId   INT IDENTITY PRIMARY KEY,
    UserId       INT           NOT NULL,
    Title        NVARCHAR(100) NOT NULL,
    CreationDate DATE          NOT NULL,
    Description  NVARCHAR(1000),
    CoverPath    NVARCHAR(100) NOT NULL,
    UNIQUE (UserId, Title)
);
GO

DROP TRIGGER IF EXISTS Playlists_INSERT;
GO

CREATE TRIGGER Playlists_INSERT
    ON Playlists
    AFTER INSERT
    AS
    IF EXISTS (SELECT *
               FROM Inserted
               WHERE UserId NOT IN (SELECT UserId FROM MusicService1.dbo.Users))
        THROW 51001, 'Nonexistent user id', 1;
GO

DROP TRIGGER IF EXISTS Playlists_UPDATE;
GO

CREATE TRIGGER Playlists_UPDATE
    ON Playlists
    AFTER UPDATE
    AS
BEGIN
    IF UPDATE(UserId)
        THROW 51000, 'User id is immutable', 1;

    IF UPDATE(PlaylistId)
        THROW 51002, 'Playlist id is immutable', 1;
END;
GO

INSERT INTO Playlists (UserId, Title, CreationDate, Description, CoverPath)
VALUES (1, 'playlist1', '2015-05-05', NULL, 'default_cover.jpg'),
       (2, 'playlist1', getdate(), 'playlist1 of user2', 'new_cover.jpg'),
       (2, 'playlist2', getdate(), NULL, 'some_cover.jpg');
GO

-- 2. Создать необходимые элементы базы данных (представления, триггеры), обеспечивающие работу с данными связанных
-- таблиц (выборку, вставку, изменение, удаление).

USE master;
GO

DROP VIEW IF EXISTS UsersPlaylists;
GO

CREATE VIEW UsersPlaylists
AS
SELECT U.Email,
       U.Name,
       U.PasswordHash,
       U.BirthDate,
       U.AvatarPath,
       P.Title,
       P.CreationDate,
       P.Description,
       P.CoverPath
FROM MusicService1.dbo.Users U
         INNER JOIN MusicService2.dbo.Playlists P
                    ON U.UserId = P.UserId;
GO

DROP TRIGGER IF EXISTS UsersPlaylists_INSERT;
GO

CREATE TRIGGER UsersPlaylists_INSERT
    ON UsersPlaylists
    INSTEAD OF INSERT
    AS
BEGIN
    INSERT INTO MusicService1.dbo.Users (Email, Name, PasswordHash, BirthDate, AvatarPath)
    SELECT Email, Name, PasswordHash, BirthDate, AvatarPath
    FROM Inserted I
    WHERE NOT EXISTS (SELECT *
                      FROM MusicService1.dbo.Users
                      WHERE Email = I.Email);

    INSERT INTO MusicService2.dbo.Playlists (UserId, Title, CreationDate, Description, CoverPath)
    SELECT U.UserId,
           I.Title,
           I.CreationDate,
           I.Description,
           I.CoverPath
    FROM Inserted I
             INNER JOIN MusicService1.dbo.Users U
                        ON I.Email = U.Email;
END;
GO

DROP TRIGGER IF EXISTS UsersPlaylists_UPDATE;
GO

CREATE TRIGGER UsersPlaylists_UPDATE
    ON UsersPlaylists
    INSTEAD OF UPDATE
    AS
BEGIN
    IF UPDATE(Email) OR
       UPDATE(Name) OR
       UPDATE(PasswordHash) OR
       UPDATE(BirthDate) OR
       UPDATE(AvatarPath)
        THROW 51003, 'User fields are immutable', 1;

    IF UPDATE(Title)
        THROW 51003, 'Title is immutable', 1;

    WITH UpdatedPlaylists AS (SELECT U.UserId,
                                     I.Title,
                                     I.CreationDate,
                                     I.Description,
                                     I.CoverPath
                              FROM Inserted I
                                       INNER JOIN MusicService1.dbo.Users U
                                                  ON I.Email = U.Email)
    UPDATE P
    SET P.CreationDate = UP.CreationDate,
        P.Description  = UP.Description,
        P.CoverPath    = UP.CoverPath
    FROM MusicService2.dbo.Playlists P
             INNER JOIN UpdatedPlaylists UP
                        ON P.UserId = UP.UserId AND
                           P.Title = UP.Title;
END;
GO

DROP TRIGGER IF EXISTS UsersPlaylists_DELETE;
GO

CREATE TRIGGER UsersPlaylists_DELETE
    ON UsersPlaylists
    INSTEAD OF DELETE
    AS
    WITH DeletedPlaylists AS (SELECT U.UserId,
                                     D.Title
                              FROM Deleted D
                                       INNER JOIN MusicService1.dbo.Users U
                                                  ON D.Email = U.Email)
    DELETE
    FROM MusicService2.dbo.Playlists
    WHERE EXISTS (SELECT *
                  FROM DeletedPlaylists DP
                  WHERE MusicService2.dbo.Playlists.UserId = DP.UserId
                    AND MusicService2.dbo.Playlists.Title = DP.Title);
GO

INSERT INTO UsersPlaylists (Email, Name, PasswordHash, BirthDate, AvatarPath, Title, CreationDate, Description,
                            CoverPath)
VALUES ('user3@email.com', 'user3', 'password3', '2000-10-10', 'new_avatar.jpg', 'playlist1', '2020-01-01',
        'playlist1 of user3', 'default_cover.jpg'),
       ('user3@email.com', 'user3', 'password3', '2000-10-10', 'new_avatar.jpg', 'playlist2', '2022-02-02', NULL,
        'new_cover.jpg'),
       ('user4@email.com', 'user4', 'password4', '2005-05-05', 'user4_avatar.jpg', 'playlist1', '2024-01-01',
        'playlist1 of user4', 'some_cover.jpg');
GO

UPDATE UsersPlaylists
SET CoverPath = 'updated_cover.jpg'
WHERE BirthDate > '2000-01-01';
GO

DELETE UsersPlaylists
WHERE BirthDate < '2000-01-01';
GO

SELECT *
FROM UsersPlaylists;
GO