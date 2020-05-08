/*Before order files can be created,need to have the events/campaigns updated
This is done by create a new table, slapping an autoincremented ID on it for each event name + date attending combo, and 
then updating the source table. I then update the names based on AK's inputs, and create master/child campaign lists. */

/*Step 1 was to create a better list of ID's for these*/
USE bros_migration1;

Drop Table IF EXISTS altered_eventid;

Create Table altered_eventid 
AS 
SELECT DISTINCT event_name, date_attending, eventid 
from bros_source
order by date_attending ASC;

/*quick QA check to make sure this clause will work and have exactly 20945 rows before proceeding

SELECT COUNT(*) from bros_source A inner join altered_eventid B on A.event_name = B.event_name AND A.date_attending = B.date_attending AND A.eventid = B.eventid;

If it does, proceed with table updates to the event id*/
alter table altered_eventid add alteredid INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

UPDATE bros_source A, altered_eventid B set A.eventid = b.alteredid
WHERE A.event_name = B.event_name AND A.date_attending = B.date_attending AND A.eventid = B.eventid;

/*
SELECT * FROM altered_eventid;
*/

/*Create the Campaigns table*/
DROP TABLE IF EXISTS CAMPAIGNS;

CREATE TABLE campaigns (
ID INT,
Show_Master_Name Varchar(80),
show_date varchar(20),
Show_Child_Name Varchar(80)
);

/*This file should have the updated, better show names listed master and child*/

LOAD DATA INFILE 'C:\\Users\\Owen\\Desktop\\Bros_Salesforce_Load\\Input Files\\bros_show_list.csv' into table campaigns
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

/*
SELECT * FROM campaigns;
*/

/*Realized the ID's are broken in the campaigns file - something got mismatched*/
/*This illustrates that the ID's are broken
SELECT * from altered_eventid A INNER JOIN campaigns B on A.eventid = B.id;
*/

/*This illustrates that the date_attending can be used as an ID for both files
SELECT * FROM altered_eventid A INNER JOIN campaigns B on A.date_attending = B.show_date;
*/

UPDATE campaigns A, altered_eventid B
set A.id = B.alteredid 
where B.date_attending = A.show_date;

/*
Select distinct show_master_name from campaigns;

SELECT * INTO OUTFILE 'C:\\Users\\Owen\\Downloads\\bros_migration_child_shows.csv'
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  FROM (SELECT * from campaigns
left Join master_shows on campaigns.Show_Master_Name = master_shows.name) A;
*/
/*I load these campaigns in with the correct parent ID's based on the original master shows file - I then redo the process for a new table based
on a new export from Salesforce that includes all campaigns*/

DROP TABLE IF EXISTS master_child_shows;

CREATE TABLE master_child_shows (
    salesforce_ID varchar(50),
    salesforce_parent_id varchar(50),
	descr varchar(50),
    end_date varchar(25),
    name varchar(100),
    start_date varchar(25),
    venue varchar(50),
    recordtypeid varchar(50),
    isActive int,
    status varchar(25)
    );


LOAD DATA INFILE 'C:\\Users\\Owen\\Desktop\\Bros_Salesforce_Load\\Input Files\\MasterChildShows.csv' into table master_child_shows
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

/*At this point I  realize something's gone wonky with the dates - Start Date and End Date for the child shows is the same as it is
for the master shows. I have to update it based on my campaigns source file, which I do successfully*/
/*
select * from master_child_shows;

select * from campaigns;
*/

Update master_child_shows A, campaigns B set a.start_date = B.show_date, A.end_date = B.show_date where A.name = B.show_child_name;

/*
SELECT * FROM master_child_shows A INNER JOIN campaigns B on A.name = B.show_child_name;

SELECT * FROM master_child_shows A LEFT JOIN campaigns B on A.name = B.show_child_name WHERE b.id is not null;
*/

/*Update the campaigns table I created to add the correct ID's in*/
ALTER TABLE campaigns add master_campaign_id varchar(50);
alter table campaigns add child_campaign_id varchar(50);

/*I did some QA work and realized there's an error with one of the names - update it here.*/
UPDATE master_child_shows set name = '2015 Swanktacular 1' where name = '2015 Swanktacular';

/*These update statements work, but only because we structured the names so uniquely for each child show and master show. 
Check the SELECTS to see what I mean. 
SELECT show_master_name, name from campaigns A left join master_child_shows B on A.show_master_name = B.name;
SELECT show_child_name, name from campaigns A left join master_child_shows B on A.show_child_name = B.name;

SELECT salesforce_ID, name, count(*) from master_child_shows group by salesforce_ID, name;
*/

UPDATE campaigns A, master_child_shows B SET A.master_campaign_id = B.salesforce_ID where A.show_master_name = B.name;
UPDATE campaigns A, master_child_shows B SET A.child_campaign_id = B.salesforce_ID where A.show_child_name = B.name;

/* QA queries to ensure that everything is still associated correctly
SELECT distinct salesforce_parent_id FROM master_child_shows where salesforce_parent_id is not null;
select distinct master_campaign_id from campaigns;

Select Count(distinct master_campaign_id, show_master_name) from campaigns;
Select distinct master_campaign_id, show_master_name from campaigns;
*/
/*At this point my QA is satisfied that I've successfully created a campaigns file, so I set about updating my source file*/

alter table bros_source add sf_campaign_id varchar(50);

UPDATE bros_source A, campaigns B set A.sf_campaign_id = B.child_campaign_id where A.eventid = b.id;

/*
SELECT * FROM bros_source A, campaigns B where A.eventid = b.id and Fullname like 'Owen Henry';
*/

/*Time to create the file that creates campaign membership linking*/

SELECT * INTO OUTFILE 'C:\\Users\\Owen\\Desktop\\Bros_Salesforce_Load\\Output Files\\bros_migration_campaign_members.csv'
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  FROM  (SELECT DISTINCT sf_campaign_id, sf_contact_id from bros_source) A;
