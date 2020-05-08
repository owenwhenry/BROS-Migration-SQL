USE BROS_Migration1;

DROP TABLE IF EXISTS Contacts ;

CREATE TABLE Contacts (
	FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(50),
    Address_Line_1 VARCHAR(50),
    Addresss_Line_2 VARCHAR(50),     
	City VARCHAR(50),
    State VARCHAR(50),
    Zip VARCHAR(50),
    Phone VARCHAR(50));

/* This query finds, for each email, the first name+last name combinations with the highest total count. This is neccesary because in the ticket files,
the ticket buyer's email is appended to the tickets of his guests. Often, people who come to shows are repeat ticket buyers, so their name+email
combination shows up multiple times in the file. */

/*Just a demonstration of the fact that it works well, unless you're aran who has an interesting name issue going on
SELECT FirstName, LastName, Email, Count(*) as Total_records
	FROM bros_source
    where email like '%aran%'
	GROUP BY FirstName, LastName, Email;

SELECT 
	FirstName, LastName, Email
FROM (
	SELECT FirstName, LastName, Email, Count(*) as Total_records
	FROM bros_source
	GROUP BY FirstName, LastName, Email ) A 
WHERE Total_Records = 
	(
	SELECT MAX(Total_records) 
	FROM 
		(
		SELECT FirstName, LastName, Email, Count(*) as Total_records
		FROM bros_source
		GROUP BY FirstName, LastName, Email 
		) B
	Where A.Email = B.Email
        )
AND email like '%aran%'
Group by Email;
*/

INSERT INTO contacts 
	(FirstName, LastName, Email) 
SELECT 
	FirstName, LastName, Email
FROM (
	SELECT FirstName, LastName, Email, Count(*) as Total_records
	FROM bros_source
	GROUP BY FirstName, LastName, Email ) A 
	WHERE Total_Records = 
		(
        SELECT MAX(Total_records) 
		FROM 
			(
            SELECT FirstName, LastName, Email, Count(*) as Total_records
			FROM bros_source
			GROUP BY FirstName, LastName, Email 
			) B
		Where A.Email = B.Email
        )
Group by Email;

CREATE INDEX idx_email on contacts(email);

Update contacts set Firstname = 'Aran', Lastname = 'Keating' where email= 'aran@baltimorerockopera.org';

/*Some quick QA queries. Should return 0 to demonstrate that there's no emails missing
SELECT count(*) from bros_source 
LEFT JOIN contacts
on bros_source.email = contacts.email
where contacts.email is null;

Should return 0 to demonstrate that there's no emails missing
SELECT count(*) from contacts 
LEFT JOIN bros_source
on contacts.email = bros_source.email
where bros_source.email is null;
*/
/* More QA - upper query should show counts greater than 1 because it's the tickets file, 
while lower query should show no counts greater than 1 because it's just contacts 
SELECT FirstName, LastName, email, count(*) from bros_source group by FirstName, LastName, email order by count(*) desc;
SELECT FirstName, LastName, email, count(*) from contacts group by FirstName, LastName, email order by count(*) desc;


SELECT * from contacts where email like '%aran%';
SELECT * from bros_source where email like '%aran%';
SELECT * from sf_id_contacts where email like '%aran%';
*/

/* Update the source file with the names from the contacts file */
UPDATE bros_source A, contacts B set A.Firstname = B.Firstname, A.Lastname = B.Lastname where A.email = B.email;

/*Now - to get the best address. I want the address from their most recent sale where they provided an address line 1, 
which this query provides and then uses to update contacts*/
DROP TABLE IF EXISTS best_addresses;

CREATE TEMPORARY TABLE best_addresses SELECT * FROM (
Select t1.email, t2.mxdate, t1.date_attending, t1.address_line_1, t1.Addresss_Line_2, t1.city, t1.state, t1.zip
from bros_source t1
inner join
(
  select max(date_attending) mxdate, address_line_1, email
  from bros_source t2
  where address_line_1 is not null
  and address_line_1 not like ''
  group by email
) t2
  on t1.email = t2.email
  and t1.date_attending = t2.mxdate
  GROUP BY t1.email, t2.mxdate, t1.date_attending, t1.address_line_1, t1.Addresss_Line_2, t1.city, t1.state, t1.zip
) A group by email order by address_line_1 desc;

/* 
select * from best_addresses group by email order by address_line_1 desc;

Now I use it to update my contacts table*/

Update contacts A, best_addresses B
SET  
	A.Address_Line_1= B.Address_Line_1,
    A.Addresss_Line_2 = B.Addresss_Line_2,
    A.City = B.City,
    A.State = B.State,
    A.Zip = B.Zip
WHERE A.Email = B.email;

/*Do the same thing shit for phones - find the most recent one that's not null*/

DROP TABLE IF EXISTS best_phones;

CREATE TEMPORARY TABLE best_phones Select t1.email, t2.mxdate, t1.date_attending, t1.phone
from bros_source t1
inner join
(
  select max(date_attending) mxdate, phone, email
  from bros_source t2
  where phone is not null
  and phone not like ''
  group by email
) t2
  on t1.email = t2.email
  and t1.date_attending = t2.mxdate;

Update contacts A, best_phones B
SET  
	A.phone = B.phone
