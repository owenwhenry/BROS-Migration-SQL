/* Source File Load script*/

DROP SCHEMA IF EXISTS BROS_Migration1;

CREATE SCHEMA BROS_Migration1;

USE BROS_Migration1;

DROP TABLE IF EXISTS bros_source;

Create Table bros_source (
pkey INT AUTO_INCREMENT,
source_file VARCHAR(255),
SaleDate VARCHAR(255),
BillingName VARCHAR(255),
BillingFirst VARCHAR(255),
BillingLast VARCHAR(255),
PurchasedBy VARCHAR(255),
PatronName VARCHAR(255) ,
FullName VARCHAR(255),
FirstName VARCHAR(255),
MiddleName VARCHAR(255),
LastName VARCHAR(255),
Email VARCHAR(255),
Quantity varchar(5),
Ticket_Type VARCHAR(255),
EventId BIGINT,
OrderId BIGINT,
OrderType VARCHAR(255),
Company VARCHAR(255),
Address_Line_1 VARCHAR(255),
Addresss_Line_2 VARCHAR(255),
City VARCHAR(255),
State VARCHAR(255),
Zip varchar(5),
Phone_Type VARCHAR(255),
Phone VARCHAR(255),
Attendee_Status VARCHAR(255), 
Venue_Name VARCHAR(255),
date_attending VARCHAR(255), 
Event_Name VARCHAR(255), 
Payment_Channel VARCHAR(255), 
Amt_Paid FLOAT,  
Payment_Method VARCHAR(255), 
fees1 varchar(6), 
fees2 varchar(6), 
Discount VARCHAR(255), 
how_heard VARCHAR(255), 
notes VARCHAR(255), 
venue_name_2 VARCHAR(255),
PRIMARY KEY (pkey));

/*This file is the main file of Tixato data that was cleaned by Greg*/

LOAD DATA INFILE 'C:\\Users\\Owen\\Desktop\\Bros_Salesforce_Load\\Input Files\\bros_data.csv' INTO TABLE BROS_SOURCE
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(source_file, SaleDate, BillingName, BillingFirst, BillingLast, PurchasedBy, PatronName, FullName, FirstName,
MiddleName, LastName, Email, Quantity, Ticket_Type, EventId, OrderId, OrderType, Company,
Address_Line_1, Addresss_Line_2, City, State, Zip, Phone_Type, Phone, Attendee_Status, Venue_Name,
Date_Attending, Event_Name, Payment_Channel, Amt_Paid,  Payment_Method, fees1, fees2, 
Discount, how_heard, notes, venue_name_2);

/*Quick data cleanup tasks before going any further*/
UPDATE bros_source set ticket_type = 'General Admission - Dual Member' where ticket_type = 'General Admission Ã¯Â¿Â½Ã¯Â¿Â½Ã¯Â¿Â½ Duel Member';
UPDATE bros_source set ticket_type = 'General Admission - Solo Member' where ticket_type = 'General Admission Ã¯Â¿Â½Ã¯Â¿Â½Ã¯Â¿Â½ Solo Member';
UPDATE bros_source set ticket_type = 'General Admission - Squad Member' where ticket_type = 'General Admission Ã¯Â¿Â½Ã¯Â¿Â½Ã¯Â¿Â½ Squad Member';
UPDATE bros_source set ticket_type = 'Supporter Seat - Dual Member' where ticket_type = 'Supporter Seat Ã¯Â¿Â½Ã¯Â¿Â½Ã¯Â¿Â½ Duel Member';
UPDATE bros_source set ticket_type = 'Supporter Seat - Squad Member' where ticket_type = 'Supporter Seat Ã¯Â¿Â½Ã¯Â¿Â½Ã¯Â¿Â½ Squad Member';


/*Ticket Types*/
UPDATE bros_source set ticket_type = 'Complimentary Admission' where ticket_type in ('Free Volunteer Comp!!', 'Friend of BROS', 
'Other Comps', 'Sponsor Comp', 'Donor Comp', 'Press Comp', 'Comp', 'Comp 9/17',  'Press / Comp', 'Press / Media Comp' );

UPDATE bros_source set ticket_type = 'Volunteer Admission' where ticket_type in ('BROS Volunteer', 'Amphion Volunteer Comp', 'CH Volunteer Full',
'CH Volunteer Half', 'Volunteer Coupons' );

UPDATE bros_source set ticket_type = 'General Admission' where ticket_type in (' ', 'Admission', 'At The Door', 'Brotest', 'Cosmic Nectar: Admission for One Guest',
'Day of Door','DC Friday Show', 'General Admission - Dual Member', 'General Admission - Solo Member', 'General Admission - Squad Member', 'Individual',
'Main Event', 'Onsite General Admission', 'Regular', 'Regular Admission', 'Transfer', 'Waitlist GA', 'Door Admission' );

UPDATE bros_source set ticket_type = 'Discounted Admission' where ticket_type in ('AMPH BROS Discount 6/10', 
'AMPH BROS Discount 6/24', 'AMPH BROS Discount 6/25', 'AMPH BROS Discount 6/26', 'Amphion BOGO', 'BROS Discount', 'Creative Ally: 25% off Main Event',
'Early Bird', 'GBCA Culture Fly', 'General admission SUNDAYFUNDAY coupon', 'Half-Price 1st Sunday: Online-only', 'Plays & Players Discount', 
'Rock Operative Discounted Main Event', 'Senior / Sunday Discount' );

UPDATE bros_source set ticket_type = 'Discounted Admission' where ticket_type like 'CH BROS Discount%';

UPDATE bros_source set ticket_type = 'Donor Admission' where ticket_type in ('BROS Donor Tickets', 'Donation to support the BROS Forever Home');

UPDATE bros_source set ticket_type = 'Supporter Admission' where ticket_type in ('BROS Supporter!', 'BROS Season Pass: Jimmy Wylie', 
'BROS Supporter', 'BROS Viewing Party', 'Afterparty Only!', 'Court of the Old King', 'Get Felt Up Table', 'Karaoke Party!', 'Mega Supporter Seat',
'Minotaur Supporter Level', 'Pegacorn Supporter Level', 'Stardust Lazerdong MegaFan!!!', 'Supporter Seat', 'Supporter Seat - Dual Member', 'Supporter Seat - Free',
 'Supporter Seat - Squad Member', 'Supporter Seats', 'Supporter Upgrade' );

UPDATE bros_source set ticket_type = 'VIP Admission' where ticket_type in ('BROS VIP Tickets', 'Full Swank!', 'Rock Operative Discounted VIP Hour + Main Event',
'VIP Hour + Main Event', 'VIP Supporter Seat');

UPDATE bros_source set ticket_type = 'Member Admission' where ticket_type in ('BROS Member Discounted');

/*Create an index - will need it*/
CREATE INDEX idx_email on bros_source(email);

SELECT * FROM bros_source;

