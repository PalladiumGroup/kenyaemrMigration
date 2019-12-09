--1. Demographics
exec pr_OpenDecryptedSession;
SELECT
P.Id Person_Id, 
PT.Id Patient_Id,
CAST(DECRYPTBYKEY(P.FirstName) AS VARCHAR(50)) AS FirstName,
CAST(DECRYPTBYKEY(P.MidName) AS VARCHAR(50)) AS MiddleName,
CAST(DECRYPTBYKEY(P.LastName) AS VARCHAR(50)) AS LastName,
CAST(DECRYPTBYKEY(P.NickName) AS VARCHAR(50)) AS Nickname,
format(cast(ISNULL(P.DateOfBirth, PT.DateOfBirth) as date),'yyyy-MM-dd') AS DOB,
CASE(ISNULL(P.DobPrecision, PT.DobPrecision))
	WHEN 0 THEN 'EXACT'
	WHEN 1 THEN 'ESTIMATED'
	ELSE 'ESTIMATED' END AS Exact_DOB,
Sex = (SELECT (case when ItemName = 'Female' then 'F' when ItemName = 'Male' then 'M' else ItemName end) FROM LookupItemView WHERE MasterName = 'GENDER' AND ItemId = P.Sex),
UPN = (SELECT IdentifierValue FROM PatientEnrollment PTE INNER JOIN PatientIdentifier PIE ON PIE.PatientEnrollmentId = PTE.Id WHERE PTE.ServiceAreaId = 1 AND PIE.IdentifierTypeId = 1 AND PIE.DeleteFlag = 0 AND PTE.DeleteFlag = 0 AND PTE.PatientId = PT.Id AND PIE.PatientId = PT.Id),
format(cast(ISNULL(P.RegistrationDate, PT.RegistrationDate) as date),'yyyy-MM-dd') AS Encounter_Date,
NULL Encounter_ID,
(CASE(Select t.IdentifierValue from (select PIR.IdentifierValue from PersonIdentifier PIR
INNER JOIN Identifiers IDE ON IDE.Id = PIR.IdentifierId
WHERE IDE.Name = 'NationalID' AND PIR.PersonId = P.Id) t)
WHEN NULL THEN PT.NationalId
ELSE (Select t.IdentifierValue from (select PIR.IdentifierValue from PersonIdentifier PIR
INNER JOIN Identifiers IDE ON IDE.Id = PIR.IdentifierId
WHERE IDE.Name = 'NationalID' AND PIR.PersonId = P.Id) t) END) AS National_id_No,
(SELECT PatientClinicID FROM mst_Patient MSP WHERE MSP.Ptn_Pk = PT.ptn_pk) AS Patient_clinic_number,
Birth_certificate=(select top 1 pdd.IdentifierValue from (select pid.PersonId,pid.IdentifierId,pid.IdentifierValue,pdd.Code,pdd.DisplayName,pdd.[Name],pid.CreateDate,pid.DeleteFlag from PersonIdentifier pid
inner join (
select id.Id,id.[Name],id.[Code],id.[DisplayName]  from Identifiers id
inner join  IdentifierType it on it.Id =id.IdentifierType
where it.Name='Person')pdd on pdd.Id=pid.IdentifierId  ) pdd where pdd.PersonId = P.Id and pdd.[Name]='BirthCertificate' and pdd.DeleteFlag=0 order by pdd.CreateDate desc),
Birth_notification=(select top 1 pdd.IdentifierValue from (select pid.PersonId,pid.IdentifierId,pid.IdentifierValue,pdd.Code,pdd.DisplayName,pdd.[Name],pid.CreateDate,pid.DeleteFlag from PersonIdentifier pid
inner join (
select id.Id,id.[Name],id.[Code],id.[DisplayName]  from Identifiers id
inner join  IdentifierType it on it.Id =id.IdentifierType
where it.Name='Person')pdd on pdd.Id=pid.IdentifierId  ) pdd where pdd.PersonId = P.Id and pdd.[Name]='BirthNotification' and pdd.DeleteFlag=0 order by pdd.CreateDate desc),
Hei_no=(select top 1 pdd.IdentifierValue from (select pid.PatientId,pid.IdentifierTypeId,pid.IdentifierValue,pdd.Code,pdd.DisplayName,pdd.[Name],pid.CreateDate,pid.DeleteFlag from PatientIdentifier pid
inner join (
select id.Id,id.[Name],id.[Code],id.[DisplayName]  from Identifiers id
inner join  IdentifierType it on it.Id =id.IdentifierType
where it.Name='Patient')pdd on pdd.Id=pid.IdentifierTypeId  ) pdd where pdd.PatientId = PT.Id and pdd.[Code]='HEIRegistration' and pdd.DeleteFlag=0 order by pdd.CreateDate desc ),
Passport=(select top 1 pdd.IdentifierValue from (select pid.PersonId,pid.IdentifierId,pid.IdentifierValue,pdd.Code,pdd.DisplayName,pdd.[Name],pid.CreateDate,pid.DeleteFlag from PersonIdentifier pid
inner join (
select id.Id,id.[Name],id.[Code],id.[DisplayName]  from Identifiers id
inner join  IdentifierType it on it.Id =id.IdentifierType
where it.Name='Person')pdd on pdd.Id=pid.IdentifierId  ) pdd where pdd.PersonId = P.Id and pdd.[Name]='Passport' and pdd.DeleteFlag=0 order by pdd.CreateDate desc),
Alien_Registration=(select top 1 pdd.IdentifierValue from (select pid.PersonId,pid.IdentifierId,pid.IdentifierValue,pdd.Code,pdd.DisplayName,pdd.[Name],pid.CreateDate,pid.DeleteFlag from PersonIdentifier pid
inner join (
select id.Id,id.[Name],id.[Code],id.[DisplayName]  from Identifiers id
inner join  IdentifierType it on it.Id =id.IdentifierType
where it.Name='Person')pdd on pdd.Id=pid.IdentifierId  ) pdd where pdd.PersonId = P.Id and pdd.[Name]='AlienRegistration' and pdd.DeleteFlag=0 order by pdd.CreateDate desc),
CAST(DECRYPTBYKEY((SELECT TOP 1 PC.MobileNumber FROM PersonContact PC WHERE PC.DeleteFlag = 0 AND PC.PersonId = P.Id ORDER BY Id DESC)) AS VARCHAR(50)) AS Phone_number,
CAST(DECRYPTBYKEY((SELECT TOP 1 PC.AlternativeNumber FROM PersonContact PC WHERE PC.DeleteFlag = 0 AND PC.PersonId = P.Id ORDER BY Id DESC)) AS VARCHAR(50)) Alternate_Phone_number,
CAST(DECRYPTBYKEY((SELECT TOP 1 PC.PhysicalAddress FROM PersonContact PC WHERE PC.DeleteFlag = 0 AND PC.PersonId = P.Id ORDER BY Id DESC)) AS VARCHAR(50)) Postal_Address,
CAST(DECRYPTBYKEY((SELECT TOP 1 PC.EmailAddress FROM PersonContact PC WHERE PC.DeleteFlag = 0 AND PC.PersonId = P.Id ORDER BY Id DESC)) AS VARCHAR(50)) Email_address,
County = (select TOP 1 C.CountyName from PersonLocation PL INNER JOIN County C ON C.CountyId = PL.County WHERE PL.PersonId = P.Id AND PL.DeleteFlag = 0 ORDER BY PL.Id DESC),
Sub_county = (select TOP 1 C.Subcountyname from PersonLocation PL INNER JOIN County C ON C.SubcountyId = PL.SubCounty WHERE PL.PersonId = P.Id AND PL.DeleteFlag = 0 ORDER BY PL.Id DESC),
Ward = (select TOP 1 C.WardName from PersonLocation PL INNER JOIN County C ON C.WardId = PL.Ward WHERE PL.PersonId = P.Id AND PL.DeleteFlag = 0 ORDER BY PL.Id DESC),
Village = (select TOP 1 PL.Village from PersonLocation PL WHERE PL.PersonId = P.Id AND PL.DeleteFlag = 0 ORDER BY PL.Id DESC),
Landmark = (select TOP 1 PL.LandMark from PersonLocation PL WHERE PL.PersonId = P.Id AND PL.DeleteFlag = 0 ORDER BY PL.Id DESC),
Nearest_Health_Centre = (select TOP 1 PL.NearestHealthCentre from PersonLocation PL WHERE PL.PersonId = P.Id AND PL.DeleteFlag = 0 ORDER BY PL.Id DESC),
Marital_status = (SELECT TOP 1 ItemName FROM PatientMaritalStatus PM INNER JOIN LookupItemView LK ON LK.ItemId = PM.MaritalStatusId WHERE PM.PersonId = P.Id AND PM.DeleteFlag = 0 AND LK.MasterName = 'MaritalStatus'),
Occupation = (SELECT TOP 1 ItemName FROM PersonOccupation PO INNER JOIN LookupItemView LK ON LK.ItemId = PO.Occupation WHERE PO.PersonId = P.Id AND MasterName = 'Occupation' AND PO.DeleteFlag = 0 ORDER BY Id DESC),
Education_level = (SELECT TOP 1 ItemName FROM PersonEducation EL INNER JOIN LookupItemView LK ON LK.ItemId = EL.EducationLevel WHERE EL.PersonId = P.Id and MasterName = 'EducationalLevel' AND EL.DeleteFlag = 0 ORDER BY Id DESC),
Dead = (SELECT top 1  'Yes' FROM PatientCareending WHERE DeleteFlag = 0 AND ExitReason = (SELECT ItemId FROM LookupItemView WHERE MasterName = 'CareEnded' AND ItemName = 'Death') AND PatientId = PT.Id AND DateOfDeath IS NOT NULL ORDER BY Id DESC),
Death_date = (SELECT TOP 1 DateOfDeath FROM PatientCareending WHERE DeleteFlag = 0 AND ExitReason = (SELECT ItemId FROM LookupItemView WHERE MasterName = 'CareEnded' AND ItemName = 'Death') AND PatientId = PT.Id AND DateOfDeath IS NOT NULL ORDER BY Id DESC),
PT.DeleteFlag AS voided 


