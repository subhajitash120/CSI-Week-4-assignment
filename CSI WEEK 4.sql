create database CSI_WEEK_4
use CSI_WEEK_4

-- Create the StudentDetails table
CREATE TABLE StudentDetails (
    StudentId INT PRIMARY KEY,
    StudentName VARCHAR(255),
    GPA FLOAT,
    Branch VARCHAR(255),
    Section VARCHAR(10)
);
GO

-- Create the SubjectDetails table
CREATE TABLE SubjectDetails (
    SubjectId VARCHAR(10) PRIMARY KEY,
    SubjectName VARCHAR(255),
    MaxSeats INT,
    RemainingSeats INT
);
GO

-- Create the StudentPreference table
CREATE TABLE StudentPreference (
    StudentId INT,
    SubjectId VARCHAR(10),
    Preference INT,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId),
    CONSTRAINT UC_Student_Subject UNIQUE (StudentId, SubjectId)
);
GO

-- Create the Allotments table
CREATE TABLE Allotments (
    SubjectId VARCHAR(10),
    StudentId INT,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId)
);
GO

-- Create the UnallotedStudents table
CREATE TABLE UnallotedStudents (
    StudentId INT,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);
GO

-- Insert data into StudentDetails
INSERT INTO StudentDetails (StudentId, StudentName, GPA, Branch, Section)
VALUES 
(159103036, 'Mohit Agarwal', 8.9, 'CCE', 'A'),
(159103037, 'Rohit Agarwal', 5.2, 'CCE', 'A'),
(159103038, 'Shohit Garg', 7.1, 'CCE', 'B'),
(159103039, 'Mrinal Malhotra', 7.9, 'CCE', 'A'),
(159103040, 'Mehreet Singh', 5.6, 'CCE', 'A'),
(159103041, 'Arjun Tehlan', 9.2, 'CCE', 'B');
GO

-- Insert data into SubjectDetails
INSERT INTO SubjectDetails (SubjectId, SubjectName, MaxSeats, RemainingSeats)
VALUES 
('PO1491', 'Basics of Political Science', 60, 2),
('PO1492', 'Basics of Accounting', 120, 119),
('PO1493', 'Basics of Financial Markets', 90, 90),
('PO1494', 'Eco philosophy', 60, 50),
('PO1495', 'Automotive Trends', 60, 60);
GO

-- Insert data into StudentPreference
INSERT INTO StudentPreference (StudentId, SubjectId, Preference)
VALUES 
(159103036, 'PO1491', 1),
(159103036, 'PO1492', 2),
(159103036, 'PO1493', 3),
(159103036, 'PO1494', 4),
(159103036, 'PO1495', 5),
(159103037, 'PO1491', 1),
(159103037, 'PO1492', 2),
(159103037, 'PO1493', 3),
(159103037, 'PO1494', 4),
(159103037, 'PO1495', 5),
(159103038, 'PO1491', 1),
(159103038, 'PO1492', 2),
(159103038, 'PO1493', 3),
(159103038, 'PO1494', 4),
(159103038, 'PO1495', 5),
(159103039, 'PO1491', 1),
(159103039, 'PO1492', 2),
(159103039, 'PO1493', 3),
(159103039, 'PO1494', 4),
(159103039, 'PO1495', 5),
(159103040, 'PO1491', 1),
(159103040, 'PO1492', 2),
(159103040, 'PO1493', 3),
(159103040, 'PO1494', 4),
(159103040, 'PO1495', 5),
(159103041, 'PO1491', 1),
(159103041, 'PO1492', 2),
(159103041, 'PO1493', 3),
(159103041, 'PO1494', 4),
(159103041, 'PO1495', 5);
GO

-- Create the AllocateSubjects stored procedure
CREATE PROCEDURE AllocateSubjects
AS
BEGIN
    DECLARE @studentId INT;
    DECLARE @studentGPA FLOAT;
    DECLARE @subjectId VARCHAR(10);
    DECLARE @pref INT;
    DECLARE @remainingSeats INT;

    -- Declare a cursor to select students sorted by GPA
    DECLARE student_cursor CURSOR FOR 
    SELECT StudentId, GPA
    FROM StudentDetails
    ORDER BY GPA DESC;

    -- Declare another cursor to select preferences for each student
    DECLARE pref_cursor CURSOR FOR
    SELECT SubjectId, Preference
    FROM StudentPreference
    WHERE StudentId = @studentId
    ORDER BY Preference;

    -- Open the student cursor
    OPEN student_cursor;

    FETCH NEXT FROM student_cursor INTO @studentId, @studentGPA;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Open preference cursor for the current student
        SET @remainingSeats = 0; -- Initialize @remainingSeats to ensure it's cleared for each student
        OPEN pref_cursor;

        FETCH NEXT FROM pref_cursor INTO @subjectId, @pref;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if the subject has available seats
            SELECT @remainingSeats = RemainingSeats
            FROM SubjectDetails
            WHERE SubjectId = @subjectId;

            IF @remainingSeats > 0
            BEGIN
                -- Allocate the subject to the student
                INSERT INTO Allotments (SubjectId, StudentId)
                VALUES (@subjectId, @studentId);

                -- Update the remaining seats
                UPDATE SubjectDetails
                SET RemainingSeats = RemainingSeats - 1
                WHERE SubjectId = @subjectId;

                -- Exit the preference loop since allocation is done
                BREAK;
            END;

            FETCH NEXT FROM pref_cursor INTO @subjectId, @pref;
        END;

        -- Check if the student is still unallotted after checking all preferences
        IF NOT EXISTS (
            SELECT 1 
            FROM Allotments 
            WHERE StudentId = @studentId
        )
        BEGIN
            INSERT INTO UnallotedStudents (StudentId)
            VALUES (@studentId);
        END;

        -- Close the preference cursor for the current student
        CLOSE pref_cursor;

        FETCH NEXT FROM student_cursor INTO @studentId, @studentGPA;
    END;

    -- Close the student cursor
    CLOSE student_cursor;
END;
GO

-- Call the AllocateSubjects stored procedure
EXEC AllocateSubjects;
GO

-- Display the final result of Allotments
SELECT * FROM Allotments;
GO

-- Display the final result of UnallotedStudents
SELECT * FROM UnallotedStudents;
GO

