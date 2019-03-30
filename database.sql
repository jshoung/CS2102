-- delete tables if already exists
DROP TABLE IF EXISTS UserAccount CASCADE;
DROP TABLE IF EXISTS Report CASCADE;
DROP TABLE IF EXISTS Writes CASCADE;
DROP TABLE IF EXISTS reportee CASCADE;
DROP TABLE IF EXISTS InterestGroup CASCADE;
DROP TABLE IF EXISTS Joins CASCADE;
DROP TABLE IF EXISTS OrganizedEvent CASCADE;
DROP TABLE IF EXISTS UserReviewItem CASCADE;
DROP TABLE IF EXISTS Upvote CASCADE;
DROP TABLE IF EXISTS Advertisement CASCADE;
DROP TABLE IF EXISTS Loaner CASCADE;
DROP TABLE IF EXISTS Borrower CASCADE;
DROP TABLE IF EXISTS LoanerItem CASCADE;
DROP TABLE IF EXISTS InvoicedLoan CASCADE;
DROP TABLE IF EXISTS Bid CASCADE;
DROP TABLE IF EXISTS Chooses CASCADE;

-- user is a superclass, and a user has to be either a loaner or borrower, and can be both
create table UserAccount(
	userID integer,
	name varchar(80) not null,
	address varchar(80) not null,
	primary key (userID)
);


-- if the reporter's value is set to null, then we know that the reporter's account has been deleted.
-- if the reportee's account is deleted, reports against him/her will also be deleted.
create table Report(
	reportID integer,
	title varchar(1000) not null,
	reportDate date not null,
	reason varchar(10000),
	reporter integer,
	reportee integer,
	primary key (reportID),
	foreign key (reporter) references UserAccount (userID) on delete set null,
	foreign key (reportee) references UserAccount (userID) on delete cascade,
	check (reporter != reportee)
);

create table InterestGroup(
	groupName varchar(80),
	groupDescription varchar(10000),
	primary key (groupName)
);

-- (userID, groupName) is the primary key because each user can only join each group once.  
-- if either the user or the group is deleted, the 'Join' entry is deleted.
create table Joins(
	joinDate date not null,
	userID integer,
	groupName varchar(80),
	primary key (userId, groupName),
	foreign key (userID) references UserAccount (userID) on delete cascade,
	foreign key (groupName) references InterestGroup (groupName) on delete cascade
);

-- if the interest group is deleted, then the entries into organizedEvent is also deleted.
create table OrganizedEvent(
	eventID integer,
	eventDate date not null,
	venue varchar(80) not null,
	organizer varchar(80),
	primary key (eventID),
	foreign key (organizer) references InterestGroup (groupName) on delete cascade
);


create table Loaner(
	userID integer references UserAccount on delete cascade,
	primary key (userID)
);

create table Borrower(
	userID integer references UserAccount on delete cascade,
	primary key (userID)
);

create table LoanerItem(
	itemID integer,
	itemName varchar(80) not null,
	value integer not null,
	itemDescription varchar(10000),
	userID integer,
	primary key (userID, itemID),
	foreign key (userID) references Loaner (userID) on delete cascade
);

--we would like the ratings to be between 0 and 5
--users are ony allowed to review an item if they have used that particular item before
--these constraints are enforced in triggers
create table UserReviewItem(
	userID integer,
	itemID integer,
	itemOwnerID integer,
	reviewID integer,
	reviewComment varchar(1000),
	reviewDate date not null,
	rating integer not null,
	primary key (reviewID),
	foreign key (userID) references UserAccount (userID) on delete set null,
	foreign key (itemOwnerID, itemID) references LoanerItem on delete cascade
);

--Upvotes
--when either the userAccount that upvoted, or the review deleted, the upvote will be deleted.
create table Upvote(
	userID integer,
	reviewID integer,
	primary key (userID,reviewID),
	foreign key (userID) references UserAccount(userID) on delete cascade,
	foreign key (reviewID) references UserReviewItem(reviewID) on delete cascade
);


-- perhaps a trigger can update the highest bidder and the highest bid, after a bid as been made to a adverstisement entry
create table Advertisement(
	advID integer,
	highestBidder integer,
	minimumPrice integer not null,
	openingDate date not null,
	closingDate date not null,
	minimumIncrease integer not null,
	highestBid integer,
	advertiser integer,
	itemID integer,
	primary key (advID),
	foreign key (advertiser) references Loaner(userID) on delete cascade,
	foreign key (advertiser, itemID) references LoanerItem(userID, itemID) on delete cascade
);