FROM Person P
LEFT JOIN Patient PT ON PT.PersonId = P.Id
ORDER BY P.Id ASC


--2. HIV ENROLLMENT. Careful thought on this on
/*SELECT
PT.Id PatientId,
PT.PersonId Person_Id,
Patient_Type = (SELECT ItemName FROM LookupItemView LK WHERE LK.ItemId = PT.PatientType AND LK.MasterName = 'PatientType'),
Entry_point = (SELECT TOP 1 LK.ItemName FROM ServiceEntryPoint SE INNER JOIN LookupItemView LK ON LK.ItemId = EntryPointId WHERE SE.PatientId = PT.Id AND ServiceAreaId = 1 ORDER BY SE.Id DESC),
TI_Facility = (select FacilityFrom from PatientTransferIn PTI WHERE PTI.PatientId = PT.Id),
CASE (SELECT ItemName FROM LookupItemView LK WHERE LK.ItemId = PT.PatientType AND LK.MasterName = 'PatientType')
WHEN 'New' THEN PE.EnrollmentDate
WHEN 'Transit' THEN PE.EnrollmentDate
WHEN 'Transfer-In' THEN (SELECT TOP 1 EnrollmentDate from PatientHivDiagnosis PHD WHERE PHD.PatientId = PT.Id AND PHD.DeleteFlag = 0 ORDER BY Id DESC)
ELSE PE.EnrollmentDate END AS Date_First_enrolled_in_care,
CASE (SELECT ItemName FROM LookupItemView LK WHERE LK.ItemId = PT.PatientType AND LK.MasterName = 'PatientType')
WHEN 'New' THEN NULL
WHEN 'Transit' THEN NULL
WHEN 'Transfer-In' THEN (select TransferInDate from PatientTransferIn PTI WHERE PTI.PatientId = PT.Id AND PTI.DeleteFlag = 0)
ELSE NULL END AS Transfer_In_Date,
CASE (SELECT ItemName FROM LookupItemView LK WHERE LK.ItemId = PT.PatientType AND LK.MasterName = 'PatientType')
WHEN 'New' THEN NULL
WHEN 'Transit' THEN NULL
WHEN 'Transfer-In' THEN (select TreatmentStartDate from PatientTransferIn PTI WHERE PTI.PatientId = PT.Id AND PTI.DeleteFlag = 0)
ELSE NULL END AS Date_started_art_at_transferring_facility,


PT.DeleteFlag Voided


FROM Patient PT
INNER JOIN PatientEnrollment PE ON PE.PatientId = PT.Id
WHERE PE.ServiceAreaId = 1;*/

