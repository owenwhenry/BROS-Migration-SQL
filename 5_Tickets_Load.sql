Drop Table IF EXISTS Tickets;

SELECT * FROM bros_source;

Create Table Tickets as 
SELECT sf_account_id as AccountID, sf_contact_id as ContactId, sf_opp_id as OpportunityId, sf_campaign_id as CampaignID, ticket_type, date_attending,
FirstName, LastName, amt_paid, email
FROM bros_source;

SELECT * INTO OUTFILE 'C:\\Users\\Owen\\Desktop\\Bros_Salesforce_Load\\Output Files\\Tickets_For_Upload.csv' 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  FROM (
  SELECT 'AccountID', 'ContactID', 'OpportunityID', 'CampaignID', 'Ticket Type', 'Date', 'FirstName', 'LastName', 'Amount', 'Email'
  UNION ALL Select AccountID, ContactID, OpportunityID, CampaignID, ticket_type, date_attending, FirstName, LastName, amt_paid, email from tickets) A;
  
  SELECT ticket_type, count(*) as total FROM tickets group by ticket_type


DROP TABLE IF EXISTS loaded_tickets;

CREATE TABLE loaded_tickets(
Id varchar(50),
Name varchar(50),
Processing_Fees__c varchar(50),
RelatedCampaign__c varchar(50),
Related_Contact__c varchar(50),
Related_Opportunity__c varchar(50),
Ticket_Holder_Email__c varchar(50),
Ticket_Holder_First_Name__c varchar(50),
Ticket_Holder_Last_Name__c varchar(50),
Ticket_Price__c	varchar(50),
Ticket_Type__c varchar(50)
)


LOAD DATA INFILE 'C:\\Users\\Owen\\Desktop\\Bros_Salesforce_Load\\Tickets.csv' INTO TABLE loaded_tickets
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES

SELECT A.*, B.* FROM (SELECT RelatedCampaign__c, count(*) from loaded_tickets group by RelatedCampaign__c order by count(*) DESC) A
LEFT JOIN (
SELECT sf_campaign_id, count(*) from tickets group by sf_campaign_id order by count(*) DESC) B 
ON A.RelatedCampaign__c = B.sf_campaign_id

SELECT A.*, B.* FROM (SELECT Related_Opportunity__c, count(*) from loaded_tickets group by Related_Opportunity__c order by count(*) DESC) A
LEFT JOIN (
SELECT opportunityId, count(*) from tickets group by opportunityId order by count(*) DESC) B 
ON A.Related_Opportunity__c = B.opportunityId

select * from tickets
select * from loaded_tickets

SELECT * from bros_source where sf_opp_id = '006f200001yPiMUAA0';