USE music_service;
GO

DROP TABLE IF EXISTS Users;
GO

CREATE TABLE Users
(
    Id INT IDENTITY PRIMARY KEY,
    Email NVARCHAR(320) NOT NULL UNIQUE,
    Name NVARCHAR(50) NOT NULL,
    PasswordHash NVARCHAR(100) NOT NULL,
    BirthDate DATE NOT NULL DEFAULT dateadd(year, -18, getdate()),
    AvatarPath NVARCHAR(100) NOT NULL DEFAULT 'default_avatar.jpg',
);
GO

INSERT INTO Users (Email, Name, PasswordHash)
VALUES
    ('user1@gmail.com', 'user1', 'hash'),
    ('user2@gmail.com', 'user2', 'hash');
GO

SELECT * FROM Users;
GO