--3 Triage
SELECT 
P.PersonId Person_Id,
P.Id Patient_Id,
Encounter_Date = format(cast(PM.VisitDate as date),'yyyy-MM-dd'),
Encounter_ID = PM.Id,
Visit_reason = NULL,
Systolic_pressure = CAST(PV.BPSystolic AS decimal),
Diastolic_pressure = CAST(PV.BPDiastolic AS decimal),
Respiratory_rate = PV.RespiratoryRate,
Pulse_rate = PV.HeartRate,
Oxygen_saturation = PV.SpO2,
Weight = PV.Weight,
Height = PV.Height,
Temperature = PV.Temperature,
BMI = PV.BMI,
Muac = PV.Muac,
Weight_for_age_zscore = PV.WeightForAge,
Weight_for_height_zscore = PV.WeightForHeight,
BMI_Zscore = PV.BMIZ,
Head_circumference = PV.HeadCircumference,
NUll as Nutritional_status,
format(cast(PIR.LMP as date),'yyyy-MM-dd') as Last_menstrual_period,
CAST(PV.NursesComments AS varchar(MAX)) as Nurse_Comments,
PV.DeleteFlag as Voided

FROM [dbo].[PatientVitals] PV
INNER JOIN Patient P ON P.Id = PV.PatientId
INNER JOIN PatientMasterVisit PM ON PM.Id = PV.PatientMasterVisitId
LEFT JOIN PregnancyIndicator PIR ON PIR.PatientMasterVisitId = PM.Id
UNION
SELECT
Person_Id = P.PersonId,
P.Id Patient_Id,
Encounter_Date = format(cast(OV.VisitDate as date),'yyyy-MM-dd'),
Encounter_ID = OV.Visit_Id,
Visit_reason = NULL,
Systolic_pressure = DPV.BPSystolic,
Diastolic_pressure = DPV.BPDiastolic,
Respiratory_rate = NULL,
Pulse_rate = NULL,
Oxygen_saturation = DPV.SP02,
Weight = DPV.Weight,
Height = DPV.Height,
Temperature = DPV.Temp,
BMI = NULL,
Muac = DPV.Muac,
Weight_for_age_zscore = NULL,
Weight_for_height_zscore = NULL,
BMI_Zscore = NULL,
Head_circumference = NULL,
NUll as Nutritional_status,
format(cast(PCS.LMP as date),'yyyy-MM-dd') as Last_menstrual_period,
NULL as Nurse_Comments,
0 as Voided