create table Bid(
	bidID integer,
	price integer not null,
	borrowerID integer,
	advID integer,
	primary key (bidID),
	foreign key (borrowerID) references Borrower (userID) on delete cascade,
	foreign key (advID) references Advertisement (advID) on delete cascade
);

create table Chooses(
	bidID integer unique,
	userID integer not null,
	advID integer unique,
	primary key (userID, bidID, advID),
	foreign key (bidID) references Bid (bidID) on delete cascade,
	foreign key (userID) references Loaner (userID) on delete cascade,
	foreign key (advID) references Advertisement (advID) on delete cascade
);

--currently startdate can be after end date
create table InvoicedLoan(
	startDate date not null,
	endDate date not null,
	penalty integer not null,
	loanFee integer not null,
	loanerID integer not null,
	borrowerID integer not null,
	invoiceID integer,
	itemID integer,
	foreign key (loanerID)references Loaner (userID) on delete cascade,
	foreign key (borrowerID) references Borrower (userID) on delete cascade,
	foreign key (loanerID, itemID) references LoanerItem (userID, itemID) on delete cascade,
	primary key (invoiceID)
);


create or replace function checkReportYourself()
returns trigger as
$$
begin
	if (new.reporter = new.reportee) then
		raise notice 'You cannot report yourself';
		return null;
	else 
		return new;
	end if;
end
$$
language plpgsql;

create trigger trig1CheckSelfReport
before update or insert on Report
for each row
execute procedure checkReportYourself();


create or replace function checkMinimumIncrease()
returns trigger as 
$$
declare adMinimumIncrease integer;
		previousHighestBid integer;
		adMinimumPrice integer;
begin
	select highestBid into previousHighestBid 
	from Advertisement
	where advID = new.advID;

	select minimumIncrease into adMinimumIncrease
	from Advertisement
	where advID = new.advID;

	select minimumPrice into adMinimumPrice
	from Advertisement
	where advID = new.advID;
	
	if (previousHighestBid is null and new.price < adMinimumPrice) then 
		raise notice 'You have to at least bid the minimum price';
		return null;
	elsif (previousHighestBid is not null and new.price < previousHighestBid + adMinimumIncrease) then 
		raise notice 'You have to at least bid the highest bid price, plus the minimum increase';
		return null;
	else 
		return new; 

	end if;
end
$$
language plpgsql;

create trigger trig1MinimumBidIncreaseTrig
before update or insert on Bid
for each row
execute procedure checkMinimumIncrease();


create or replace function updateHighestBidder()
returns trigger as
$$
begin
	update Advertisement
	set highestBid = new.price,
		highestBidder = new.borrowerID
	where advID = new.advID;
	return new;
end
$$
language plpgsql;

create trigger trig2UpdateHighestBidderTrig
before update or insert on Bid
for each row 
execute procedure updateHighestBidder();


create or replace function checkUnableToBidForYourOwnAdvertisement()
returns trigger as 
$$
declare originalAdvertiser integer;
begin
	select advertiser into originalAdvertiser from Advertisement where advID = new.advID;
	if (new.borrowerID = originalAdvertiser) then 
		raise notice 'You cannot bid for your own advertisements';
		return null;
	else 
		return new;
	end if;
end
$$
language plpgsql;

create trigger trig3CheckUnableToBidForYourOwnAdvertisement
before update or insert on Bid
for each row 
execute procedure checkUnableToBidForYourOwnAdvertisement();


create or replace function checkChoosesYourOwnAdvertisementAndCorrectBid()
returns trigger as 
$$
declare creatorID integer;
begin 
	select advertiser into creatorID
	from Advertisement
	where advID = new.advID;

	if (new.userID != creatorID) then 
		raise notice 'creator ID is %', creatorID;
		raise notice 'You can only choose bids that you created the advertisements for';
		return null;
	elsif new.bidID not in (select bidID from Bid where advID = new.advID) then 
		raise notice 'You can only choose the bids for your own advertisement';
		return null;
	else 
		return new;
	end if;
end
$$
language plpgsql;

create trigger trig1CheckChoosesYourOwnAdvertisementAndCorrectBid
before update or insert on Chooses
for each row 
execute procedure checkChoosesYourOwnAdvertisementAndCorrectBid();


