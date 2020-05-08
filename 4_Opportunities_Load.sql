USE bros_migration1;

DROP TABLE IF EXISTS Orders;

/*This is the query I originally tried to use. It fails because there are too many rows with an orderid of 0 in the source file*/
SELECT COUNT(*) FROM (SELECT sf_contact_id, sf_account_id, sf_campaign_id, orderid, FullName, Amt_Paid, date_attending, ticket_type, "Ticket Sale" as opp_name, "Closed" as stage_name
FROM bros_source
Group by sf_campaign_id, orderid) A;

/*This is the query I am now using. It looks at unique instances of orders for a contact within a campaign.
The one instance in which this falls down is if there are multiple rows where the orderid is 0 for a given contact/campaign combination, 
but to be frank I don't know what to do about that*/
SELECT COUNT(*) FROM (SELECT sf_contact_id, sf_account_id, sf_campaign_id, orderid, FullName, Amt_Paid, date_attending, ticket_type, "Ticket Sale" as opp_name, "Closed" as stage_name
FROM bros_source
Group by sf_account_id, sf_campaign_id, orderid, date_attending) A;

Create Table Orders as
SELECT sf_account_id as AccountId, orderid, sf_campaign_id as CampaignId, Amt_Paid as Amount, 
date_attending as Date, ticket_type as Description, "Ticket Sale" as Name, 
"Closed" as stage_name, '012f200000120S2AAI' as RecordTypeID
FROM bros_source
GROUP BY sf_contact_id, sf_campaign_id, orderid, date_attending;

/*The original order ID's are such a mess that I need to update them*/

ALTER TABLE Orders Drop Column OrderID;
alter table orders add orderid INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

Select * from orders;

SELECT * INTO OUTFILE 'C:\\Users\\Owen\\Desktop\\Bros_Salesforce_Load\\Output Files\\Opportunities.csv'
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
FROM (
	SELECT 'AccountId', 'OrderID', 'CampaignId', 'Amount', 'Date', 'Description', 'Name', 'stage_name', 'RecordTypeID'
    UNION ALL Select AccountID, orderid, CampaignID, Amount, Date, Description, Name, stage_name, RecordTypeID from Orders) A;
    

ALTER TABLE bros_source add sf_opp_id varchar(50);
alter table orders add sf_opp_id varchar(25);

drop table if exists sf_opps;

Create Table sf_opps(
	sf_opp_id varchar(50),
    AccountId varchar(50),
    orderid INT,
    sf_campaign_id varchar(50),
    Amt_Paid Varchar(15),
    date_attending varchar(25),
    ticket_type varchar(50),
    name varchar(11),
    stage_name varchar(6),
    RecordTypeID varchar(25),
    status varchar(25)
    );
    
LOAD DATA INFILE 'C:\\Users\\Owen\\Desktop\\Bros_Salesforce_Load\\opps_success_file.csv' INTO TABLE sf_opps
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT COUNT(*) FROM bros_source A LEFT JOIN sf_orders B on A.orderid = B.orderid;

Update orders A, sf_opps B SET A.sf_opp_id = B.sf_opp_id where A.orderid = B.orderid;

SELECT * FROM bros_source where sf_account_id = '001f200001m0Wm4AAE'

UPDATE orders set accountid = '001f200001m0WokAAE' where accountid = '001f200001m0Wm4AAE'

SELECT * from orders where sf_opp_id is null;

UPDATE bros_source A, orders B SET A.sf_opp_id = B.sf_opp_id WHERE (A.sf_account_id = b.accountid and a.sf_campaign_id = b.campaignid and a.date_attending = b.date)

SELECT COUNT(*) from bros_source A inner join orders B on (A.sf_account_id = b.accountid and a.sf_campaign_id = b.campaignid and a.date_attending = b.date)