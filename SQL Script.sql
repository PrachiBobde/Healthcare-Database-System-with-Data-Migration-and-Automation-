CREATE DATABASE HospitalDB;
Use HospitalDB;

create table departments
(departmentID int auto_increment primary key,
name varchar(50) not null);

create table doctors
(doctorID int auto_increment primary key,
name varchar(50),
specialization varchar(100),
role varchar(50),
departmentID int,
foreign key (departmentID) references departments(departmentID));

create table patients
(patientID int auto_increment primary key,
name varchar(50),
DateofBirth date,
Gender varchar(50),
Phone varchar(15),
check (gender in('m','f','o')));

create table appointments
(appointmentID int auto_increment primary key,
pateintID int,
doctorID int,
appointmenttime datetime,
status varchar(50),
foreign key (pateintID) references patients(patientID),
foreign key (doctorID) references doctors(doctorID),
check (status in('Scheduled', 'Completed', 'Cancelled')));

create table prescriptions
(prescriptionID int auto_increment primary key,
appointmentID int,
medication varchar(100),
dosage varchar(100),
foreign key (appointmentID) references appointments(appointmentID));

create table bills 
(billID int auto_increment primary key,
appointmentID int,
amount decimal(10,2),
paid tinyint(1),
billdate datetime default current_timestamp,
foreign key (appointmentID) references appointments(appointmentID));

create table labreports 
(reportID int auto_increment primary key,
appointmentID int,
reportdata text,
createdat datetime default current_timestamp,
foreign key (appointmentID) references appointments(appointmentID));

select * from hospital_data

select concat('select',group_concat(concat('`',column_name,'`')),'from hospital_data')
from information_schema.columns
where table_schema='hospitaldb'
and Table_name  ='hospital_data'
and column_name like 'Departments.%'


insert into departments(departmentID,name)
select`Departments.DepartmentID`,`Departments.Name`from hospital_data
where `Departments.DepartmentID`<>''

select concat('select',group_concat(concat('`',column_name,'`')),'from hospital_data')
from information_schema.columns
where table_schema='hospitaldb'
and Table_name  ='hospital_data'
and column_name like 'Doctors.%'

insert into doctors(doctorID,name,specialization,role,departmentID)
select`Doctors.DoctorID`,`Doctors.Name`,`Doctors.Specialization`,`Doctors.Role`,`Doctors.DepartmentID`from hospital_data
where `Doctors.DoctorID` <> ''

select concat('select',group_concat(concat('`',column_name,'`')),'from hospital_data')
from information_schema.columns
where table_schema='hospitaldb'
and Table_name  ='hospital_data'
and column_name like 'Patients.%'

insert into patients(patientID,name,DateofBirth,Gender,Phone)
select`Patients.PatientID`,`Patients.Name`,
str_to_date(`Patients.DateOfBirth`, '%d-%m-%Y') ,
`Patients.Gender`,`Patients.Phone`from hospital_data
where `Patients.PatientID` <> ''

select concat('select',group_concat(concat('`',column_name,'`')),'from hospital_data')
from information_schema.columns
where table_schema='hospitaldb'
and Table_name  ='hospital_data'
and column_name like 'Appointments.%'

insert into appointments(appointmentID,pateintID,doctorID,appointmenttime,status)
select`Appointments.AppointmentID`,`Appointments.PatientID`,`Appointments.DoctorID`,
str_to_date(`Appointments.AppointmentTime`, '%d-%m-%Y %H:%i'),
`Appointments.Status`from hospital_data

select concat('select',group_concat(concat('`',column_name,'`')),'from hospital_data')
from information_schema.columns
where table_schema='hospitaldb'
and Table_name  ='hospital_data'
and column_name like 'Prescriptions.%'

insert into prescriptions(prescriptionID,appointmentID,medication,dosage)
select`Prescriptions.PrescriptionID`,`Prescriptions.AppointmentID`,`Prescriptions.Medication`,`Prescriptions.Dosage`from hospital_data
where `Prescriptions.PrescriptionID`<> ''

select concat('select',group_concat(concat('`',column_name,'`')),'from hospital_data')
from information_schema.columns
where table_schema='hospitaldb'
and Table_name  ='hospital_data'
and column_name like 'Bills.%'

insert into bills(billID,appointmentID,amount,paid,billdate)
select`Bills.BillID`,`Bills.AppointmentID`,`Bills.Amount`,`Bills.Paid`,`Bills.BillDate`from hospital_data
where `Bills.BillID` <> ''

