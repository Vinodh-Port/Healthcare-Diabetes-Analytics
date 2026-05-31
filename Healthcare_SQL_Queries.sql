
Use IPD_Healthcare

-- 1. Total Population table ni chudataniki
Select * From Population

-- 2. Total Hospital table ni chudataniki
Select * From Hospital

-- 3. Total State table ni chudataniki
Select * From State

-- 4. Diabetes Status use chesi users count chudataniki
SELECT
    DiabetesStatus,
    COUNT(UserID) AS TotalUsers,
    ROUND(AVG(DiabetesValue), 2) AS AvgDiabetesValue
FROM Population
GROUP BY DiabetesStatus
ORDER BY TotalUsers DESC;    

-- 4. Diabetes Parameter use chesi users count chudataniki
SELECT
    DiabetesParameter,
    COUNT(UserID) AS TotalUsers,
    ROUND(AVG(DiabetesValue), 2) AS AvgDiabetesValue
FROM Population
GROUP BY DiabetesParameter
ORDER BY TotalUsers DESC;

-- 5. State and hospital tables join chesi Appointments count
SELECT
    S.StateName,
    S.HospitalName,
    COUNT(H.UserID) AS TotalAppointments
FROM State S
JOIN Hospital H ON H.HospitalID = S.HospitalID
GROUP BY 
    S.StateName,  -- Manam select lo use chese unique columns ni pakkaga use cheyyali except aggregations ledante error teskuntundi
				  -- bcoz row by row count cheseppudu 5 appointments ni count cheyali kabatti only state ni group chesthe avvadu	
	S.HospitalName 
ORDER BY TotalAppointments DESC;    

-- 6. Dense_Rank(), Over(), Partition By ni use chesi ranking cheddam then Top 3 ni ranks ni chuddam
-- (CTE approach matches perfectly in MS SQL)
	-- SELECT 
		--        UserID,
		--        DiabetesStatus,
		--        DiabetesValue,
		--        DiabetesParameter,
		--        DENSE_RANK() OVER(PARTITION BY DiabetesStatus ORDER BY DiabetesValue DESC) AS PatientRank
		--    FROM 
		--        Population
		-- Where PatientRank >3;
		-- Ala rasthe wrong avtundi bcoz akkada manaku PatientRank anedi unknown column avtundi
        -- andukani manam ikkada CTE [With ... As(...)] use cheddam ante
		-- temprary table ga paina unna query antha teskuni then ah temporary table nundi Where use cheddam

WITH RankedPatients AS (
    SELECT
        UserID,
        DiabetesStatus,
        DiabetesValue,
        DiabetesParameter,
        DENSE_RANK() OVER(PARTITION BY DiabetesStatus ORDER BY DiabetesValue DESC) AS PatientRank
    FROM Population
)
SELECT
    UserID,
    DiabetesStatus,
    DiabetesValue,
    DiabetesParameter,
    PatientRank
FROM RankedPatients
WHERE PatientRank <= 3;

-- 7. Users DOB ni base cheskuni Age slabs petti Diabetes status chuddam
WITH AgeCalculation AS (
    SELECT
        UserID,
        DiabetesStatus,
        DiabetesValue,
        DATEDIFF(YEAR, UserDOB, GETDATE()) AS PatientAge
        -- MS SQL lo DATEDIFF use chestham. Unit of Measurement (YEAR) modata untundi.
        -- Background Math Process: SQL engine present date (GETDATE()) nunchi UserDOB ni subtract chesthundhi.
        -- Order: Chinna Date (Past/UserDOB) modata undali, Pedda Date (Present/GETDATE()) chivarlo undali, ledante age minus lo vasthundi.
    FROM Population
),
AgeGroups AS (
    SELECT
        UserID,
        DiabetesStatus,
        DiabetesValue,
        PatientAge,
        CASE
            WHEN PatientAge >= 60 THEN 'Senior'
            WHEN PatientAge >= 25 THEN 'Adult'
            ELSE 'Youth'
        END AS AgeGroup
    FROM AgeCalculation
)
SELECT
    AgeGroup,
    COUNT(UserID) AS PatientsCount,
    ROUND(AVG(DiabetesValue), 2) AS AvgValue