--should only be able to review AFTER you have made a loan
create or replace function checkReviewAfterLoan()
returns trigger as 
$$
declare earliestLoanDate date;
begin
	select min(startDate) into earliestLoanDate
	from InvoicedLoan
	where new.userID = borrowerID and new.itemOwnerID = loanerID and new.itemID = itemID;

	if (earliestLoanDate is null or earliestLoanDate > new.reviewDate) then 
		raise notice 'You have to use the item first before reviewing it';
		return null;
	else 
		return new;
	end if;
end
$$
language plpgsql;

create trigger trig1CheckReviewAfterLoan
before update or insert on UserReviewItem
for each row
execute procedure checkReviewAfterLoan();


create or replace function checkProperRating()
returns trigger as 
$$
begin
	if (new.rating < 0 or new.rating > 5) then 
		raise notice 'ratings have to be between 0 and 5';
		return null;
	else 
		return new;
	end if;
end
$$
language plpgsql;

create trigger trig2CheckProperRating
before update or insert on UserReviewItem
for each row 
execute procedure checkProperRating();


create or replace function checkLoanDateClash()
returns trigger as
$$
declare
begin
	if (select max(invoiceID) from InvoicedLoan where new.startDate >= startDate and new.startDate <= endDate and new.loanerID = loanerID and new.itemID = itemID) is not null then 
		raise notice  'You cannot begin a loan when that item is on loan during that time';
		return null;
	elsif (select max(invoiceID)from InvoicedLoan where new.endDate >= startDate and new.endDate <= endDate and new.loanerID = loanerID and new.itemID = itemID) is not null then 
		raise notice 'You cannot have an item on loan when that item is on loan to someone else during that time';
		return null;
	else
		return new;
	end if;
end
$$
language plpgsql;

create trigger trig1CheckInvoicedLoanClash
before update or insert on InvoicedLoan
for each row
execute procedure checkLoanDateClash();


create or replace function checkLoanYourOwnItem()
returns trigger as
$$
begin 
	if (new.loanerID = new.borrowerID) then 
		raise notice 'You cannot make a loan on your own item';
		return null;
	else 
		return new;
	end if;
end
$$
language plpgsql;

create trigger trig1CheckLoanYourOwnItem
before update or insert on InvoicedLoan 
for each row 
execute procedure checkLoanYourOwnItem();


create or replace function checkStartDateEqualsOrAfterEndDate()
returns trigger as
$$
begin 
	if (new.startDate > new.endDate) then 
		raise notice 'Start date cannot be after the end date';
		return null;
	else 
		return new;
	end if;
end
$$
language plpgsql;

create trigger trig2CheckStartAndEndDateOfLoan
before update or insert on InvoicedLoan 
for each row 
execute procedure checkStartDateEqualsOrAfterEndDate();


create or replace function checkOpeningDateEqualsOrAfterClosingDate()
returns trigger as
$$
begin 
	if (new.openingDate > new.closingDate) then 
		raise notice 'Opening date cannot be after the closing date';
		return null;
	else 
		return new;
	end if;
end
$$
language plpgsql;

create trigger trig1CheckStartAndEndDateOfAdvertisement
before update or insert on Advertisement 
for each row 
execute procedure checkOpeningDateEqualsOrAfterClosingDate();


create  or replace function checkMinimumIncreaseIsGreaterThanZero()
returns trigger as 
$$
begin
	if (new.minimumIncrease <= 0) then 
		raise notice 'Minimum Increase of the bid in an advertisement should be greater than zero';
		return null;
	else
		return new;
	end if;
end
$$
language plpgsql;

create trigger trig2CheckMinimumIncreaseIsGreaterThanZero
before update or insert on Advertisement
for each row 
execute procedure checkMinimumIncreaseIsGreaterThanZero();





