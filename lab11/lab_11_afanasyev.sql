USE master;
GO

/*
1. Создать базу данных, спроектированную в рамках лабораторной работы №4, используя изученные в лабораторных работах
5-10 средства SQL Server 2012:
- поддержания создания и физической организации базы данных;
- различных категорий целостности;
- представления и индексы;
- хранимые процедуры, функции и триггеры;

2. Создание объектов базы данных должно осуществляться средствами DDL (CREATE/ALTER/DROP), в обязательном порядке
иллюстрирующих следующие аспекты:
- добавление и изменение полей;
- назначение типов данных;
- назначение ограничений целостности (PRIMARY KEY, NULL/NOT NULL/UNIQUE, CHECK и т.п.);
- определение значений по умолчанию;
*/

DROP DATABASE IF EXISTS music_service;
GO

CREATE DATABASE music_service
    ON
    (
        NAME = music_service_data,
        FILENAME = '/var/opt/mssql/data/music_service_data.mdf',
        SIZE = 5MB,
        MAXSIZE = 100MB,
        FILEGROWTH = 5MB
    )
    LOG ON
    (
        NAME = music_service_log,
        FILENAME = '/var/opt/mssql/data/music_service_log.ldf',
        SIZE = 5MB,
        MAXSIZE = 50MB,
        FILEGROWTH = 5MB
    );
GO

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

DROP TABLE IF EXISTS Playlists;
GO

CREATE TABLE Playlists
(
    Id INT IDENTITY PRIMARY KEY,
    UserId INT NOT NULL REFERENCES Users(Id) ON DELETE CASCADE,
    Title NVARCHAR(100) NOT NULL,
    CreationDate DATE NOT NULL DEFAULT getdate(),
    Description NVARCHAR(1000),
    CoverPath NVARCHAR(100) NOT NULL DEFAULT 'default_cover.jpg',
    UNIQUE (UserId, Title)
);
GO

DROP TRIGGER IF EXISTS Playlists_UPDATE;
GO