FROM AgeGroups
GROUP BY AgeGroup
ORDER BY AvgValue;   

-- 8. Top 5 best performing hospitals based on low risk rate
-- (MySQL lo unna LIMIT 5 ni tegesi, SELECT pakkana TOP 5 pettali)
SELECT TOP 5
    S.StateName,
    S.HospitalName,
    H.DiabetesStatus,
    COUNT(H.UserID) AS BestPerformanceCount
FROM State S
JOIN Hospital H ON H.HospitalID = S.HospitalID
WHERE H.DiabetesStatus = 'Low'
GROUP BY S.StateName, S.HospitalName, H.DiabetesStatus
ORDER BY BestPerformanceCount DESC;

-- 9: Calculating Overall Percentage Slabs for Patient Segments
SELECT 
    DiabetesStatus,
    COUNT(UserID) AS PatientCount,
    ROUND((COUNT(UserID) * 100.0 / (SELECT COUNT(*) FROM Population)), 2) AS RiskPercentageSlab
FROM Population
GROUP BY DiabetesStatus
ORDER BY PatientCount DESC;
    
-- 10: Analyzing Parameter Triggers for High Risk Identification
SELECT 
    DiabetesParameter,
    COUNT(UserID) AS HighRiskPatientCount
FROM Population
WHERE DiabetesStatus = 'High'
GROUP BY DiabetesParameter
ORDER BY HighRiskPatientCount DESC;

-- 11. State lo unde hospital lo diabetes parameter ki diabetes status then RiskPercentageSlab and ranking the hospitals
WITH BaseSlabCount AS (
    SELECT
        S.StateName,
        S.HospitalName,
        P.DiabetesParameter,
        P.DiabetesStatus,
        COUNT(P.UserID) AS PatientCount,
        SUM(COUNT(P.UserID)) OVER(PARTITION BY S.StateName, S.HospitalName) AS HospitalTotalCount
    FROM Population P
    JOIN Hospital H ON P.UserID = H.UserID
    JOIN State S ON H.HospitalID = S.HospitalID
    GROUP BY S.StateName, S.HospitalName, P.DiabetesParameter, P.DiabetesStatus
),
CalculatedSlab AS (
    SELECT
        StateName,
        HospitalName,
        DiabetesParameter,
        DiabetesStatus,
        PatientCount,
        ROUND((PatientCount * 100.0 / HospitalTotalCount), 2) AS RiskPercentageSlab
    FROM BaseSlabCount
)
SELECT
    StateName,
    HospitalName,
    DiabetesParameter,
    DiabetesStatus,
    PatientCount,    
    RiskPercentageSlab,
    DENSE_RANK() OVER (PARTITION BY DiabetesParameter, StateName, DiabetesStatus ORDER BY RiskPercentageSlab DESC) AS HospitalRank
FROM CalculatedSlab
ORDER BY StateName, DiabetesParameter, DiabetesStatus, HospitalRank;

-- 11 (Part 2). Partition change chesina variant
WITH BaseSlabCount AS (
    SELECT
        S.StateName,
        S.HospitalName,
        P.DiabetesParameter,
        P.DiabetesStatus,
        COUNT(P.UserID) AS PatientCount,
        SUM(COUNT(P.UserID)) OVER(PARTITION BY S.StateName, S.HospitalName) AS HospitalTotalCount
    FROM Population P
    JOIN Hospital H ON P.UserID = H.UserID
    JOIN State S ON H.HospitalID = S.HospitalID
    GROUP BY S.StateName, S.HospitalName, P.DiabetesParameter, P.DiabetesStatus
),
CalculatedSlab AS (
    SELECT
        StateName,
        HospitalName,
        DiabetesParameter,
        DiabetesStatus,
        PatientCount,
        ROUND((PatientCount * 100.0 / HospitalTotalCount), 2) AS RiskPercentageSlab
    FROM BaseSlabCount
)
SELECT
    StateName,
    HospitalName,
    DiabetesParameter,
    DiabetesStatus,
    PatientCount,    
    RiskPercentageSlab,
    DENSE_RANK() OVER (PARTITION BY PatientCount ORDER BY RiskPercentageSlab DESC) AS HospitalRank