--userID from 1 to 100 inclusive
INSERT INTO UserAccount (userID,name,address) VALUES (1,'Emerson Franks','5596 Convallis Rd.'),(2,'Linus Lyons','Ap #537-6165 Sed Road'),(3,'Blake Garrison','542-8114 Est. Rd.'),(4,'Rafael Brewer','Ap #343-8632 Elementum Av.'),(5,'Hermione Lancaster','P.O. Box 790, 1566 Sed St.'),(6,'Allegra Colon','Ap #322-7444 Odio. Rd.'),(7,'Nissim Duffy','8965 Amet Road'),(8,'Fritz Hill','Ap #838-2145 Rhoncus Avenue'),(9,'Destiny Chambers','Ap #231-3514 Enim Street'),(10,'Sacha Moreno','P.O. Box 468, 8943 Ipsum St.');
INSERT INTO UserAccount (userID,name,address) VALUES (11,'Sybil Bishop','886-2408 Tellus. St.'),(12,'Fay Nixon','125-1506 Leo. Ave'),(13,'Aristotle Riddle','4601 Aptent Ave'),(14,'Dustin Orr','3090 Phasellus Ave'),(15,'Madeson Wilcox','202-447 Ac Street'),(16,'Erich Gonzales','280-3274 Fusce Road'),(17,'Arthur Browning','9562 Mollis. St.'),(18,'Mark Brewer','P.O. Box 400, 7887 Elementum Street'),(19,'Serena Rocha','Ap #881-7762 Nisl Road'),(20,'Macaulay Spencer','Ap #113-8073 Enim. Rd.');
INSERT INTO UserAccount (userID,name,address) VALUES (21,'Elmo Hickman','700-1435 Fringilla Avenue'),(22,'Rinah Glover','Ap #790-2787 Quam Road'),(23,'Laith Holman','5630 Et Ave'),(24,'Jin Mosley','P.O. Box 738, 7162 Semper Av.'),(25,'Felix Durham','870-2557 Egestas Road'),(26,'Peter Blackburn','9246 Dignissim. St.'),(27,'Kareem Velasquez','974-7517 Urna, Rd.'),(28,'Venus Calhoun','257-5555 Arcu St.'),(29,'Carl Holcomb','Ap #125-7409 Mauris. Street'),(30,'Deirdre George','P.O. Box 129, 4964 Vehicula St.');
INSERT INTO UserAccount (userID,name,address) VALUES (31,'Magee Booker','4086 Sapien. Ave'),(32,'Ali Osborne','P.O. Box 940, 745 Velit Street'),(33,'Kaden Rasmussen','P.O. Box 512, 5295 Ridiculus St.'),(34,'Kato French','430-5466 Mauris Rd.'),(35,'Kelly Glenn','P.O. Box 463, 5738 Vel St.'),(36,'Kalia Alexander','Ap #341-3183 Tincidunt Avenue'),(37,'Fallon Bond','944-7112 Ut Rd.'),(38,'Amal Chapman','304-2492 Sit Rd.'),(39,'Chancellor Mcclain','Ap #758-6344 A, Road'),(40,'Beck Tyler','Ap #851-5033 Magna. Rd.');
INSERT INTO UserAccount (userID,name,address) VALUES (41,'Destiny Serrano','7372 Sed Avenue'),(42,'Lucas Fuller','8498 Ante, Street'),(43,'Ariana Peters','P.O. Box 101, 1520 Massa Rd.'),(44,'Akeem Morton','P.O. Box 623, 4017 Consectetuer Rd.'),(45,'Wayne Christian','544-8345 Ipsum St.'),(46,'Rina Robinson','1651 Tempus, Rd.'),(47,'Thaddeus Jones','Ap #241-9228 Lacus St.'),(48,'Todd Palmer','Ap #656-3473 Nibh. Avenue'),(49,'Dorothy Pierce','P.O. Box 112, 6161 Pede Road'),(50,'Demetrius Rodriguez','Ap #917-4185 Morbi Road');
INSERT INTO UserAccount (userID,name,address) VALUES (51,'Sybil Short','P.O. Box 989, 2185 Fusce Rd.'),(52,'Odysseus Rosario','P.O. Box 287, 9314 Dictum. St.'),(53,'Jeanette Robles','874-8968 Sollicitudin St.'),(54,'Hector Rhodes','Ap #395-873 Et Road'),(55,'Jael Puckett','Ap #525-4393 Aliquam Ave'),(56,'Blaze Le','Ap #675-442 Id, Av.'),(57,'Denton Yates','Ap #411-810 Consectetuer St.'),(58,'Fallon Rojas','4633 Facilisis Rd.'),(59,'Clark House','P.O. Box 575, 3468 Parturient Avenue'),(60,'Xerxes Anderson','Ap #228-8343 Tempus Av.');
INSERT INTO UserAccount (userID,name,address) VALUES (61,'Orla Kent','Ap #515-8520 Erat Road'),(62,'Kevin Reeves','770-2553 Gravida Avenue'),(63,'Lucas Parks','P.O. Box 402, 3916 Est. Avenue'),(64,'Noble Briggs','P.O. Box 869, 3517 Dolor. Ave'),(65,'Dale Stout','Ap #596-5693 Sapien, Street'),(66,'Shafira Howell','P.O. Box 841, 1840 At, Rd.'),(67,'Jared Kirby','5721 Mauris. Rd.'),(68,'Rebecca Lott','5494 Eget Ave'),(69,'Laith Rodgers','9634 Vitae, Ave'),(70,'Ivor Fulton','2794 Nulla Ave');
INSERT INTO UserAccount (userID,name,address) VALUES (71,'Cody Sargent','P.O. Box 691, 8639 Sollicitudin Ave'),(72,'Paki Obrien','843-7704 Mauris Av.'),(73,'Alden Branch','Ap #560-8285 Quam, Ave'),(74,'Herman Buckner','339-9462 Ut, Road'),(75,'Lucian Zimmerman','771-5920 Sagittis Rd.'),(76,'Jena Flynn','P.O. Box 896, 5778 Integer Av.'),(77,'Derek Potts','744-3667 Sed Rd.'),(78,'Jarrod Lopez','8233 Donec Avenue'),(79,'Hadassah Moreno','2641 Convallis Street'),(80,'Declan Kane','Ap #991-3457 Semper Avenue');
INSERT INTO UserAccount (userID,name,address) VALUES (81,'Alden Waters','101-9663 At St.'),(82,'Abdul Taylor','P.O. Box 779, 9490 In Rd.'),(83,'Palmer Pearson','Ap #626-1921 Proin Rd.'),(84,'Moses Brewer','1666 Neque Rd.'),(85,'Skyler Martin','Ap #844-724 Nec St.'),(86,'Owen Webster','P.O. Box 787, 6381 Montes, Rd.'),(87,'Madison Santiago','514-2360 Lacus. St.'),(88,'Hope Murphy','Ap #787-3644 Malesuada St.'),(89,'Forrest Banks','Ap #906-2448 Ante Avenue'),(90,'Quyn Logan','943-1102 Aliquam St.');
INSERT INTO UserAccount (userID,name,address) VALUES (91,'William Lindsey','127-1859 Amet, Av.'),(92,'Dora Dickson','P.O. Box 169, 5019 Diam. Avenue'),(93,'Karly Mcbride','P.O. Box 946, 8730 Molestie Rd.'),(94,'Ishmael Avila','Ap #530-1790 Non Av.'),(95,'Julian May','P.O. Box 426, 2316 Mauris St.'),(96,'Mariam Beard','876-6920 Magna Rd.'),(97,'August English','P.O. Box 472, 3189 Cursus Ave'),(98,'Luke Manning','6895 Placerat, Rd.'),(99,'Rhonda Contreras','157-451 Aliquam Rd.'),(100,'Fatima Sandoval','585 Feugiat Ave');

