USE MyCollegeDB;
GO

-- Drop the stored procedure if exists
IF OBJECT_ID('dbo.AllocateSubjects', 'P') IS NOT NULL
    DROP PROCEDURE dbo.AllocateSubjects;
GO

-- Drop tables in order considering FK dependencies
IF OBJECT_ID('dbo.Allotments', 'U') IS NOT NULL
    DROP TABLE dbo.Allotments;
GO

IF OBJECT_ID('dbo.UnallotedStudents', 'U') IS NOT NULL
    DROP TABLE dbo.UnallotedStudents;
GO

IF OBJECT_ID('dbo.StudentPreference', 'U') IS NOT NULL
    DROP TABLE dbo.StudentPreference;
GO

IF OBJECT_ID('dbo.StudentDetails', 'U') IS NOT NULL
    DROP TABLE dbo.StudentDetails;
GO

IF OBJECT_ID('dbo.SubjectDetails', 'U') IS NOT NULL
    DROP TABLE dbo.SubjectDetails;
GO

-- Create tables

CREATE TABLE StudentDetails (
    StudentID VARCHAR(20) PRIMARY KEY,
    StudentName VARCHAR(100),
    GPA DECIMAL(4,2),
    Branch VARCHAR(50),
    Section VARCHAR(10)
);
GO

CREATE TABLE SubjectDetails (
    SubjectID VARCHAR(20) PRIMARY KEY,
    SubjectName VARCHAR(100),
    MaxSeats INT,
    RemainingSeats INT
);
GO

CREATE TABLE StudentPreference (
    StudentID VARCHAR(20),
    SubjectID VARCHAR(20),
    Preference INT CHECK (Preference BETWEEN 1 AND 5),
    PRIMARY KEY (StudentID, SubjectID),
    FOREIGN KEY (StudentID) REFERENCES StudentDetails(StudentID),
    FOREIGN KEY (SubjectID) REFERENCES SubjectDetails(SubjectID)
);
GO

CREATE TABLE Allotments (
    StudentID VARCHAR(20) PRIMARY KEY,
    SubjectID VARCHAR(20),
    FOREIGN KEY (StudentID) REFERENCES StudentDetails(StudentID),
    FOREIGN KEY (SubjectID) REFERENCES SubjectDetails(SubjectID)
);
GO

CREATE TABLE UnallotedStudents (
    StudentID VARCHAR(20) PRIMARY KEY,
    FOREIGN KEY (StudentID) REFERENCES StudentDetails(StudentID)
);
GO

-- Create Stored Procedure

CREATE PROCEDURE dbo.AllocateSubjects
AS
BEGIN
    SET NOCOUNT ON;

    -- Clear previous allocations
    DELETE FROM Allotments;
    DELETE FROM UnallotedStudents;

    -- Temporary table to hold students sorted by GPA descending
    CREATE TABLE #SortedStudents (
        RowNum INT PRIMARY KEY,
        StudentID VARCHAR(20)
    );

    INSERT INTO #SortedStudents (RowNum, StudentID)
    SELECT ROW_NUMBER() OVER (ORDER BY GPA DESC), StudentID
    FROM StudentDetails;

    DECLARE @StudentID VARCHAR(20);
    DECLARE @Preference INT;
    DECLARE @SubjectID VARCHAR(20);
    DECLARE @Allocated BIT;

    DECLARE student_cursor CURSOR FOR
        SELECT StudentID FROM #SortedStudents ORDER BY RowNum;

    OPEN student_cursor;

    FETCH NEXT FROM student_cursor INTO @StudentID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Allocated = 0;
        SET @Preference = 1;

        WHILE @Preference <= 5 AND @Allocated = 0
        BEGIN
            SELECT @SubjectID = SubjectID
            FROM StudentPreference
            WHERE StudentID = @StudentID AND Preference = @Preference;

            IF @SubjectID IS NOT NULL
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM SubjectDetails WHERE SubjectID = @SubjectID AND RemainingSeats > 0
                )
                BEGIN
                    INSERT INTO Allotments (StudentID, SubjectID)
                    VALUES (@StudentID, @SubjectID);

                    UPDATE SubjectDetails
                    SET RemainingSeats = RemainingSeats - 1
                    WHERE SubjectID = @SubjectID;

                    SET @Allocated = 1;
                END
            END

            SET @Preference = @Preference + 1;
        END

        IF @Allocated = 0
        BEGIN
            INSERT INTO UnallotedStudents (StudentID)
            VALUES (@StudentID);
        END

        FETCH NEXT FROM student_cursor INTO @StudentID;
    END

    CLOSE student_cursor;
    DEALLOCATE student_cursor;

    DROP TABLE #SortedStudents;
END
GO
 EXEC dbo.AllocateSubjects;
