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
    RegisteredAt DATETIME NOT NULL DEFAULT getdate(),
);
GO

INSERT INTO Users (Email, Name, PasswordHash, BirthDate, RegisteredAt)
VALUES
('user1@example.com', 'user1', 'password hash', '2010-01-01', datediff(day, 8, getdate())),
('user2@example.com', 'user2', 'password hash', '2000-01-01', datediff(day, 24, getdate())),
('user3@example.com', 'user3', 'password hash', '2008-01-01', datediff(day, 5, getdate())),
('user4@example.com', 'user4', 'password hash', '1995-01-01', datediff(day, 13, getdate())),
('user5@example.com', 'user5', 'password hash', '1998-01-01', datediff(day, 2, getdate()));
GO

SELECT * FROM Users;
GO

-- 1. Создать хранимую процедуру, производящую выборку из некоторой таблицы и
-- возвращающую результат выборки в виде курсора.

DROP PROCEDURE IF EXISTS FillCursorUsers;
GO

CREATE PROCEDURE FillCursorUsers
    @UsersCursor CURSOR VARYING OUTPUT
AS
BEGIN
    SET @UsersCursor =
        CURSOR FORWARD_ONLY STATIC FOR
        SELECT
            Email,
            Name,
            BirthDate,
            RegisteredAt
        FROM Users;
    OPEN @UsersCursor;
END;
GO

DECLARE @UsersCursor CURSOR;
EXECUTE FillCursorUsers @UsersCursor = @UsersCursor OUTPUT;
FETCH NEXT FROM @UsersCursor;
WHILE @@FETCH_STATUS = 0
BEGIN
    FETCH NEXT FROM @UsersCursor;
END;
CLOSE @UsersCursor;
DEALLOCATE @UsersCursor;
GO

-- 2. Модифицировать хранимую процедуру п.1. таким образом, чтобы выборка
-- осуществлялась с формированием столбца, значение которого формируется
-- пользовательской функцией.

DROP FUNCTION IF EXISTS IsAdult;
GO

CREATE FUNCTION IsAdult(@BirthDate DATE)
RETURNS BIT AS
BEGIN
    RETURN IIF((dateadd(year, 18, @BirthDate) < getdate()), 'TRUE', 'FALSE');
END;
GO

DROP PROCEDURE IF EXISTS FillCursorUsersWithIsAdult;
GO

CREATE PROCEDURE FillCursorUsersWithIsAdult
    @UsersCursor CURSOR VARYING OUTPUT
AS
BEGIN
    SET @UsersCursor =
        CURSOR FORWARD_ONLY STATIC FOR
        SELECT
            Email,
            Name,
            BirthDate,
            RegisteredAt,
            dbo.IsAdult(BirthDate) AS IsAdult
        FROM Users;
    OPEN @UsersCursor;
END;
GO

DECLARE @UsersCursor CURSOR;
EXECUTE FillCursorUsersWithIsAdult @UsersCursor = @UsersCursor OUTPUT;
FETCH NEXT FROM @UsersCursor;
WHILE @@FETCH_STATUS = 0
BEGIN
    FETCH NEXT FROM @UsersCursor;
END;
CLOSE @UsersCursor;
DEALLOCATE @UsersCursor;
GO

-- 3. Создать хранимую процедуру, вызывающую процедуру п.1., осуществляющую
-- прокрутку возвращаемого курсора и выводящую сообщения, сформированные из
-- записей при выполнении условия, заданного еще одной пользовательской функцией.

DROP FUNCTION IF EXISTS IsNewUser;
GO

CREATE FUNCTION IsNewUser(@RegisteredAt DATETIME)
RETURNS BIT AS
BEGIN
    RETURN IIF(dateadd(day, 7, @RegisteredAt) >= getdate(), 'TRUE', 'FALSE');
END;
GO
DROP PROCEDURE IF EXISTS PrintNewUsers; GO

CREATE PROCEDURE PrintNewUsers
AS
BEGIN
    DECLARE @Email NVARCHAR(320);
    DECLARE @Name NVARCHAR(50);
    DECLARE @BirthDate DATE;
    DECLARE @RegisteredAt DATETIME;

    DECLARE @UsersCursor CURSOR;
    EXECUTE FillCursorUsers @UsersCursor = @UsersCursor OUTPUT;

    FETCH NEXT FROM @UsersCursor
    INTO @Email, @Name, @BirthDate, @RegisteredAt;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF dbo.IsNewUser(@RegisteredAt) = 'TRUE'
            PRINT 'New user: ' + @Email + ' ' + @Name +' ' +
                CAST(@BirthDate AS VARCHAR) + ' ' + CAST(@RegisteredAt AS VARCHAR);

        FETCH NEXT FROM @UsersCursor
        INTO @Email, @Name, @BirthDate, @RegisteredAt;
    END;

    CLOSE @UsersCursor;
    DEALLOCATE @UsersCursor;
END;
GO

EXECUTE PrintNewUsers;
GO

-- 4. Модифицировать хранимую процедуру п.2. таким образом, чтобы выборка
-- формировалась с помощью табличной функции.

DROP FUNCTION IF EXISTS GetUsersWithIsAdult;
GO

CREATE FUNCTION GetUsersWithIsAdult()
RETURNS TABLE AS
RETURN
(
    SELECT
        Email,
        Name,
        BirthDate,
        RegisteredAt,
        dbo.IsAdult(BirthDate) AS IsAdult
    FROM Users
);
GO

DROP PROCEDURE IF EXISTS FillCursorUsersWithIsAdult;
GO

CREATE PROCEDURE FillCursorUsersWithIsAdult
    @UsersCursor CURSOR VARYING OUTPUT
AS
BEGIN
    SET @UsersCursor =
        CURSOR FORWARD_ONLY STATIC FOR
        SELECT * FROM dbo.GetUsersWithIsAdult(); -- Некорректно
    OPEN @UsersCursor;
END;
GO

DECLARE @UsersCursor CURSOR;
EXECUTE FillCursorUsersWithIsAdult @UsersCursor = @UsersCursor OUTPUT;
FETCH NEXT FROM @UsersCursor;
WHILE @@FETCH_STATUS = 0
    BEGIN
        FETCH NEXT FROM @UsersCursor;
    END;
CLOSE @UsersCursor;
DEALLOCATE @UsersCursor;
GO
