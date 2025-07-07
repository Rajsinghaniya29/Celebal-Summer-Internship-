CREATE TABLE dbo.DateDimension (
    SKDate INT PRIMARY KEY,
    KeyDate DATE,
    Date DATE,
    CalendarDay INT,
    CalendarMonth INT,
    CalendarQuarter INT,
    CalendarYear INT,
    DayNameLong VARCHAR(20),
    DayNameShort VARCHAR(10),
    DayNumberOfWeek INT,
    DayNumberOfYear INT,
    DaySuffix VARCHAR(5),
    FiscalWeek INT,
    FiscalPeriod INT,
    FiscalQuarter INT,
    FiscalYear INT,
    FiscalYearPeriod VARCHAR(10)
);
GO

CREATE PROCEDURE dbo.PopulateDateDimension
    @InputDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(YEAR(@InputDate), 1, 1);
    DECLARE @EndDate DATE = DATEFROMPARTS(YEAR(@InputDate), 12, 31);

    WITH DateCTE AS (
        SELECT @StartDate AS DateValue
        UNION ALL
        SELECT DATEADD(DAY, 1, DateValue)
        FROM DateCTE
        WHERE DateValue < @EndDate
    )
    INSERT INTO dbo.DateDimension (
        SKDate, KeyDate, Date,
        CalendarDay, CalendarMonth, CalendarQuarter, CalendarYear,
        DayNameLong, DayNameShort, DayNumberOfWeek, DayNumberOfYear, DaySuffix,
        FiscalWeek, FiscalPeriod, FiscalQuarter, FiscalYear, FiscalYearPeriod
    )
    SELECT
        CONVERT(INT, FORMAT(DateValue, 'yyyyMMdd')) AS SKDate,
        DateValue AS KeyDate,
        DateValue AS Date,
        DAY(DateValue) AS CalendarDay,
        MONTH(DateValue) AS CalendarMonth,
        DATEPART(QUARTER, DateValue) AS CalendarQuarter,
        YEAR(DateValue) AS CalendarYear,
        DATENAME(WEEKDAY, DateValue) AS DayNameLong,
        LEFT(DATENAME(WEEKDAY, DateValue), 3) AS DayNameShort,
        DATEPART(WEEKDAY, DateValue) AS DayNumberOfWeek,
        DATEPART(DAYOFYEAR, DateValue) AS DayNumberOfYear,
        CASE
            WHEN DAY(DateValue) IN (1, 21, 31) THEN CAST(DAY(DateValue) AS VARCHAR) + 'st'
            WHEN DAY(DateValue) IN (2, 22) THEN CAST(DAY(DateValue) AS VARCHAR) + 'nd'
            WHEN DAY(DateValue) IN (3, 23) THEN CAST(DAY(DateValue) AS VARCHAR) + 'rd'
            ELSE CAST(DAY(DateValue) AS VARCHAR) + 'th'
        END AS DaySuffix,
        DATEPART(WEEK, DateValue) AS FiscalWeek,
        MONTH(DateValue) AS FiscalPeriod,
        DATEPART(QUARTER, DateValue) AS FiscalQuarter,
        YEAR(DateValue) AS FiscalYear,
        CAST(YEAR(DateValue) AS VARCHAR) + RIGHT('0' + CAST(MONTH(DateValue) AS VARCHAR), 2) AS FiscalYearPeriod
    FROM DateCTE
    OPTION (MAXRECURSION 366);
END;
GO

EXEC dbo.PopulateDateDimension @InputDate = '2020-07-14';
GO