select concat('select',group_concat(concat('`',column_name,'`')),'from hospital_data')
from information_schema.columns
where table_schema='hospitaldb'
and Table_name  ='hospital_data'
and column_name like 'Labreports.%'

insert into labreports(reportID,appointmentID,reportdata,createdat)
select`LabReports.ReportID`,`LabReports.AppointmentID`,`LabReports.ReportData`,`LabReports.CreatedAt`from hospital_data
where `LabReports.ReportID` <> ''

DELIMITER $$
CREATE TRIGGER CHECK_NEW_APPOINMENT
BEFORE INSERT ON APPOINTMENTS
FOR EACH ROW
BEGIN 
   IF NEW.APPOINTMENTTIME< NOW() THEN 
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Error: Appointment cannot be  in the past.';
   END IF ;
   
   IF  EXISTS
    (
      SELECT * FROM APPOINTMENTS
      WHERE DOCTORID= NEW.DOCTORID AND 
      APPOINTMENTTIME= NEW.APPOINTMENTTIME
      AND STATUS IN ('SCHEDULED')
	) THEN 
    SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT= 'Error: Doctor Already has an appointment  at this time';
   END IF ;
END $$
DELIMITER;

INSERT INTO appointments(appointmentID, pateintID, doctorID, appointmenttime,status)
VALUES(10000,1,1,'2026-01-16 10:00:00', 'Scheduled')

INSERT INTO appointments(appointmentID, pateintID, doctorID, appointmenttime,status)
VALUES(10001,1,1,'2026-01-16 10:00:00', 'Scheduled')

INSERT INTO appointments(appointmentID, pateintID, doctorID, appointmenttime,status)
VALUES(10002,1,1,'2026-01-16 11:00:00', 'Scheduled')


DELIMITER $$
CREATE PROCEDURE  VIEW_DOCTOR_DATA(IN INPUT_USERNAME VARCHAR(100), IN INPUT_PASSWORD VARCHAR(100))
BEGIN 
  DECLARE DOC_ROLE VARCHAR(100);
  DECLARE DOC_DEPT INT;
  DECLARE DOC_ID INT;
  

  SELECT DOCTOR_ID INTO DOC_ID
  FROM  DOCTOR_CREDENTIALS 
  WHERE USER_NAME=INPUT_USERNAME AND PASSWORD=INPUT_PASSWORD;
  
 
  SELECT role , departmentID
  INTO DOC_ROLE, DOC_DEPT
  FROM doctors WHERE doctorID= DOC_ID;
  

  IF DOC_ROLE='senior' THEN
     SELECT D.doctorID,P.patientID, P.name, P.Gender, 
	 A.appointmenttime, PR.medication,LR.reportdata
	 FROM patients AS P INNER JOIN
	 appointments AS A ON A.pateintID=P.patientID
     JOIN DOCTORS  D ON D.doctorID= A.doctorID
	 LEFT JOIN prescriptions AS PR ON A.appointmentID = PR.appointmentID
	 LEFT JOIN labreports AS LR ON A.appointmentID = LR.appointmentID
     WHERE D.departmentID= DOC_DEPT;
  ELSE
    SELECT A.doctorID,P.patientID, P.name, P.Gender, 
	 A.appointmenttime, PR.medication,LR.reportdata
	 FROM patients AS P INNER JOIN
	 appointments AS A ON A.pateintID=P.patientID
	 LEFT JOIN prescriptions AS PR ON A.appointmentID = PR.appointmentID
	 LEFT JOIN labreports AS LR ON A.appointmentID = LR.appointmentID
     WHERE A.doctorID=DOC_ID;
   END IF;
END$$
DELIMITER;

CALL VIEW_DOCTOR_DATA('doctor1','W3jzIANG')
CALL VIEW_DOCTOR_DATA('doctor4','ic0pFSn0')


select * from doctor_credentials

DELIMITER //
CREATE PROCEDURE SP_MONTHLYREVENUE(IN P_YEAR INT , IN P_MONTH INT)
BEGIN
 SELECT D1.name AS DEPARTMENT,
	SUM(B.amount) AS TOTAL_REVENUE 
	FROM bills AS B 
	INNER JOIN appointments AS A ON A.appointmentID=B.appointmentID
	INNER JOIN doctors AS D ON A.doctorID=D.doctorID
	INNER JOIN departments AS D1 ON D1.departmentID=D.doctorID
	WHERE  MONTH(B.billdate)=P_MONTH AND YEAR(B.billdate)=P_YEAR
GROUP BY D1.NAME;
END//
DELIMITER

CALL SP_MONTHLYREVENUE(2025,5)
  
  