FROM dtl_PatientVitals DPV
left join Patient P on p.ptn_pk = DPV.Ptn_pk
left join ord_Visit OV ON OV.Visit_Id = DPV.Visit_pk
left join dtl_PatientClinicalStatus PCS ON PCS.Visit_pk = OV.Visit_Id;

-- KEY POPULATION
SELECT 
PersonId Person_Id,
Pop_Type = PopulationType,
Key_Pop_Type = (SELECT ItemName FROM LookupItemView LK WHERE LK.ItemId = PopulationCategory AND MasterName = 'KeyPopulation'),
Voided = DeleteFlag

FROM [dbo].[PatientPopulation]

-- 4. HTS Initial Encounter
SELECT 
HE.PersonId Person_Id,
PT.Id Patient_Id,
Encounter_Date = format(cast(PE.EncounterStartTime as date),'yyyy-MM-dd'),
Encounter_ID = HE.Id,
Pop_Type = PPL2.PopulationType,
Key_Pop_Type = PPL2.KeyPop,
Priority_Pop_Type = PPR2.PrioPop,
Patient_disabled = (CASE ISNULL(PI.Disability, '') WHEN '' THEN 'No' ELSE 'Yes' END),
PI.Disability,
Ever_Tested = (SELECT ItemName FROM LookupItemView WHERE ItemId = HE.EverTested AND MasterName = 'YesNo'),
Self_Tested = (SELECT ItemName FROM LookupItemView WHERE ItemId = HE.EverSelfTested AND MasterName = 'YesNo'),
HE.MonthSinceSelfTest,
HE.MonthsSinceLastTest,
HTS_Strategy = (SELECT ItemName FROM LookupItemView WHERE MasterName = 'Strategy' AND ItemId = HE.TestingStrategy),
HTS_Entry_Point = (SELECT ItemName FROM LookupItemView WHERE MasterName = 'HTSEntryPoints' AND ItemId = HE.TestEntryPoint),
NULL as Consented,
TestedAs = (SELECT ItemName FROM LookupItemView WHERE ItemId = HE.TestedAs AND MasterName = 'TestedAs'),
TestType = CASE HE.EncounterType WHEN 1 THEN 'Initial Test' WHEN 2 THEN 'Repeat Test' END,
NULL as Test_1_Kit_Name,
NULL as Test_1_Lot_Number,
NULL as Test_1_Expiry_Date,
NULL as Test_1_Final_Result,
NULL as Test_2_Kit_Name,
NULL as Test_2_Lot_Number,
NULL as Test_2_Expiry_Date,
NULL as Test_2_Final_Result,
Final_Result = (SELECT ItemName FROM LookupItemView WHERE ItemId = HER.FinalResult AND MasterName = 'HIVFinalResults'),
Result_given = (SELECT ItemName FROM LookupItemView WHERE ItemId = HE.FinalResultGiven AND MasterName = 'YesNo'),
Couple_Discordant = (SELECT ItemName FROM LookupItemView WHERE ItemId = HE.CoupleDiscordant AND MasterName = 'YesNoNA'),
TB_SCreening_Results = (select top 1 ItemName from LookupItemView where MasterName = 'TbScreening' AND ItemId = (select top 1 ScreeningValueId from PatientScreening where PatientMasterVisitId = PM.Id AND PatientId = PT.Id and ScreeningTypeId = (select top 1 MasterId from LookupItemView where MasterName = 'TbScreening'))),
HE.EncounterRemarks as Remarks, 
0 as Voided

