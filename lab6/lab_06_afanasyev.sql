USE music_service;
GO

DROP TABLE IF EXISTS Compositions;
GO

-- Создание таблицы с автоинкрементным первичным ключом, добавление ограничений
-- и значений по умолчанию с использованием встроенных функций

DROP TABLE IF EXISTS Musicians;
GO

CREATE TABLE Musicians
(
    Id INT PRIMARY KEY IDENTITY,
    Name NVARCHAR(50) NOT NULL CHECK(len(Name) >= 1),
    BirthDate DATE NOT NULL DEFAULT getdate(),
    DeathDate DATE,
    Description NVARCHAR(1000),
    AvatarPath NVARCHAR(100) NOT NULL DEFAULT 'default_avatar.jpg',
);
GO

-- Вставка значений в таблицу

INSERT INTO Musicians (Name, BirthDate, DeathDate, Description)
VALUES
('Musician 1 name', DEFAULT, '2010-01-01', 'Musician 1 description'),
('Musician 2 name', '1950-01-01', NULL, 'Musician 2 description'),
('Musician 3 name', '1940-01-01', '2020-01-01', NULL);

SELECT * FROM Musicians;

-- Получение сгенерированного значения IDENTITY

SELECT SCOPE_IDENTITY();
GO

SELECT @@IDENTITY;
GO

SELECT IDENT_CURRENT('Musicians');
GO

-- Создание таблицы с первичным ключом на основе последовательности

DROP TABLE IF EXISTS Albums;
GO

DROP SEQUENCE IF EXISTS music_service_sequence;
GO

CREATE SEQUENCE music_service_sequence
  START WITH 1
  INCREMENT BY 1;
GO

CREATE TABLE Albums
(
    Id INT PRIMARY KEY DEFAULT (NEXT VALUE FOR music_service_sequence),
    Title NVARCHAR(100) NOT NULL,
    PublicationDate DATE NOT NULL DEFAULT getdate(),
    Description NVARCHAR(1000),
    CoverPath NVARCHAR(100) NOT NULL DEFAULT 'default_cover.jpg'
);
GO

-- Вставка значений в таблицу

INSERT INTO Albums (Title, PublicationDate, Description)
VALUES
('Album 1 title', DEFAULT, 'Album 1 description'),
('Album 2 title', '2020-10-10', NULL);
GO

SELECT * FROM Albums;
GO

-- Создание таблицы с первичным ключом на основе глобального уникального идентификатора

CREATE TABLE Compositions
(
    Id UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL DEFAULT newid(),
    MusicianId INT NOT NULL REFERENCES Musicians(Id),
    AlbumId INT NOT NULL REFERENCES Albums(Id),
    Title NVARCHAR(100) NOT NULL,
    AudioPath NVARCHAR(100) NOT NULL,
    TimesPlayed INT NOT NULL DEFAULT 0,
    UNIQUE(MusicianId, Title)
);
GO

-- Вставка значений в таблицу

INSERT INTO Compositions(MusicianId, AlbumId, Title, AudioPath)
VALUES
(1, 1, 'Composition 1 title', 'composition_1.mp3'),
(3, 1, 'Composition 2 title', 'composition_2.mp3'),
(2, 2, 'Composition 3 title', 'composition_3.mp3'),
(3, 2, 'Composition 4 title', 'composition_4.mp3');
GO

SELECT * FROM Compositions;
GO

-- Тестирование вариантов действий для ограничений ссылочной целостности

ALTER TABLE Compositions
ADD CONSTRAINT FK_Compositions_MusicianId FOREIGN KEY(MusicianId) REFERENCES Musicians(Id)
ON DELETE CASCADE;
GO

ALTER TABLE Compositions
ADD CONSTRAINT FK_Compositions_AlbumId FOREIGN KEY(AlbumId) REFERENCES Albums(Id)
ON DELETE CASCADE;
GO

DELETE FROM Musicians
WHERE Id = 1;
GO

SELECT * FROM Compositions;
GO

ALTER TABLE Compositions
DROP CONSTRAINT FK_Compositions_MusicianId;
GO

ALTER TABLE Compositions
DROP CONSTRAINT FK_Compositions_AlbumId;
GO

 /*
 * При попытке удаления, например, записи Musicians с Id = 2, когда для полей
 * MusicianId, AlbumId таблицы Compositions установлено одно из ограничений
 * ON DELETE SET NULL, ON DELETE SET DEFAULT или ON DELETE NO ACTION, возникает
 * ошибка, поскольку эти поля не NULL.
 */