FROM CalculatedSlab
ORDER BY StateName, HospitalRank;    

-- 12. User Age and DiabetesValue ni base cheskuni prediction cheyyali (The Master View)
-- (MS SQL requires views to be in separate batches, so GO statement mandatory)
GO
CREATE OR ALTER VIEW View_KPI_To_Win_Master AS
WITH PatientBaseMetrics AS (
    SELECT 
        P.UserID,
        S.StateName,
        S.HospitalName,
        P.DiabetesParameter,
        P.DiabetesStatus,
        P.DiabetesValue,
        DATEDIFF(YEAR, P.UserDOB, '2026-05-29') AS PatientAge,
        -- Step 1: Assigning Age Weight
        CASE 
            WHEN DATEDIFF(YEAR, P.UserDOB, '2026-05-29') >= 60 THEN 3 -- Senior
            WHEN DATEDIFF(YEAR, P.UserDOB, '2026-05-29') >= 25 THEN 2 -- Adult
            ELSE 1                                                    -- Youth
        END AS AgeWeight,
        -- Step 2: Assigning Clinical Diagnostic Severity Weight
        CASE 
            WHEN P.DiabetesStatus = 'High' THEN 3
            WHEN P.DiabetesStatus = 'Moderate' THEN 2
            ELSE 1
        END AS ClinicalSeverityWeight
    FROM Population AS P
    INNER JOIN Hospital AS H ON P.UserID = H.UserID
    INNER JOIN State AS S ON H.HospitalID = S.HospitalID
)
SELECT 
    UserID,
    StateName,
    HospitalName,
    DiabetesParameter,
    DiabetesStatus,
    DiabetesValue,
    PatientAge,
    AgeWeight,
    ClinicalSeverityWeight,
    -- Step 3: Predictive Score Index combining both dimensions
    (AgeWeight * ClinicalSeverityWeight) AS PredictiveRiskIndex,
    -- Step 4: Strategic Actionable Category for Management Intervention Insights
    CASE 
        WHEN (AgeWeight * ClinicalSeverityWeight) >= 8 THEN 'Critical Priority (Immediate Care)'
        WHEN (AgeWeight * ClinicalSeverityWeight) >= 6 THEN 'High Risk (Targeted Preventive Plan)'
        WHEN (AgeWeight * ClinicalSeverityWeight) >= 3 THEN 'Moderate Warning (Routine Monitoring)'
        ELSE 'Safe Zone (Stable Operations)'
    END AS FutureRiskCategory
FROM PatientBaseMetrics;
GO

-- View run chesi Output check cheyadaniki (LIMIT 50 converted to TOP 50)
SELECT * FROM View_KPI_To_Win_Master 
ORDER BY StateName;

-- Adding more data

-- 1. Population Table loki kotha rows append cheyadam
INSERT INTO [Population] (UserID, UserDOB, DiabetesCode, DiabetesValue, DiabetesParameter, DiabetesStatus)
SELECT UserID, UserDOB, DiabetesCode, DiabetesValue, DiabetesParameter, DiabetesStatus 
FROM Temp_Population;

Select * From Population

-- 2. State Table loki kotha rows append cheyadam
INSERT INTO [State] (StateID, StateName, HospitalName, HospitalID, DiabetesCode)
SELECT StateID, StateName, HospitalName, HospitalID, DiabetesCode 
FROM Temp_State;

