USE master;
GO

DROP DATABASE IF EXISTS music_service;
GO

-- Создание базы данных с настроенным размером файлов

CREATE DATABASE music_service
ON PRIMARY
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
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
  );
GO

-- Создание таблицы

USE music_service;
GO

DROP TABLE IF EXISTS Users;
GO

CREATE TABLE Users (
  Id INT PRIMARY KEY,
  Email NVARCHAR(320) UNIQUE NOT NULL,
  Name NVARCHAR(50) NOT NULL,
  PasswordHash NVARCHAR(100) NOT NULL,
  BirthDate DATE NOT NULL,
  AvatarPath NVARCHAR(100) NOT NULL
);
GO

-- Добавление файловой группы и файла данных

ALTER DATABASE music_service
ADD FILEGROUP music_service_filegroup;
GO

ALTER DATABASE music_service
ADD FILE
(
  NAME = music_service_filegroup_data,
  FILENAME = '/var/opt/mssql/data/music_service_filegroup_data.mdf',
  SIZE = 5MB,
  MAXSIZE = 100MB,
  FILEGROWTH = 5MB
)
TO FILEGROUP music_service_filegroup;
GO

-- Назначение созданной файловой группы файловой группой по умолчанию

ALTER DATABASE music_service
MODIFY FILEGROUP music_service_filegroup DEFAULT;
GO

-- Создание второй таблицы

CREATE TABLE Musicians (
  Id INT PRIMARY KEY,
  Name NVARCHAR(50) UNIQUE NOT NULL,
  BirthDate DATE NOT NULL,
  DeathDate DATE,
  Description NVARCHAR(1000),
  AvatarPath NVARCHAR(100) NOT NULL
);
GO

-- Удаление созданной файловой группы

ALTER DATABASE music_service
MODIFY FILEGROUP [PRIMARY] DEFAULT;
GO

DROP TABLE IF EXISTS Musicians;
GO

ALTER DATABASE music_service
REMOVE FILE music_service_filegroup_data;
GO

ALTER DATABASE music_service
REMOVE FILEGROUP music_service_filegroup;
GO

-- Создание схемы, переменещение в неё таблицы, удаление схемы.

CREATE SCHEMA music_service_schema;
GO

ALTER SCHEMA music_service_schema
TRANSFER dbo.Users;
GO

DROP TABLE music_service_schema.Users;
GO

DROP SCHEMA music_service_schema;
GO