CREATE TRIGGER Playlists_UPDATE
ON Playlists
AFTER UPDATE
AS
IF UPDATE(UserId)
BEGIN;
    RAISERROR('Playlist''s UserId is immutable', 5, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END;
GO

DROP TABLE IF EXISTS Albums;
GO

CREATE TABLE Albums
(
    Id INT IDENTITY PRIMARY KEY,
    Title NVARCHAR(100) NOT NULL UNIQUE,
    PublicationDate DATE NOT NULL DEFAULT getdate(),
    Description NVARCHAR(1000),
    CoverPath NVARCHAR(100) NOT NULL DEFAULT 'default_cover.jpg'
);
GO

DROP TABLE IF EXISTS Musicians;
GO

CREATE TABLE Musicians
(
    Id INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL UNIQUE,
    BirthDate DATE NOT NULL,
    DeathDate DATE,
    Description NVARCHAR(1000),
    AvatarPath NVARCHAR(100) NOT NULL DEFAULT 'default_avatar.jpg'
);
GO

DROP TABLE IF EXISTS Compositions;
GO

CREATE TABLE Compositions
(
    Id INT IDENTITY PRIMARY KEY,
    MusicianId INT NOT NULL REFERENCES Musicians(Id) ON DELETE CASCADE,
    Title NVARCHAR(100) NOT NULL,
    AlbumId INT NOT NULL REFERENCES Albums(Id) ON DELETE CASCADE,
    AudioPath NVARCHAR(100) NOT NULL,
    DurationSeconds INT NOT NULL,
    TimesPlayed INT NOT NULL DEFAULT 0
);
GO

DROP TRIGGER IF EXISTS Compositions_UPDATE;
GO

CREATE TRIGGER Compositions_UPDATE
ON Compositions
AFTER UPDATE
AS
BEGIN;
    IF UPDATE(AlbumId)
    BEGIN;
        RAISERROR('Composition''s AlbumId is immutable', 5, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF UPDATE(MusicianId)
    BEGIN;
        RAISERROR('Composition''s MusicianId is immutable', 5, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

DROP TRIGGER IF EXISTS Compositions_DELETE;
GO

CREATE TRIGGER Compositions_DELETE
ON Compositions
AFTER DELETE
AS
DELETE Albums
WHERE Id IN (
    SELECT DISTINCT AlbumId
    FROM Deleted D
    WHERE NOT EXISTS (
        SELECT 1
        FROM Compositions C
        WHERE C.AlbumId = D.AlbumId
    )
);
GO

DROP VIEW IF EXISTS AlbumsMusiciansCompositions;
GO

CREATE VIEW AlbumsMusiciansCompositions
AS
SELECT
    A.Title AS AlbumTitle,
    A.PublicationDate AS AlbumPublicationDate,
    A.Description AS AlbumDescription,
    A.CoverPath AS AlbumCoverPath,
    M.Name AS MusicianName,
    M.BirthDate AS MusicianBirthDate,
    M.DeathDate AS MusicianDeathDate,
    M.Description AS MusicianDescription,
    M.AvatarPath AS MusicianAvatarPath,
    C.Title AS CompositionTitle,
    C.AudioPath AS CompositionAudioPath,
    C.DurationSeconds AS CompositionDurationSeconds,
    C.TimesPlayed AS CompositionTimesPlayed
FROM Compositions C
INNER JOIN Albums A
ON C.AlbumId = A.Id
INNER JOIN Musicians M
ON C.MusicianId = M.Id
GO

DROP TRIGGER IF EXISTS AlbumsMusiciansCompositions_INSERT;
GO

CREATE TRIGGER AlbumsMusiciansCompositions_INSERT
ON AlbumsMusiciansCompositions
INSTEAD OF INSERT
AS
BEGIN;
INSERT INTO Albums (Title, PublicationDate, Description, CoverPath)
    SELECT DISTINCT
        I.AlbumTitle,
        I.AlbumPublicationDate,
        I.AlbumDescription,
        I.AlbumCoverPath
    FROM Inserted I
    WHERE NOT EXISTS (
        SELECT Title
        FROM Albums A
        WHERE A.Title = I.AlbumTitle
    );

    INSERT INTO Musicians (Name, BirthDate, DeathDate, Description, AvatarPath)
    SELECT DISTINCT
        I.MusicianName,
        I.MusicianBirthDate,
        I.MusicianDeathDate,
        I.MusicianDescription,
        I.MusicianAvatarPath
    FROM Inserted AS I
    WHERE NOT EXISTS (
        SELECT Name
        FROM Musicians M
        WHERE M.Name = I.MusicianName
    );

    INSERT INTO Compositions (MusicianId, Title, AlbumId, AudioPath, DurationSeconds, TimesPlayed)
    SELECT
        M.Id,
        I.CompositionTitle,
        A.Id,
        I.CompositionAudioPath,
        I.CompositionDurationSeconds,
        I.CompositionTimesPlayed
    FROM Inserted I
    INNER JOIN Albums A
    ON I.AlbumTitle = A.Title
    INNER JOIN Musicians M
    ON I.MusicianName = M.Name
END;
GO

DROP TRIGGER IF EXISTS AlbumsMusiciansCompositions_UPDATE;
GO

CREATE TRIGGER AlbumsMusiciansCompositions_UPDATE
ON AlbumsMusiciansCompositions
INSTEAD OF UPDATE
AS
BEGIN;
    IF UPDATE(AlbumTitle) OR
       UPDATE(AlbumPublicationDate) OR
       UPDATE(AlbumDescription) OR
       UPDATE(AlbumCoverPath)
    BEGIN;
        RAISERROR('Album fields are immutable throughout the view', 5, 1);
        RETURN;
    END;

    IF UPDATE(MusicianName) OR
       UPDATE(MusicianBirthDate) OR
       UPDATE(MusicianDeathDate) OR
       UPDATE(MusicianDescription) OR
       UPDATE(MusicianAvatarPath)
    BEGIN;
        RAISERROR('Musician fields are immutable throughout the view', 5, 1);
        RETURN;
    END;

    IF UPDATE(CompositionTitle)
    BEGIN;
        RAISERROR('CompositionTitle field is immutable throughout the view', 5, 1);
        RETURN;
    END;

    WITH InsertedAlbumsMusicians AS (
        SELECT
            A.Id AS AlbumId,
            M.Id AS MusicianId,
            I.CompositionTitle,
            I.CompositionAudioPath,
            I.CompositionDurationSeconds,
            I.CompositionTimesPlayed
        FROM Inserted I
        INNER JOIN Albums A
        ON I.AlbumTitle = A.Title
        INNER JOIN Musicians M
        ON I.MusicianName = M.Name
    )
    UPDATE C
    SET AudioPath = IAM.CompositionAudioPath,
        DurationSeconds = IAM.CompositionDurationSeconds,
        TimesPlayed = IAM.CompositionTimesPlayed
    FROM Compositions C
    INNER JOIN InsertedAlbumsMusicians IAM
    ON C.AlbumId = IAM.AlbumId AND
       C.MusicianId = IAM.MusicianId AND
       C.Title = IAM.CompositionTitle;
END;
GO

DROP TRIGGER IF EXISTS AlbumsMusiciansCompositions_DELETE;
GO

CREATE TRIGGER AlbumsMusiciansCompositions_DELETE
ON AlbumsMusiciansCompositions
INSTEAD OF DELETE
AS
BEGIN;
    WITH DeletedCompositions AS (
        SELECT
            A.Id AS AlbumId,
            M.Id AS MusicianId,
            D.CompositionTitle
        FROM Deleted D
        INNER JOIN Albums A
        ON D.AlbumTitle = A.Title
        INNER JOIN Musicians M
        ON D.MusicianName = M.Name
    )
    DELETE FROM Compositions
    WHERE EXISTS (
        SELECT * FROM DeletedCompositions DC
        WHERE Compositions.AlbumId = DC.AlbumId AND
              Compositions.MusicianId = DC.MusicianId AND
              Compositions.Title = DC.CompositionTitle
    )
END;
GO

DROP TABLE IF EXISTS PlaylistsCompositions;
GO

CREATE TABLE PlaylistsCompositions
(
    CompositionId INT NOT NULL REFERENCES Compositions(Id) ON DELETE CASCADE,
    PlaylistId INT NOT NULL REFERENCES Playlists(Id) ON DELETE CASCADE,
    PRIMARY KEY (CompositionId, PlaylistId)
);
GO

DROP TRIGGER IF EXISTS PlaylistsCompositions_UPDATE;
GO

CREATE TRIGGER PlaylistsCompositions_UPDATE
ON PlaylistsCompositions
AFTER UPDATE
AS
BEGIN;
    IF UPDATE(PlaylistId)
    BEGIN;
        RAISERROR('PlaylistsCompositions'' PlaylistId cannot be updated', 5, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF UPDATE(CompositionId)
    BEGIN;
        RAISERROR('PlaylistsCompositions'' CompositionId cannot be updated', 5, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

DROP FUNCTION IF EXISTS GetAlbumDuration;
GO

CREATE FUNCTION GetAlbumDuration(@AlbumTitle NVARCHAR(100))
RETURNS INT AS
BEGIN
    DECLARE @Result INT = 0;

    SELECT @Result = SUM(DurationSeconds)
    FROM Compositions C
    INNER JOIN Albums A
    ON C.AlbumId = A.Id
    WHERE A.Title = @AlbumTitle

    RETURN @Result;
END;
GO

/*
3. В рассматриваемой базе данных должны быть тем или иным образом (в рамках объектов базы данных или дополнительно)
созданы запросы DML для:
- выборки записей (команда SELECT);
- добавления новых записей (команда INSERT), как с помощью непосредственного указания значений, так и с помощью команды
SELECT;
- модификации записей (команда UPDATE);
- удаления записей (команда DELETE);
*/

INSERT INTO Users (Email, Name, PasswordHash)
VALUES
    ('user1@gmail.com', 'user1', 'password hash'),
    ('user2@gmail.com', 'user2', 'password hash'),
    ('user3@gmail.com', 'user3', 'password hash');
GO

INSERT INTO Playlists (UserId, Title)
VALUES
    (1, 'playlist 1 of user1'),
    (1, 'playlist 2 of user1'),
    (2, 'playlist 1 of user2');
GO

-- Вставка композиции нового музыканта в новый альбом
INSERT INTO AlbumsMusiciansCompositions (
    AlbumTitle,
    AlbumPublicationDate,
    AlbumDescription,
    AlbumCoverPath,
    MusicianName,
    MusicianBirthDate,
    MusicianDeathDate,
    MusicianDescription,
    MusicianAvatarPath,
    CompositionTitle,
    CompositionAudioPath,
    CompositionDurationSeconds,
    CompositionTimesPlayed
)
VALUES
    (
        'album1',
        '2000-01-01',
        'album1 description',
        'default_cover.jpg',
        'musician1',
        '1960-01-01',
        '2020-01-01',
        'musician1 description',
        'musician1_avatar.jpg',
        'composition1',
        'album1_composition1.mp3',
        180,
        0
    );
GO

-- Вставка композиции нового музыканта в существующий альбом
INSERT INTO AlbumsMusiciansCompositions (
    AlbumTitle,
    MusicianName,
    MusicianBirthDate,
    MusicianDeathDate,
    MusicianDescription,
    MusicianAvatarPath,
    CompositionTitle,
    CompositionAudioPath,
    CompositionDurationSeconds,
    CompositionTimesPlayed
)
VALUES
    (
        'album1',
        'musician2',
        '1980-01-01',
        NULL,
        'musician2 description',
        'default_avatar.jpg',
        'composition2',
        'album1_composition2.mp3',
        150,
        10
    );
GO

-- Вставка композиции существующего музыканта в новый альбом
INSERT INTO AlbumsMusiciansCompositions (
    AlbumTitle,
    AlbumPublicationDate,
    AlbumDescription,
    AlbumCoverPath,
    MusicianName,
    CompositionTitle,
    CompositionAudioPath,
    CompositionDurationSeconds,
    CompositionTimesPlayed
)
VALUES
    (
        'album2',
        '1990-01-01',
        NULL,
        'album2_cover.jpg',
        'musician1',
        'composition1',
        'album2_composition1.mp3',
        120,
        5
    );
GO

-- Вставка композиции существующего музыканта в существующий альбом
INSERT INTO AlbumsMusiciansCompositions (
    AlbumTitle,
    MusicianName,
    CompositionTitle,
    CompositionAudioPath,
    CompositionDurationSeconds,
    CompositionTimesPlayed
)
VALUES
    (
        'album2',
        'musician2',
        'composition2',
        'album2_composition2.mp3',
        140,
        15
    );
GO

INSERT INTO PlaylistsCompositions (CompositionId, PlaylistId)
VALUES
    (1, 1),
    (2, 1),
    (3, 1),
    (4, 2);
GO

-- Обновление неключевого атрибута Compositions
UPDATE AlbumsMusiciansCompositions
SET CompositionTimesPlayed = CompositionTimesPlayed + 5
WHERE AlbumTitle = 'album2';
GO

-- 4. Запросы, созданные в рамках пп.2,3 должны иллюстрировать следующие возможности языка:

-- удаление повторяющихся записей (DISTINCT);

SELECT COUNT(DISTINCT AlbumTitle)
FROM AlbumsMusiciansCompositions;
GO

-- выбор, упорядочивание и именование полей (создание псевдонимов для полей и таблиц / представлений);

SELECT
    Title AS AlbumTitle,
    dbo.GetAlbumDuration(Title) AS AlbumDuration,
    Description AS AlbumDescription
FROM Albums;
GO

-- соединение таблиц (INNER JOIN / LEFT JOIN / RIGHT JOIN / FULL OUTER JOIN);

SELECT PC.CompositionId, P.Title
FROM PlaylistsCompositions PC
RIGHT JOIN Playlists P
ON PC.PlaylistId = P.Id;
GO

-- условия выбора записей (в том числе, условия / LIKE / BETWEEN / IN / EXISTS);

-- альбомы с префиксом album:
SELECT AlbumTitle
FROM AlbumsMusiciansCompositions
WHERE AlbumTitle LIKE 'album%';
GO

-- композиции продолжительностью от 140 до 150 секунд:
SELECT CompositionTitle
FROM AlbumsMusiciansCompositions
WHERE CompositionDurationSeconds BETWEEN 140 AND 150;
GO

-- непустые плейлисты:
SELECT Title
FROM Playlists
WHERE Id IN (
    SELECT DISTINCT PlaylistId
    FROM PlaylistsCompositions
);
GO

-- пользователи без плейлистов:
SELECT Name
FROM Users U
WHERE NOT EXISTS (
    SELECT 1
    FROM Playlists P
    WHERE U.Id = P.UserId
);
GO

-- сортировка записей (ORDER BY - ASC, DESC);

-- альбомы по лексикографическому убыванию названия:
SELECT * FROM AlbumsMusiciansCompositions
ORDER BY AlbumTitle DESC;
GO

-- группировка записей (GROUP BY + HAVING, использование функций агрегирования COUNT / AVG / SUM / MIN / MAX);

-- плейлисты с числом композиций в возрастающем порядке:
SELECT
    UserId,
    Title,
    COUNT(PC.CompositionId) AS CompositionsCount
FROM Playlists
LEFT JOIN PlaylistsCompositions PC
ON Id = PlaylistId
GROUP BY UserId, Title
ORDER BY CompositionsCount;
GO

-- альбомы со средней продолжительностью композиции более 150 секунд:
SELECT
    AlbumTitle,
    AVG(CompositionDurationSeconds) AS AlbumAverageDuration
FROM AlbumsMusiciansCompositions
GROUP BY AlbumTitle
HAVING AVG(CompositionDurationSeconds) >= 150;
GO

-- объединение результатов нескольких запросов (UNION / UNION ALL / EXCEPT / INTERSECT);

SELECT AlbumTitle
FROM AlbumsMusiciansCompositions
WHERE AlbumDescription IS NULL
UNION
SELECT AlbumTitle
FROM AlbumsMusiciansCompositions
WHERE AlbumCoverPath = 'default_cover.jpg';
GO

-- без удаления повторяющихся записей:
SELECT AlbumTitle
FROM AlbumsMusiciansCompositions
WHERE AlbumDescription IS NULL
UNION ALL
SELECT AlbumTitle
FROM AlbumsMusiciansCompositions
WHERE AlbumCoverPath = 'default_cover.jpg';
GO

-- пересечение пусто:
SELECT AlbumTitle
FROM AlbumsMusiciansCompositions
WHERE AlbumDescription IS NULL
INTERSECT
SELECT AlbumTitle
FROM AlbumsMusiciansCompositions
WHERE AlbumCoverPath = 'default_cover.jpg';
GO

-- результаты первой выборки без результатов второй:
SELECT AlbumTitle
FROM AlbumsMusiciansCompositions
WHERE AlbumDescription IS NULL
EXCEPT
SELECT AlbumTitle
FROM AlbumsMusiciansCompositions
WHERE AlbumCoverPath = 'default_cover.jpg';
GO

-- Удаление композиций в разных альбомах
DELETE FROM AlbumsMusiciansCompositions
WHERE CompositionDurationSeconds BETWEEN 140 AND 150;
GO

-- При удалении последней композиции альбома удаляется и сам альбом
DELETE FROM AlbumsMusiciansCompositions
WHERE CompositionAudioPath = 'album2_composition1.mp3';
GO