Select * From State

-- 3. Hospital Table loki kotha rows append cheyadam
INSERT INTO [Hospital] (HospitalID, UserID, ApptDate, ApptTime, DoctorID, DiabetesStatus)
SELECT HospitalID, UserID, ApptDate, ApptTime, DoctorID, DiabetesStatus 
FROM Temp_Hospital;

Select * From Hospital
Select * From State
Select * From Population

-- Manipulating the data

Drop Table Temp_Population;
Drop Table Temp_State;
Drop Table Temp_Hospital;

Update [State]
Set StateID = 'S11', StateName = 'Odisha'
Where StateID = '1';

Update [State]
Set StateID = 'S12', StateName = 'MadhyaPradesh'
Where StateID = '2';

Update [State]
Set StateID = 'S13', StateName = 'Rajasthan'
Where StateID = '3';

Update [State]
Set StateID = 'S14', StateName = 'UttarPradesh'
Where StateID = '4';

Update [State]
Set StateID = 'S15', StateName = 'HimachalPradesh'
Where StateID = '5';

Update [State]
Set DiabetesCode = 'DIA111'
Where StateID = 'S11';

Update [State]
Set DiabetesCode = 'DIA112'
Where StateID = 'S12';

Update [State]
Set DiabetesCode = 'DIA113'
Where StateID = 'S13';

Update [State]
Set DiabetesCode = 'DIA114'
Where StateID = 'S14';

Update [State]
Set DiabetesCode = 'DIA115'
Where StateID = 'S15';

Update[Hospital] Set UserID = 'USR00004' Where UserID = '36'
Update[Hospital] Set UserID = 'USR00006' Where UserID = '37'
Update[Hospital] Set UserID = 'USR00013' Where UserID = '38'
Update[Hospital] Set UserID = 'USR00020' Where UserID = '39'
Update[Hospital] Set UserID = 'USR00029' Where UserID = '40'
Update[Hospital] Set UserID = 'USR00039' Where UserID = '41'
Update[Hospital] Set UserID = 'USR00048' Where UserID = '42'
Update[Hospital] Set UserID = 'USR15008' Where UserID = '43'
Update[Hospital] Set UserID = 'USR15009' Where UserID = '44'
Update[Hospital] Set UserID = 'USR15010' Where UserID = '45'
Update[Hospital] Set UserID = 'USR15016' Where UserID = '46'
Update[Hospital] Set UserID = 'USR15012' Where UserID = '47'
Update[Hospital] Set UserID = 'USR15017' Where UserID = '48'
Update[Hospital] Set UserID = 'USR15014' Where UserID = '49'
Update[Hospital] Set UserID = 'USR15015' Where UserID = '50'
Update[Hospital] Set UserID = 'USR15029' Where UserID = '51'
Update[Hospital] Set UserID = 'USR15030' Where UserID = '52'
Update[Hospital] Set UserID = 'USR15018' Where UserID = '53'
Update[Hospital] Set UserID = 'USR15019' Where UserID = '54'
Update[Hospital] Set UserID = 'USR00163' Where UserID = '55'
Update[Hospital] Set UserID = 'USR00175' Where UserID = '56'
Update[Hospital] Set UserID = 'USR00182' Where UserID = '57'
Update[Hospital] Set UserID = 'USR15023' Where UserID = '58'
Update[Hospital] Set UserID = 'USR15024' Where UserID = '59'
Update[Hospital] Set UserID = 'USR15025' Where UserID = '60'
Update[Hospital] Set UserID = 'USR00494' Where UserID = '61'
Update[Hospital] Set UserID = 'USR00515' Where UserID = '62'
Update[Hospital] Set UserID = 'USR00538' Where UserID = '63'
Update[Hospital] Set UserID = 'USR00554' Where UserID = '64'
Update[Hospital] Set UserID = 'USR00573' Where UserID = '65'