WHERE A.Email = B.email;  
		
/*Update the contacts file with the correct names from the additional data provided by Kim.
Before being entered, the file was de-duped on email, last names were filled in with "Unknown" as 
necessary, and anyone with "Anonymous" as their first name had that value replaced with "Unknown".
*/
DROP TABLE IF EXISTS add_contacts;

CREATE TEMPORARY TABLE add_contacts (
email VARCHAR(50),
FirstName VARCHAR(25),
LastName VarChar(25)
);

LOAD DATA INFILE 'C:\\Users\\Owen\\Desktop\\Bros_Salesforce_Load\\Input Files\\bros_add_contacts.csv' INTO  TABLE add_contacts
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n';

/*Update the first names if they aren't bad data*/

Update contacts A, add_contacts B
set A.Firstname = B.Firstname
where A.Email=B.Email
and B.Firstname not in ('Anonymous', 'Unknown', '');

Update contacts A, add_contacts B
set A.Lastname = B.Lastname
where A.Email=B.Email
and B.Lastname not in ('Anonymous', 'Unknown', '');

/*Only insert contacts from the add_contacts table if they weren't in the original contacts file for some reason */
Insert Into Contacts (FirstName, LastName, Email)
SELECT A.FirstName, A.LastName, A.Email FROM add_contacts A
Left JOIN contacts C
on C.email = A.email
Where c.email IS NULL;

/*With the contacts file completed, update the source table based on the email.*/
Update 
	bros_source A, contacts B 
SET
	A.FirstName = B.Firstname,
    A.Lastname = B.Lastname,
	A.Address_Line_1= B.Address_Line_1,
    A.Addresss_Line_2 = B.Addresss_Line_2,
    A.City = B.City,
    A.State = B.State,
    A.Zip = B.Zip,
    A.Phone = B.Phone
WHERE 
	A.Email = B.email;

/*Create the file that goes out to Salesforce to be uploaded 

SELECT * INTO OUTFILE 'C:\\Users\\Owen\\Desktop\\Bros_Salesforce_Load\\Output Files\\Contacts_To_Load.csv'
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  FROM contacts;
*/
/*I loaded those contacts in to Salesforce and it kicked me back a file with the ID of every record I loaded. 
I'm now going to load and append those ID's to my tables*/

DROP TABLE IF EXISTS sf_id_contacts;

CREATE TABLE sf_id_contacts(
	sf_contact_id varchar(100),
    sf_account_id varchar(100),
    email varchar(100),
    LastName varchar(25), 
    FirstName varchar(25)
);

create index idx_email on sf_id_contacts(email);

LOAD DATA infile 'C:\\Users\\Owen\\Desktop\\Bros_Salesforce_Load\\Input Files\\Contacts_AccountID_ContactID_Email.csv' into table sf_id_contacts
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

alter table bros_source add sf_contact_id varchar(100);
alter table contacts add sf_contact_id varchar(100);
alter table bros_source add sf_account_id varchar(50);
alter table contacts add sf_account_id varchar(50);

/* This shows I have 6116 contacts in my original file. These are all the people who bought tickets
SELECT COUNT(DISTINCT Firstname, LastName, Email) from bros_source;*/

/* This shows I have 6552 contacts in my contacts file.
This is different from the count in my source file because it has the additional contacts in it
SELECT COUNT(DISTINCT Firstname, LastName, Email) from contacts;*/

/*check out the contacts that don't appear in the source file.
There are 436 of them. 436 is exactly the number of rows inserted from
the additional contacts file
SELECT COUNT(A.Email) from contacts A
LEFT JOIN bros_source B
on a.email = b.email
where b.email is null;
*/
/*This shows I have 6543 contacts in my file, which is less than the original file 
SELECT COUNT(DISTINCT Firstname, LastName, Email) from sf_id_contacts;*/

/*Therefore, the contact load SHOULD have been A-OK...*/

/*Check out the people in SF who aren't in my current contacts file.
Must have been entered by Kim during membership updates
SELECT * from sf_id_contacts A
left join contacts B
on A.email = b.email
where b.email is null;
*/


/*Let's see how many distinct emails I have on each file. It's close but there's about 10 contacts missing from SF
SELECT COUNT(Distinct email) from bros_source;
SELECT COUNT(Distinct email) from sf_id_contacts;
SELECT COUNT(Distinct email) from contacts;
*/

/*Put the Salesforce ID# on my contacts file*/
UPDATE contacts, sf_id_contacts 
set contacts.sf_contact_id = sf_id_contacts.sf_contact_id, contacts.sf_account_id = sf_id_contacts.sf_account_id
where contacts.email = sf_id_contacts.email;

/*Check the output

Select A.FirstName, A.LastName, A.Email, B.FirstName, B.Lastname, B.Email
FROM contacts A
LEFT JOIN sf_id_contacts B
on A.Email = B.Email
where A.Firstname != B.Firstname;

SELECT * from Contacts where email = 'aran@baltimorerockopera.org';
*/

/*provided everything looks good, update my source file from my contacts file*/
UPDATE bros_source, contacts 
set bros_source.sf_contact_id = contacts.sf_contact_id, bros_source.sf_account_id = contacts.sf_account_id
where bros_source.email = contacts.email;

SELECT * from contacts;

select * from bros_source;