--10 reports are written, only the first 3 have descriptions.
INSERT INTO Report (reportID,title,reportDate,reason,reporter,reportee) values
(1,'No manners','04-24-2018','This person never reply me with smiley face',1,2),
(2,'Self-entitled','04-24-2018','This person thinks he deserves a smiley face',2,1),
(3,'Pedophile','03-23-2019','This person is insinuating pedophilic actions and comments',1,7);
INSERT INTO Report (reportID,title,reportDate,reporter,reportee) VALUES
(4,'Rude','01-15-2019',9,2),
(5,'Bad vibes','02-22-2019',15,2),
(6,'Salty person','03-15-2019',35,2),
(7,'Rude','01-15-2019',19,2),
(8,'Bad negotiator','02-14-2019',83,2),
(9,'Not gentleman/gentlewoman','03-14-2019',74,2),
(10,'No basic respect','03-29-2019',25,2);

--5 groups are created, only the first 3 have descriptions.
INSERT INTO InterestGroup (groupName, groupDescription) VALUES
('Photography Club', 'For all things photos'),
('Spiderman Fans', 'Live and Die by the web'),
('Tech Geeks', 'Self-explanatory.  We like tech && are geeks');
INSERT INTO InterestGroup (groupName) VALUES
('Refined Music People'),
('Clothes Club');


