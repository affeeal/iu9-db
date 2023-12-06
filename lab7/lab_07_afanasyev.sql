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
    Id INT PRIMARY KEY IDENTITY,
    Email NVARCHAR(320) UNIQUE NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    PasswordHash NVARCHAR(100) NOT NULL,
    BirthDate DATE NOT NULL,
    AvatarPath NVARCHAR(100) NOT NULL DEFAULT 'default_avatar.jpg'
);
GO

INSERT INTO Users (Email, Name, PasswordHash, BirthDate)
VALUES
('email1@example.com', 'Name 1', 'Password hash', '1990-01-01'),
('email2@example.com', 'Name 2', 'Password hash', '2000-01-01');
GO

SELECT * FROM Users;
GO

CREATE TABLE Playlists
(
    Id INT PRIMARY KEY IDENTITY,
    UserId INT NOT NULL REFERENCES Users(Id),
    Title NVARCHAR(100) NOT NULL,
    CreationDate DATE NOT NULL DEFAULT getdate(),
    Description NVARCHAR(1000) NULL,
    CoverPath NVARCHAR(100) NOT NULL DEFAULT 'default_cover.jpg',
    UNIQUE(UserId, Title)
);
GO

INSERT INTO Playlists (UserId, Title, Description)
VALUES
(1, 'Title 1', 'Description'),
(1, 'Title 2', 'Description'),
(2, 'Title 3', 'Description');
GO

SELECT * FROM Playlists;
GO

-- Создание представления на основе таблицы Users

DROP VIEW IF EXISTS UsersAvatars;
GO

CREATE VIEW UsersAvatars
AS SELECT Name, AvatarPath
FROM Users;
GO

SELECT * FROM UsersAvatars;
GO

-- Создание представления на основе полей связанных таблиц Users и Playlists

CREATE VIEW UsersPlaylists
WITH SCHEMABINDING
AS SELECT U.Name, U.AvatarPath, P.Title, P.CoverPath
FROM dbo.Users AS U
JOIN dbo.Playlists AS P ON U.Id = P.UserId;
GO

SELECT * FROM UsersPlaylists;
GO

-- Создание индекса для таблицы Users с дополнительными неключевыми полями

DROP INDEX IF EXISTS IX_Users_Email ON Users;
GO

CREATE NONCLUSTERED INDEX IX_Users_Email
ON Users (Email)
INCLUDE (BirthDate, PasswordHash);
GO

-- Создание индексированного представления для UsersPlaylists

DROP INDEX IF EXISTS IX_UsersPlaylists_Name_Title ON UsersPlaylists;
GO

CREATE UNIQUE CLUSTERED INDEX IX_UsersPlaylists_Name_Title
ON UsersPlaylists (Name, Title);
GO