FROM HtsEncounter HE 
LEFT JOIN HtsEncounterResult HER ON HER.HtsEncounterId = HE.Id
INNER JOIN PatientEncounter PE ON PE.Id = HE.PatientEncounterID
INNER JOIN PatientMasterVisit PM ON PM.Id = PE.PatientMasterVisitId
INNER JOIN Person P ON P.Id = HE.PersonId
INNER JOIN Patient PT ON PT.PersonId = P.Id
LEFT JOIN (SELECT Main.Person_Id, LEFT(Main.Disability,Len(Main.Disability)-1) As "Disability"
FROM
    (
        SELECT DISTINCT P.Id Person_Id, 
            (
                SELECT 
				(SELECT ItemName FROM LookupItemView WHERE MasterName = 'Disabilities' AND ItemId = CD.DisabilityId) + ' , ' AS [text()]
                FROM ClientDisability CD
				INNER JOIN PatientEncounter PE ON PE.Id = CD.PatientEncounterID
                WHERE CD.PersonId = P.Id
                ORDER BY CD.PersonId
                FOR XML PATH ('')
            ) [Disability]
        FROM Person P
    ) [Main]) PI ON PI.Person_Id = P.Id
LEFT JOIN ( SELECT PPL.Person_Id, PPL.PopulationType, PPL.KeyPop
FROM
	(
		SELECT DISTINCT  P.Id Person_Id, PPT.PopulationType,
			(
				SELECT 
				(SELECT ItemName FROM LookupItemView LK WHERE LK.ItemId = PP.PopulationCategory AND MasterName = 'HTSKeyPopulation') + ' , ' AS [text()]
				FROM PatientPopulation PP
				WHERE PP.PersonId = P.Id
				ORDER BY PP.PersonId
				FOR XML PATH ('')
			) [KeyPop]
		FROM Person P
		LEFT JOIN PatientPopulation PPT ON PPT.PersonId = P.Id
	) PPL) PPL2 ON PPL2.Person_Id = P.Id
LEFT JOIN (SELECT PPR.Person_Id, PPR.PrioPop

FROM
	(
		SELECT DISTINCT  P.Id Person_Id, 
		(
			SELECT

					(SELECT ItemName FROM LookupItemView LK WHERE LK.ItemId = PP.PriorityId AND MasterName = 'PriorityPopulation') + ' , ' AS [text()]

					FROM PersonPriority PP
					WHERE PP.PersonId = P.Id
					ORDER BY PP.PersonId
					FOR XML PATH ('')
				) [PrioPop]
			FROM Person P
			LEFT JOIN PersonPriority PPY ON PPY.PersonId = P.Id
		) PPR
) PPR2 ON PPR2.Person_Id = P.Id

--6. HTS Client Tracing
SELECT 
PersonID,
Encounter_Date = T.DateTracingDone,
Encounter_ID = T.Id,
Contact_Type = (SELECT ItemName FROM LookupItemView WHERE ItemId=T.Mode AND MasterName = 'TracingMode'),
Contact_Outcome = (SELECT ItemName FROM LookupItemView WHERE ItemId=T.Outcome AND MasterName = 'TracingOutcome'),
Reason_uncontacted = (SELECT ItemId FROM LookupItemView WHERE ItemId= T.ReasonNotContacted AND MasterName in ('TracingReasonNotContactedPhone','TracingReasonNotContactedPhysical')),
T.OtherReasonSpecify,
T.Remarks,
T.DeleteFlag Voided

FROM Tracing T

--7. HTS Referral


 