--We  have userAccounts joining interestgroups
INSERT INTO Joins (joinDate, userID, groupname) VALUES 
('02-22-2018',1,'Photography Club'),
('02-21-2018',2,'Photography Club'),
('02-24-2018',3,'Photography Club'),
('02-22-2018',4,'Photography Club'),
('02-20-2018',1,'Clothes Club'),
('02-27-2018',2,'Clothes Club'),
('02-15-2018',3,'Refined Music People'),
('02-17-2018',4,'Refined Music People'),
('01-22-2018',5,'Spiderman Fans'),
('01-21-2018',6,'Spiderman Fans'),
('01-24-2018',7,'Spiderman Fans'),
('01-22-2018',8,'Tech Geeks'),
('01-20-2018',9,'Tech Geeks'),
('01-27-2018',10,'Clothes Club'),
('01-15-2018',11,'Refined Music People'),
('01-17-2018',12,'Refined Music People');


INSERT INTO OrganizedEvent (eventID,eventDate,venue,organizer) VALUES  
(1,'01-17-2019','East Coast Park','Photography Club'),
(2,'01-18-2019','Suntec City','Tech Geeks'),
(3,'01-19-2019','Vivocity Movie Theatre','Spiderman Fans'),
(4,'02-17-2019','Scape','Clothes Club'),
(5,'07-17-2019','Esplanade','Refined Music People');

--loanerID from 1 to 50 inclusive
INSERT INTO Loaner (userID) VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10);
INSERT INTO Loaner (userID) VALUES (11),(12),(13),(14),(15),(16),(17),(18),(19),(20);
INSERT INTO Loaner (userID) VALUES (21),(22),(23),(24),(25),(26),(27),(28),(29),(30);
INSERT INTO Loaner (userID) VALUES (31),(32),(33),(34),(35),(36),(37),(38),(39),(40);
INSERT INTO Loaner (userID) VALUES (41),(42),(43),(44),(45),(46),(47),(48),(49),(50);

--borrowerID from 41 to 100 inclusive
INSERT INTO Borrower (userID) VALUES (41),(42),(43),(44),(45),(46),(47),(48),(49),(50);
INSERT INTO Borrower (userID) VALUES (51),(52),(53),(54),(55),(56),(57),(58),(59),(60);
INSERT INTO Borrower (userID) VALUES (61),(62),(63),(64),(65),(66),(67),(68),(69),(70);
INSERT INTO Borrower (userID) VALUES (71),(72),(73),(74),(75),(76),(77),(78),(79),(80);
INSERT INTO Borrower (userID) VALUES (81),(82),(83),(84),(85),(86),(87),(88),(89),(90);
INSERT INTO Borrower (userID) VALUES (91),(92),(93),(94),(95),(96),(97),(98),(99),(100);

--LoanerItem current set as each loaner has 1 item on loan.  ItemID ranges from 100 to 149 inclusive
-- The first 10 items have an item description
INSERT INTO LoanerItem (itemID,itemName,value,itemDescription,userID) VALUES 
(100,'Fuji Camera', 500,'Hello All, renting out a immaculate condition Camera, lightly used without usage mark. Shutter click less the 3k. Comes with all standard accessories. Self collect only at Blk 421 Hougang Ave 10, low ballers stayout.',1),
(101,'iPad Pro',200,'As good as new with no signs if usage, item in perfect condition, bought on 17th June 2017 Locally, finest tempered glass on since bought. Comes with warranty,  box and all standard accessories. Will throw in Apple original pencil, 3rd party book case.',2),
(102,'Toshiba Laptop',600,'Very good condition, Well kept and still looks new, Condition 9/10, No Battery, Intel Core(TM) 2 Duo CPU T6600 @ 2.2 GHz, DDR2 SDRAM, HDD 500GB, Memory 2GB, Windows 7 Professional',3),
(103,'Sony Headphones',300,'Hello renting a as good as new headphone , used less then 1 hr. Renting as seldom used. Comes with all standard accessories . Item is perfect conditioning with zero usage marks. Item is bought from Expansys on 24th Nov 2018. Price is firm and Low baller will be ignored.  First offer first serve . Thank you ',4),
(104,'Canon Camera Lens',900,'Hello all renting a full working condition lens with no box,  receipt,  warranty.  Item physical condition is 8/10.  With only light users mark which is only visible on strong sunlight. ',5),
(105,'Black Tuxedo',400,'Who doesnt love a black tuxedo',6),
(106,'Pink Shoes',200,'Not only for pedophiles',7),
(107,'Metal Watch',100,'To impress that girl and make her think that you are rich',8),
(108,'Vintage Music CD',100,'Put this in your uni dorm to make visitors think that you are cultured',9),
(109,'Spiderman Movie',60,'Shoot webs and fight crime with your favourite neighbourhood superhero',10);
INSERT INTO LoanerItem (itemID,itemName,value,userID) VALUES (110,'Fuji Camera',100,11),(111,'iPad Pro',900,12),(112,'Toshiba Laptop',100,13),(113,'Sony Headphones',900,14),(114,'Canon Camera Lens',600,15),(115,'Black Tuxedo',700,16),(116,'Pink Shoes',100,17),(117,'Metal Watch',100,18),(118,'Vintage Music CD',500,19),(119,'Spiderman Movie',700,20);
INSERT INTO LoanerItem (itemID,itemName,value,userID) VALUES (120,'Fuji Camera',100,21),(121,'iPad Pro',500,22),(122,'Toshiba Laptop',200,23),(123,'Sony Headphones',800,24),(124,'Canon Camera Lens',700,25),(125,'Black Tuxedo',700,26),(126,'Pink Shoes',400,27),(127,'Metal Watch',100,28),(128,'Vintage Music CD',700,29),(129,'Spiderman Movie',500,30);
INSERT INTO LoanerItem (itemID,itemName,value,userID) VALUES (130,'Fuji Camera',500,31),(131,'iPad Pro',700,32),(132,'Toshiba Laptop',200,33),(133,'Sony Headphones',800,34),(134,'Canon Camera Lens',900,35),(135,'Black Tuxedo',700,36),(136,'Pink Shoes',600,37),(137,'Metal Watch',500,38),(138,'Vintage Music CD',400,39),(139,'Spiderman Movie',600,40);
INSERT INTO LoanerItem (itemID,itemName,value,userID) VALUES (140,'Fuji Camera',600,41),(141,'iPad Pro',600,42),(142,'Toshiba Laptop',700,43),(143,'Sony Headphones',900,44),(144,'Canon Camera Lens',600,45),(145,'Black Tuxedo',900,46),(146,'Pink Shoes',800,47),(147,'Metal Watch',600,48),(148,'Vintage Music CD',900,49),(149,'Spiderman Movie',200,50);


INSERT INTO Advertisement (advID,highestBidder,highestBid,minimumPrice,openingDate,closingDate,minimumIncrease,advertiser,itemID) VALUES  
(1,null,null,10,'03-01-2019','05-01-2019',2,11,110),
(2,null,null,12,'01-04-2019','07-02-2019',2,22,121),
(3,null,null,15,'04-02-2019','05-04-2019',2,44,143);

INSERT INTO Bid (bidID,borrowerID,advID,price) VALUES  
(10,64,1,10),
(11,85,1,12),
(12,76,1,14),
(13,57,2,12);

INSERT INTO Chooses (bidID,userID,advID) VALUES  
(13,22,2);


--Invoiced Loan is a loan between the first loaner and the first borrower.  I.e. id 1 and id 41, id 2 and 42 and so on.  
--There are a total of 40 + 15 invoicedLoans.  The later 15 have reviews tagged to them

INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID) VALUES ('02-19-2018','10-16-2018',14,2,1,41,200,100),('02-14-2019','06-27-2019',15,6,2,42,201,101),('07-31-2018','11-19-2018',11,2,3,43,202,102),('05-31-2018','03-26-2019',12,5,4,44,203,103),('10-17-2018','09-30-2019',12,9,5,45,204,104),('01-14-2018','07-14-2018',17,5,6,46,205,105),('05-21-2019','03-26-2020',10,3,7,47,206,106),('10-04-2018','10-10-2018',19,3,8,48,207,107),('01-14-2019','08-26-2019',14,2,9,49,208,108),('05-05-2018','09-16-2018',14,7,10,50,209,109);
INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID) VALUES ('04-24-2018','06-07-2018',13,4,11,51,210,110),('10-08-2018','12-15-2019',13,8,12,52,211,111),('11-01-2019','02-29-2020',19,2,13,53,212,112),('01-24-2019','06-16-2019',10,7,14,54,213,113),('07-30-2017','05-13-2018',19,3,15,55,214,114),('04-18-2018','05-14-2018',15,6,16,56,215,115),('09-19-2018','10-12-2018',19,5,17,57,216,116),('10-07-2018','01-05-2019',16,2,18,58,217,117),('06-09-2018','06-06-2019',13,8,19,59,218,118),('09-09-2019','10-13-2019',12,8,20,60,219,119);
INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID) VALUES ('10-06-2018','10-11-2018',19,9,21,61,220,120),('03-10-2018','06-11-2018',19,5,22,62,221,121),('07-07-2018','08-02-2019',10,7,23,63,222,122),('09-09-2018','05-13-2019',16,10,24,64,223,123),('04-28-2018','07-22-2018',14,8,25,65,224,124),('09-04-2018','11-08-2018',11,9,26,66,225,125),('06-20-2018','07-22-2019',18,9,27,67,226,126),('04-12-2018','12-28-2018',13,7,28,68,227,127),('03-31-2018','05-12-2018',16,7,29,69,228,128),('05-20-2018','02-13-2019',15,5,30,70,229,129);
INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID) VALUES ('02-09-2018','09-10-2018',10,3,31,71,230,130),('03-27-2018','07-10-2018',16,2,32,72,231,131),('10-29-2017','04-01-2018',10,9,33,73,232,132),('07-24-2019','07-28-2019',17,6,34,74,233,133),('09-24-2017','05-30-2018',10,3,35,75,234,134),('12-08-2019','02-18-2020',16,9,36,76,235,135),('01-18-2019','02-10-2020',16,5,37,77,236,136),('06-09-2018','07-25-2018',10,3,38,78,237,137),('07-24-2018','08-08-2019',10,8,39,79,238,138),('12-08-2019','01-05-2020',13,7,40,80,239,139);
INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID) VALUES 
('11-09-2018','11-12-2018',41,15,11,46,240,110),
('11-23-2018','11-25-2018',73,51,11,58,252,110),
('11-26-2018','11-29-2018',51,24,11,49,243,110),
('12-14-2018','12-16-2018',73,51,11,55,249,110),
('12-22-2018','01-17-2019',37,41,11,52,246,110),
('11-14-2018','11-16-2018',73,41,21,51,245,120),
('11-17-2018','11-19-2018',47,23,21,54,248,120),
('11-24-2018','11-26-2018',14,10,21,48,242,120),
('11-27-2018','11-28-2018',47,23,21,57,251,120),
('11-29-2018','12-01-2018',47,23,21,60,254,120),
('11-20-2018','11-21-2018',15,13,22,50,244,121),
('11-27-2018','11-28-2018',25,14,22,56,250,121),
('11-29-2018','11-30-2018',25,14,22,59,253,121),
('12-01-2018','12-02-2018',46,26,22,53,247,121),
('12-25-2018','12-30-2018',34,13,22,47,241,121);
--date format is month, day, year



--User review item
INSERT INTO UserReviewItem (userID,itemID,itemOwnerID,reviewID,reviewComment,reviewDate,rating) VALUES  
(58,110,11,1,'Enjoyable camera to use!  I really like it.','01-17-2019',5),
(59,121,22,2,'This iPad was not working properly when I got it','01-12-2019',1),
(60,120,21,3,'This is not as good as the other cameras I used','02-19-2019',2);

INSERT INTO UserReviewItem (userID,itemID,itemOwnerID,reviewID,reviewDate,rating) VALUES  
(46,110,11,4,'01-17-2019',2),
(47,121,22,5,'01-12-2019',4),
(48,120,21,6,'02-19-2019',1),
(49,110,11,7,'01-17-2019',4),
(50,121,22,8,'01-12-2019',1),
(51,120,21,9,'02-19-2019',5),
(52,110,11,10,'01-17-2019',1),
(53,121,22,11,'01-12-2019',4),
(54,120,21,12,'02-19-2019',3),
(55,110,11,13,'01-17-2019',1),
(56,121,22,14,'01-12-2019',2),
(57,120,21,15,'02-19-2019',5);

INSERT INTO Upvote (userID,reviewID) VALUES  
(74,1),
(51,2),
(56,3),
(61,4),
(71,5),
(86,6),
(95,7),
(10,8),
(16,9),
(41,10),
(43,1),
(94,1);
