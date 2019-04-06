--Project 
--Data generated using https://www.generatedata.com/

SELECT
    table_schema || '.' || table_name
FROM
    information_schema.tables
WHERE
    table_type = 'BASE TABLE'
AND
    table_schema NOT IN ('pg_catalog', 'information_schema');

-- delete tables if already exists
DROP TABLE IF EXISTS UserAccount
CASCADE;
DROP TABLE IF EXISTS Report
CASCADE;
DROP TABLE IF EXISTS Writes
CASCADE;
DROP TABLE IF EXISTS reportee
CASCADE;
DROP TABLE IF EXISTS InterestGroup
CASCADE;
DROP TABLE IF EXISTS Joins
CASCADE;
DROP TABLE IF EXISTS OrganizedEvent
CASCADE;
DROP TABLE IF EXISTS UserReviewItem
CASCADE;
DROP TABLE IF EXISTS Upvote
CASCADE;
DROP TABLE IF EXISTS Advertisement
CASCADE;
DROP TABLE IF EXISTS Loaner
CASCADE;
DROP TABLE IF EXISTS Borrower
CASCADE;
DROP TABLE IF EXISTS LoanerItem
CASCADE;
DROP TABLE IF EXISTS InvoicedLoan
CASCADE;
DROP TABLE IF EXISTS Bid
CASCADE;
DROP TABLE IF EXISTS Chooses
CASCADE;

-- user is a superclass, and a user has to be either a loaner or borrower, and can be both
create table UserAccount
(
	userID serial,
	name varchar(80) not null,
	address varchar(80) not null,
	primary key (userID)
);


-- if the reporter's value is set to null, then we know that the reporter's account has been deleted.
-- if the reportee's account is deleted, reports against him/her will also be deleted.
create table Report
(
	reportID serial,
	title varchar(1000) not null,
	reportDate date not null,
	reason varchar(8000),
	reporter integer,
	reportee integer,
	primary key (reportID),
	foreign key (reporter) references UserAccount (userID) on delete set null,
	foreign key (reportee) references UserAccount (userID) on delete cascade,
	--You cannot report yourself
	check (reportee != reporter)
);

create table InterestGroup
(
	groupName varchar(80),
	groupDescription varchar(8000),
	primary key (groupName)
);

-- (userID, groupName) is the primary key because each user can only join each group once.  
-- if either the user or the group is deleted, the 'Join' entry is deleted.

create table Joins
(
	joinDate date not null,
	userID integer,
	groupName varchar(80),
	primary key (userId, groupName),
	foreign key (userID) references UserAccount (userID) on delete cascade,
	foreign key (groupName) references InterestGroup (groupName) on delete cascade
);

-- if the interest group is deleted, then the entries into organizedEvent is also deleted.

create table OrganizedEvent
(
	eventID serial,
	eventDate date not null,
	venue varchar(80) not null,
	organizer varchar(80),
	primary key (eventID),
	foreign key (organizer) references InterestGroup (groupName) on delete cascade
);


create table Loaner
(
	userID integer references UserAccount on delete cascade,
	primary key (userID)
);

create table Borrower
(
	userID integer references UserAccount on delete cascade,
	primary key (userID)
);

create table LoanerItem
(
	itemID serial not null,
	itemName varchar(80) not null,
	value integer not null,
	itemDescription varchar(8000),
	userID integer,
	primary key (userID, itemID),
	foreign key (userID) references Loaner (userID) on delete cascade
);

create table InvoicedLoan
(
	invoiceID serial,
	startDate date not null,
	endDate date not null,
	penalty integer not null,
	loanFee integer not null,
	loanerID integer not null,
	borrowerID integer not null,
	itemID integer,
	primary key (invoiceID),
	foreign key (loanerID)references Loaner (userID) on delete cascade,
	foreign key (borrowerID) references Borrower (userID) on delete cascade,
	foreign key (loanerID, itemID) references LoanerItem (userID, itemID) on delete cascade,
	check(startDate <= endDate and loanerID != borrowerID)
);

--we would like the ratings to be between 0 and 5
--users are ony allowed to review an item if they have used that particular item before
--these constraints are enforced in triggers
create table UserReviewItem
(
	reviewID serial,
	userID integer,
	itemID integer not null,
	itemOwnerID integer,
	reviewComment varchar(1000),
	reviewDate date not null,
	rating integer not null,
	invoiceID integer unique not null,
	primary key (reviewID),
	foreign key (userID) references UserAccount (userID) on delete set null,
	foreign key (itemOwnerID, itemID) references LoanerItem (userID, itemID) on delete cascade,
	foreign key (invoiceID) references InvoicedLoan (invoiceID) on delete set null,
	--ratings have to be between 0 to 5 inclusive
	check(0 <= rating and rating <=5 )
);

--Upvotes
--when either the userAccount that upvoted, or the review deleted, the upvote will be deleted.
create table Upvote
(
	userID integer,
	reviewID integer,
	primary key (userID,reviewID),
	foreign key (userID) references UserAccount(userID) on delete cascade,
	foreign key (reviewID) references UserReviewItem(reviewID) on delete cascade
);


-- perhaps a trigger can update the highest bidder and the highest bid, after a bid as been made to a adverstisement entry
create table Advertisement
(
	advID serial,
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
	foreign key (advertiser, itemID) references LoanerItem(userID, itemID) on delete cascade,
	check(minimumIncrease > 0 and openingDate <= closingDate)
);


create table Bid
(
	bidID serial,
	price integer not null,
	borrowerID integer,
	advID integer,
	bidDate date not null,
	primary key (bidID),
	foreign key (borrowerID) references Borrower (userID) on delete cascade,
	foreign key (advID) references Advertisement (advID) on delete cascade
);

create table Chooses
(
	bidID integer unique,
	userID integer not null,
	advID integer unique,
	primary key (userID, bidID, advID),
	foreign key (bidID) references Bid (bidID) on delete cascade,
	foreign key (userID) references Loaner (userID) on delete cascade,
	foreign key (advID) references Advertisement (advID) on delete cascade
);


create or replace function checkMinimumIncrease()
returns trigger as 
$$
	declare adMinimumIncrease integer;
			previousHighestBid integer;
			adMinimumPrice integer;
	begin
		select highestBid
		into previousHighestBid
		from Advertisement
		where advID = new.advID;
	
		select minimumIncrease
		into adMinimumIncrease
		from Advertisement
		where advID = new.advID;
	
		select minimumPrice
		into adMinimumPrice
		from Advertisement
		where advID = new.advID;
	
		if (previousHighestBid is null and new.price < adMinimumPrice) then 
			raise exception 'You have to at least bid the minimum price';
		return null;
		elsif
		(previousHighestBid is not null and new.price < previousHighestBid + adMinimumIncrease) then 
			raise exception 'You have to at least bid the highest bid price, plus the minimum increase';
		return null;
		else
		return new;
	
	end if;
	end
$$
language plpgsql;

create trigger trig1MinimumBidIncreaseTrig
before
update or insert on Bid
for each row
execute procedure checkMinimumIncrease();

create or replace function checkBidMadeBetweenAdvOpenAndCloseDate()
returns trigger as
$$
	declare targetAdvOpening date;
			targetAdvClosing date;
	begin
		select openingDate, closingDate
		into targetAdvOpening, targetAdvClosing
		from advertisement
		where advID = new.advID;

		if (new.bidDate < targetAdvOpening or new.bidDate > targetAdvClosing) then
			raise exception 'You can only bid when the adverisement is open';
			return null;
		else 
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig2CheckBidMadeBetweenAdvOpenAndCloseDate
before
update or insert on Bid
for each row
execute procedure checkBidMadeBetweenAdvOpenAndCloseDate();


create or replace function checkUnableToBidForYourOwnAdvertisement()
returns trigger as 
$$
	declare originalAdvertiser integer;
	begin
		select advertiser
		into originalAdvertiser
		from Advertisement
		where advID = new.advID;
		if (new.borrowerID = originalAdvertiser) then 
			raise exception 'You cannot bid for your own advertisements';
		return null;
		else
		return new;
	end if;
	
	end
$$
language plpgsql;

create trigger trig3CheckUnableToBidForYourOwnAdvertisement
before
update or insert on Bid
for each row
execute procedure checkUnableToBidForYourOwnAdvertisement();



drop procedure if exists insertNewBid;

create or replace function checkChoosesYourOwnAdvertisementAndCorrectBid()
returns trigger as 
$$
	declare creatorID integer;
	begin
		select advertiser
		into creatorID
	
		from Advertisement
		where advID = new.advID;
	
		if (new.userID != creatorID) then 
			raise exception 'creator ID is %', creatorID;
	raise exception 'You can only choose bids that you created the advertisements for';
	return null;
	elsif new.bidID not in
	(select bidID
	from Bid
	where advID = new.advID)
	then 
			raise exception 'You can only choose the bids for your own advertisement';
	return null;
	else
	return new;
	end if;
	
	end
$$
language plpgsql;

create trigger trig1CheckChoosesYourOwnAdvertisementAndCorrectBid
before
update or insert on Chooses
for each row
execute procedure checkChoosesYourOwnAdvertisementAndCorrectBid();


create or replace function checkReviewAfterLoan()
returns trigger as 
$$
	declare invoiceDate date;
	begin
		select startdate
		into invoiceDate
		from invoicedLoan
		where invoiceID = new.invoiceID;
	
		if (new.reviewDate < invoiceDate) then 
			raise exception 'Reviews cannot be written before the loan begins';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig2CheckReviewAfterLoan
before
update or insert on UserReviewItem
for each row
execute procedure checkReviewAfterLoan();


create or replace function checkReviewYourOwnInvoice()
returns trigger as 
$$
	declare invoiceOwner integer;
	begin
		select borrowerID
		into invoiceOwner
		from invoicedLoan
		where invoiceID = new.invoiceID;
	
		if (new.userID != invoiceOwner) then 
			raise exception 'Reviews can only be written with reference to your own invoices, and not someone elses';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig3CheckReviewYourOwnInvoice
before
update or insert on UserReviewItem
for each row
execute procedure checkReviewYourOwnInvoice();


create or replace function checkLoanDateClash()
returns trigger as
$$
	declare
	begin
		if (select max(invoiceID)
		from InvoicedLoan
		where new.startDate >= startDate and new.startDate <= endDate and new.loanerID = loanerID and new.itemID = itemID) is not null then 
			raise exception  'You cannot begin a loan when that item is on loan during that time';
	return null;
	elsif
	(select max(invoiceID)
	from InvoicedLoan
	where new.endDate >= startDate and new.endDate <= endDate and new.loanerID = loanerID and new.itemID = itemID)
	is not null then 
			raise exception 'You cannot have an item on loan when that item is on loan to someone else during that time';
	return null;
	else
	return new;
	end if;
	
	end
$$
language plpgsql;

create trigger trig1CheckInvoicedLoanClash
before
update or insert on InvoicedLoan
for each row
execute procedure checkLoanDateClash();


create  or replace function checkNotAlreadyAdvertised()
returns trigger as 
$$
	begin
		if(select max(advID)
		from advertisement
		where new.openingDate >= openingDate and new.openingDate <= closingDate and new.advertiser = advertiser and new.itemID = itemID and new.highestBid = highestBid and new.advID != advID) is not null then 
			raise exception  'You cannot advertise an item that is currently already being advertised';
			return null;
		elsif(select max(advID)
			from advertisement
			where new.closingDate >= openingDate and new.closingDate <= closingDate and new.advertiser = advertiser and new.itemID = itemID and new.highestBid = highestBid and new.advID != advID) is not null then 
			raise exception 'You cannot advertise an item that is currently already being advertised';
			return null;
		else
		return new;
		end if;
	
	end
$$
language plpgsql;

create trigger trig1CheckNotAlreadyAdvertised
before
update or insert on Advertisement
for each row
execute procedure checkNotAlreadyAdvertised();


create or replace procedure insertNewBid(newBorrowerID integer,newAdvID integer,newBidDate date,newPrice integer)
as
$$
	begin
		insert into Bid (price, borrowerID, advID, bidDate) values 
		(newPrice, newBorrowerID, newAdvID, newBidDate);
		
		update Advertisement
		set highestBid = newPrice,
			highestBidder = newBorrowerID
		where advID = newadvID;
	commit;
	end;
$$
language plpgsql;

select * from advertisement;
--userID from 1 to 100 inclusive
INSERT INTO UserAccount
	(name,address)
VALUES
	('Emerson Franks', '5596 Convallis Rd.'),
	('Linus Lyons', 'Ap #537-6165 Sed Road'),
	('Blake Garrison', '542-8114 Est. Rd.'),
	('Rafael Brewer', 'Ap #343-8632 Elementum Av.'),
	('Hermione Lancaster', 'P.O. Box 790, 1566 Sed St.'),
	('Allegra Colon', 'Ap #322-7444 Odio. Rd.'),
	('Nissim Duffy', '8965 Amet Road'),
	('Fritz Hill', 'Ap #838-2145 Rhoncus Avenue'),
	('Destiny Chambers', 'Ap #231-3514 Enim Street'),
	('Sacha Moreno', 'P.O. Box 468, 8943 Ipsum St.'),
	('Sybil Bishop', '886-2408 Tellus. St.'),
	('Fay Nixon', '125-1506 Leo. Ave'),
	('Aristotle Riddle', '4601 Aptent Ave'),
	('Dustin Orr', '3090 Phasellus Ave'),
	('Madeson Wilcox', '202-447 Ac Street'),
	('Erich Gonzales', '280-3274 Fusce Road'),
	('Arthur Browning', '9562 Mollis. St.'),
	('Mark Brewer', 'P.O. Box 400, 7887 Elementum Street'),
	('Serena Rocha', 'Ap #881-7762 Nisl Road'),
	('Macaulay Spencer', 'Ap #113-8073 Enim. Rd.'),
	('Elmo Hickman', '700-1435 Fringilla Avenue'),
	('Rinah Glover', 'Ap #790-2787 Quam Road'),
	('Laith Holman', '5630 Et Ave'),
	('Jin Mosley', 'P.O. Box 738, 7162 Semper Av.'),
	('Felix Durham', '870-2557 Egestas Road'),
	('Peter Blackburn', '9246 Dignissim. St.'),
	('Kareem Velasquez', '974-7517 Urna, Rd.'),
	('Venus Calhoun', '257-5555 Arcu St.'),
	('Carl Holcomb', 'Ap #125-7409 Mauris. Street'),
	('Deirdre George', 'P.O. Box 129, 4964 Vehicula St.'),
	('Magee Booker', '4086 Sapien. Ave'),
	('Ali Osborne', 'P.O. Box 940, 745 Velit Street'),
	('Kaden Rasmussen', 'P.O. Box 512, 5295 Ridiculus St.'),
	('Kato French', '430-5466 Mauris Rd.'),
	('Kelly Glenn', 'P.O. Box 463, 5738 Vel St.'),
	('Kalia Alexander', 'Ap #341-3183 Tincidunt Avenue'),
	('Fallon Bond', '944-7112 Ut Rd.'),
	('Amal Chapman', '304-2492 Sit Rd.'),
	('Chancellor Mcclain', 'Ap #758-6344 A, Road'),
	('Beck Tyler', 'Ap #851-5033 Magna. Rd.'),
	('Destiny Serrano', '7372 Sed Avenue'),
	('Lucas Fuller', '8498 Ante, Street'),
	('Ariana Peters', 'P.O. Box 101, 1520 Massa Rd.'),
	('Akeem Morton', 'P.O. Box 623, 4017 Consectetuer Rd.'),
	('Wayne Christian', '544-8345 Ipsum St.'),
	('Rina Robinson', '1651 Tempus, Rd.'),
	('Thaddeus Jones', 'Ap #241-9228 Lacus St.'),
	('Todd Palmer', 'Ap #656-3473 Nibh. Avenue'),
	('Dorothy Pierce', 'P.O. Box 112, 6161 Pede Road'),
	('Demetrius Rodriguez', 'Ap #917-4185 Morbi Road'),
	('Sybil Short', 'P.O. Box 989, 2185 Fusce Rd.'),
	('Odysseus Rosario', 'P.O. Box 287, 9314 Dictum. St.'),
	('Jeanette Robles', '874-8968 Sollicitudin St.'),
	('Hector Rhodes', 'Ap #395-873 Et Road'),
	('Jael Puckett', 'Ap #525-4393 Aliquam Ave'),
	('Blaze Le', 'Ap #675-442 Id, Av.'),
	('Denton Yates', 'Ap #411-810 Consectetuer St.'),
	('Fallon Rojas', '4633 Facilisis Rd.'),
	('Clark House', 'P.O. Box 575, 3468 Parturient Avenue'),
	('Xerxes Anderson', 'Ap #228-8343 Tempus Av.'),
	('Orla Kent', 'Ap #515-8520 Erat Road'),
	('Kevin Reeves', '770-2553 Gravida Avenue'),
	('Lucas Parks', 'P.O. Box 402, 3916 Est. Avenue'),
	('Noble Briggs', 'P.O. Box 869, 3517 Dolor. Ave'),
	('Dale Stout', 'Ap #596-5693 Sapien, Street'),
	('Shafira Howell', 'P.O. Box 841, 1840 At, Rd.'),
	('Jared Kirby', '5721 Mauris. Rd.'),
	('Rebecca Lott', '5494 Eget Ave'),
	('Laith Rodgers', '9634 Vitae, Ave'),
	('Ivor Fulton', '2794 Nulla Ave'),
	('Cody Sargent', 'P.O. Box 691, 8639 Sollicitudin Ave'),
	('Paki Obrien', '843-7704 Mauris Av.'),
	('Alden Branch', 'Ap #560-8285 Quam, Ave'),
	('Herman Buckner', '339-9462 Ut, Road'),
	('Lucian Zimmerman', '771-5920 Sagittis Rd.'),
	('Jena Flynn', 'P.O. Box 896, 5778 Integer Av.'),
	('Derek Potts', '744-3667 Sed Rd.'),
	('Jarrod Lopez', '8233 Donec Avenue'),
	('Hadassah Moreno', '2641 Convallis Street'),
	('Declan Kane', 'Ap #991-3457 Semper Avenue'),
	('Alden Waters', '101-9663 At St.'),
	('Abdul Taylor', 'P.O. Box 779, 9490 In Rd.'),
	('Palmer Pearson', 'Ap #626-1921 Proin Rd.'),
	('Moses Brewer', '1666 Neque Rd.'),
	('Skyler Martin', 'Ap #844-724 Nec St.'),
	('Owen Webster', 'P.O. Box 787, 6381 Montes, Rd.'),
	('Madison Santiago', '514-2360 Lacus. St.'),
	('Hope Murphy', 'Ap #787-3644 Malesuada St.'),
	('Forrest Banks', 'Ap #906-2448 Ante Avenue'),
	('Quyn Logan', '943-1102 Aliquam St.'),
	('William Lindsey', '127-1859 Amet, Av.'),
	('Dora Dickson', 'P.O. Box 169, 5019 Diam. Avenue'),
	('Karly Mcbride', 'P.O. Box 946, 8730 Molestie Rd.'),
	('Ishmael Avila', 'Ap #530-1790 Non Av.'),
	('Julian May', 'P.O. Box 426, 2316 Mauris St.'),
	('Mariam Beard', '876-6920 Magna Rd.'),
	('August English', 'P.O. Box 472, 3189 Cursus Ave'),
	('Luke Manning', '6895 Placerat, Rd.'),
	('Rhonda Contreras', '157-451 Aliquam Rd.'),
	('Fatima Sandoval', '585 Feugiat Ave');


--10 reports are written, only the first 3 have descriptions.
INSERT INTO Report
	(title,reportDate,reason,reporter,reportee)
values
	('No manners', '04-24-2018', 'This person never reply me with smiley face', 1, 2),
	('Self-entitled', '04-24-2018', 'This person thinks he deserves a smiley face', 2, 1),
	('Pedophile', '03-23-2019', 'This person is insinuating pedophilic actions and comments', 1, 7);
INSERT INTO Report
	(title,reportDate,reporter,reportee)
VALUES
	('Rude', '01-15-2019', 9, 2),
	('Bad vibes', '02-22-2019', 15, 2),
	('Salty person', '03-15-2019', 35, 2),
	('Rude', '01-15-2019', 19, 2),
	('Bad negotiator', '02-14-2019', 83, 2),
	('Not gentleman/gentlewoman', '03-14-2019', 74, 2),
	( 'No basic respect', '03-29-2019', 25, 2);

--5 groups are created, only the first 3 have descriptions.
INSERT INTO InterestGroup
	(groupName, groupDescription)
VALUES
	('Photography Club', 'For all things photos'),
	('Spiderman Fans', 'Live and Die by the web'),
	('Tech Geeks', 'Self-explanatory.  We like tech && are geeks');
INSERT INTO InterestGroup
	(groupName)
VALUES
	('Refined Music People'),
	('Clothes Club');


--We  have userAccounts joining interestgroups
INSERT INTO Joins
	(joinDate, userID, groupname)
VALUES
	('02-22-2018', 1, 'Photography Club'),
	('02-21-2018', 2, 'Photography Club'),
	('02-24-2018', 3, 'Photography Club'),
	('02-22-2018', 4, 'Photography Club'),
	('02-20-2018', 1, 'Clothes Club'),
	('02-27-2018', 2, 'Clothes Club'),
	('02-15-2018', 3, 'Refined Music People'),
	('02-17-2018', 4, 'Refined Music People'),
	('01-22-2018', 5, 'Spiderman Fans'),
	('01-21-2018', 6, 'Spiderman Fans'),
	('01-24-2018', 7, 'Spiderman Fans'),
	('01-22-2018', 8, 'Tech Geeks'),
	('01-20-2018', 9, 'Tech Geeks'),
	('01-27-2018', 10, 'Clothes Club'),
	('01-15-2018', 11, 'Refined Music People'),
	('01-17-2018', 12, 'Refined Music People'),
	('04-14-2017', 48, 'Refined Music People');


INSERT INTO OrganizedEvent
	(eventDate,venue,organizer)
VALUES
	('01-17-2019', 'East Coast Park', 'Photography Club'),
	('01-18-2019', 'Suntec City', 'Tech Geeks'),
	('01-19-2019', 'Vivocity Movie Theatre', 'Spiderman Fans'),
	('02-17-2019', 'Scape', 'Clothes Club'),
	('07-17-2019', 'Esplanade', 'Refined Music People');


--loanerID from 1 to 50 inclusive
INSERT INTO Loaner
	(userID)
VALUES
	(1),
	(2),
	(3),
	(4),
	(5),
	(6),
	(7),
	(8),
	(9),
	(10),
	(11),
	(12),
	(13),
	(14),
	(15),
	(16),
	(17),
	(18),
	(19),
	(20),
	(21),
	(22),
	(23),
	(24),
	(25),
	(26),
	(27),
	(28),
	(29),
	(30),
	(31),
	(32),
	(33),
	(34),
	(35),
	(36),
	(37),
	(38),
	(39),
	(40),
	(41),
	(42),
	(43),
	(44),
	(45),
	(46),
	(47),
	(48),
	(49),
	(50);

--borrowerID from 41 to 100 inclusive
INSERT INTO Borrower
	(userID)
VALUES
	(41),
	(42),
	(43),
	(44),
	(45),
	(46),
	(47),
	(48),
	(49),
	(50),
	(51),
	(52),
	(53),
	(54),
	(55),
	(56),
	(57),
	(58),
	(59),
	(60),
	(61),
	(62),
	(63),
	(64),
	(65),
	(66),
	(67),
	(68),
	(69),
	(70),
	(71),
	(72),
	(73),
	(74),
	(75),
	(76),
	(77),
	(78),
	(79),
	(80),
	(81),
	(82),
	(83),
	(84),
	(85),
	(86),
	(87),
	(88),
	(89),
	(90),
	(91),
	(92),
	(93),
	(94),
	(95),
	(96),
	(97),
	(98),
	(99),
	(100),
	(1);

--LoanerItem current set as each loaner has 1 item on loan.  ItemID ranges from 100 to 149 inclusive
-- The first 10 items have an item description
INSERT INTO LoanerItem
	(itemName,value,itemDescription,userID)
VALUES
	('Fuji Camera', 500, 'Hello All, renting out a immaculate condition Camera, lightly used without usage mark. Shutter click less the 3k. Comes with all standard accessories. Self collect only at Blk 421 Hougang Ave 10, low ballers stayout.', 1),
	('iPad Pro', 200, 'As good as new with no signs if usage, item in perfect condition, bought on 17th June 2017 Locally, finest tempered glass on since bought. Comes with warranty,  box and all standard accessories. Will throw in Apple original pencil, 3rd party book case.', 2),
	('Toshiba Laptop', 600, 'Very good condition, Well kept and still looks new, Condition 9/10, No Battery, Intel Core(TM) 2 Duo CPU T6600 @ 2.2 GHz, DDR2 SDRAM, HDD 500GB, Memory 2GB, Windows 7 Professional', 3),
	('Sony Headphones', 300, 'Hello renting a as good as new headphone , used less then 1 hr. Renting as seldom used. Comes with all standard accessories . Item is perfect conditioning with zero usage marks. Item is bought from Expansys on 24th Nov 2018. Price is firm and Low baller will be ignored.  First offer first serve . Thank you ', 4),
	('Canon Camera Lens', 900, 'Hello all renting a full working condition lens with no box,  receipt,  warranty.  Item physical condition is 8/10.  With only light users mark which is only visible on strong sunlight. ', 5),
	('Black Tuxedo', 400, 'Who doesnt love a black tuxedo', 6),
	('Pink Shoes', 200, 'Not only for pedophiles', 7),
	('Metal Watch', 100, 'To impress that girl and make her think that you are rich', 8),
	('Vintage Music CD', 100, 'Put this in your uni dorm to make visitors think that you are cultured', 9),
	('Spiderman Movie', 60, 'Shoot webs and fight crime with your favourite neighbourhood superhero', 10);
INSERT INTO LoanerItem
	(itemName,value,userID)
VALUES
	('Fuji Camera', 100, 11),
	('iPad Pro', 900, 12),
	('Toshiba Laptop', 100, 13),
	('Sony Headphones', 900, 14),
	('Canon Camera Lens', 600, 15),
	('Black Tuxedo', 700, 16),
	('Pink Shoes', 100, 17),
	('Metal Watch', 100, 18),
	('Vintage Music CD', 500, 19),
	('Spiderman Movie', 700, 20),
	--
	('Fuji Camera', 100, 21),
	('iPad Pro', 500, 22),
	('Toshiba Laptop', 200, 23),
	('Sony Headphones', 800, 24),
	('Canon Camera Lens', 700, 25),
	('Black Tuxedo', 700, 26),
	('Pink Shoes', 400, 27),
	('Metal Watch', 100, 28),
	('Vintage Music CD', 700, 29),
	('Spiderman Movie', 500, 30),
	--
	('Fuji Camera', 500, 31),
	('iPad Pro', 700, 32),
	('Toshiba Laptop', 200, 33),
	('Sony Headphones', 800, 34),
	('Canon Camera Lens', 900, 35),
	('Black Tuxedo', 700, 36),
	('Pink Shoes', 600, 37),
	('Metal Watch', 500, 38),
	('Vintage Music CD', 400, 39),
	('Spiderman Movie', 600, 40),
	--
	('Fuji Camera', 600, 41),
	('iPad Pro', 600, 42),
	('Toshiba Laptop', 700, 43),
	('Sony Headphones', 900, 44),
	('Canon Camera Lens', 600, 45),
	('Black Tuxedo', 900, 46),
	('Pink Shoes', 800, 47),
	('Metal Watch', 600, 48),
	('Vintage Music CD', 900, 49),
	('Spiderman Movie', 200, 50);


INSERT INTO Advertisement
	(highestBidder,highestBid,minimumPrice,openingDate,closingDate,minimumIncrease,advertiser,itemID)
VALUES
	(null, null, 10, '03-01-2019', '05-01-2019', 2, 1, 1),
	(null, null, 12, '01-04-2019', '07-02-2019', 2, 2, 2),
	(null, null, 15, '04-02-2019', '05-04-2019', 2, 3, 3),
	(null, null, 10, '03-01-2019', '05-01-2019', 2, 4, 4),
	(null, null, 12, '01-04-2019', '07-02-2019', 2, 5, 5),
	(null, null, 15, '04-02-2019', '05-04-2019', 2, 6, 6),
	(null, null, 10, '03-01-2019', '05-01-2019', 2, 7, 7),
	(null, null, 12, '01-04-2019', '07-02-2019', 2, 8, 8),
	(null, null, 15, '04-02-2019', '05-04-2019', 2, 9, 9);

	
call insertNewBid(64, 1,'03-01-2019',10);
call insertNewBid(49, 1,'03-02-2019',12);
call insertNewBid(85, 1,'03-03-2019',14);
call insertNewBid(76, 1,'03-04-2019',16);
call insertNewBid(57, 2,'01-04-2019',12);
call insertNewBid(64, 3,'04-02-2019',15);
call insertNewBid(49, 3,'05-03-2019',17);
call insertNewBid(85, 3,'05-04-2019',19);
call insertNewBid(85, 4,'03-01-2019',14);
call insertNewBid(76, 4,'03-02-2019',16);
call insertNewBid(76, 5,'01-04-2019',18);
call insertNewBid(64, 5,'02-04-2019',20);
call insertNewBid(57, 6,'04-02-2019',15);
call insertNewBid(49, 6,'04-03-2019',17);
call insertNewBid(57, 6,'04-03-2019',19);
call insertNewBid(64, 7,'03-01-2019',10);
call insertNewBid(49, 7,'04-02-2019',12);
call insertNewBid(57, 7,'04-02-2019',14);
call insertNewBid(85, 8,'02-04-2019',12);
call insertNewBid(76, 9,'05-02-2019',16);
	

INSERT INTO Chooses
	(bidID,userID,advID)
VALUES
	(5, 2, 2);


--Invoiced Loan is a loan between the first loaner and the first borrower.  I.e. id 1 and id 41, id 2 and 42 and so on.  
--There are a total of 40 + 15 invoicedLoans.  The later 15 have reviews tagged to them
INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,itemID) VALUES ('02-19-2018','10-16-2018',14,2,1,41,1),('02-14-2019','02-27-2019',15,6,2,42,2),('07-31-2018','08-19-2018',11,2,3,43,3),('05-31-2018','06-01-2018',12,5,4,44,4),('10-17-2018','10-30-2018',12,9,5,45,5),('01-14-2018','07-14-2018',17,5,6,46,6),('05-21-2019','05-26-2019',10,3,7,47,7),('10-04-2018','10-10-2018',19,3,8,48,8),('01-14-2019','08-26-2019',14,2,9,49,9),('05-05-2018','09-16-2018',14,7,10,50,10);
INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,itemID) VALUES ('04-24-2018','06-07-2018',13,4,11,51,11),('10-08-2018','12-15-2019',13,8,12,52,12),('11-01-2019','02-29-2020',19,2,13,53,13),('01-24-2019','06-16-2019',10,7,14,54,14),('07-30-2017','05-13-2018',19,3,15,55,15),('04-18-2018','05-14-2018',15,6,16,56,16),('09-19-2018','10-12-2018',19,5,17,57,17),('10-07-2018','01-05-2019',16,2,18,58,18),('06-09-2018','06-06-2019',13,8,19,59,19),('09-09-2019','10-13-2019',12,8,20,60,20);
INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,itemID) VALUES ('10-06-2018','10-11-2018',19,9,21,61,21),('03-10-2018','06-11-2018',19,5,22,62,22),('07-07-2018','08-02-2019',10,7,23,63,23),('09-09-2018','05-13-2019',16,10,24,64,24),('04-28-2018','07-22-2018',14,8,25,65,25),('09-04-2018','11-08-2018',11,9,26,66,26),('06-20-2018','07-22-2019',18,9,27,67,27),('04-12-2018','12-28-2018',13,7,28,68,28),('03-31-2018','05-12-2018',16,7,29,69,29),('05-20-2018','02-13-2019',15,5,30,70,30);
INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,itemID) VALUES ('02-09-2018','09-10-2018',10,3,31,71,31),('03-27-2018','07-10-2018',16,2,32,72,32),('10-29-2017','04-01-2018',10,9,33,73,33),('07-24-2019','07-28-2019',17,6,34,74,34),('09-24-2017','05-30-2018',10,3,35,75,35),('12-08-2019','02-18-2020',16,9,36,76,36),('01-18-2019','02-10-2020',16,5,37,77,37),('06-09-2018','07-25-2018',10,3,38,78,38),('07-24-2018','08-08-2019',10,8,39,79,39),('12-08-2019','01-05-2020',13,7,40,80,40);
INSERT INTO InvoicedLoan
	(startDate,endDate,penalty,loanFee,loanerID,borrowerID,itemID)
VALUES
	('02-14-2019', '02-27-2019', 15, 6, 1, 42, 1),
	('07-31-2018', '11-19-2018', 11, 2, 2, 43, 2),
	('05-31-2018', '06-02-2018', 12, 5, 3, 44, 3),
	('10-17-2018', '10-18-2018', 12, 9, 4, 45, 4),
	('01-14-2018', '02-14-2018', 17, 5, 1, 46, 1),
	('06-21-2019', '06-26-2019', 10, 3, 2, 47, 2),
	('10-04-2018', '10-10-2018', 19, 3, 3, 48, 3),
	('01-14-2019', '01-26-2019', 14, 2, 1, 49, 1),
	('05-05-2018', '06-16-2018', 14, 7, 2, 50, 2),
	('04-24-2018', '04-25-2018', 12, 5, 3, 51, 3),
	('09-17-2019', '09-30-2019', 12, 9, 1, 52, 1),
	('02-14-2018', '03-14-2018', 17, 5, 2, 53, 2),
	('03-10-2018', '03-13-2018', 10, 3, 3, 54, 3),
	('09-10-2019', '10-10-2019', 19, 3, 1, 55, 1),
	('08-14-2019', '08-26-2019', 14, 2, 2, 56, 2),
	('09-05-2018', '09-16-2018', 14, 7, 3, 57, 3),
	('02-05-2018', '02-06-2018', 14, 7, 2, 57, 2),
	('07-10-2019', '07-10-2019', 19, 3, 1, 64, 1),
	('02-03-2017', '02-04-2017', 13, 4, 3, 1, 3);
--date format is month, day, year


INSERT INTO UserReviewItem
 	(userID,itemOwnerID,itemID,reviewComment,reviewDate,rating,invoiceID)
VALUES
 	(42, 1,1, 'Enjoyable camera to use!  I really like it.', '02-17-2019', 5,41),
 	(43, 2,2, 'This iPad was not working properly when I got it', '01-12-2019', 1,42),
 	(44, 1,1, 'This is not as good as the other cameras I used', '02-19-2019', 2,43),
 	(1, 3, 3, 'This Toshiba laptop is an ancient beauty','06-02-2017', 5,59);

 
INSERT INTO UserReviewItem
 	(userID,itemOwnerID,itemID,reviewDate,rating,invoiceID)
VALUES
 	(46, 1,1, '01-17-2019', 2,45),
 	(47, 2,2, '10-12-2019', 4,46),
 	(48, 3,3, '02-19-2019', 1,47),
 	(49, 1,1, '01-17-2019', 4,48),
 	(50, 2,2, '01-12-2019', 1,49),
 	(51, 3,3, '02-19-2019', 5,50),
 	(52, 1,1, '10-17-2019', 1,51),
 	(53, 2,2, '10-12-2019', 4,52),
 	(54, 3,3, '02-19-2019', 3,53),
 	(55, 1,1, '12-17-2019', 1,54),
 	(56, 2,2, '09-12-2019', 2,55),
 	(57, 3,3, '10-19-2019', 5,56),
 	(44, 4,4, '05-31-2018', 4,4),
 	(45, 5,5, '10-17-2018', 4,5),
 	(46, 6,6, '05-31-2018', 4,6),
 	(47, 7,7, '05-23-2019', 4,7),
 	(48, 8,8, '10-10-2018', 4,8),
 	(49, 9,9, '01-31-2019', 4,9);

 
INSERT INTO Upvote
 	(userID,reviewID)
VALUES
 	(74, 1),
 	(51, 2),
 	(56, 3),
 	(61, 4),
 	(71, 5),
 	(86, 6),
 	(95, 7),
 	(10, 8),
 	(16, 9),
 	(41, 10),
 	(43, 1),
 	(94, 1),
 	(46, 4);


DROP VIEW IF EXISTS biggestFanAward, worstEnemy, popularItem CASCADE;

create view biggestFanAward  (loanerID, fan) as
with loanerAdvertisement as
(
	select advertiser, advID
	from Advertisement
),
advertisementBidders as 
(
	select advID, borrowerID as bidder
	from Bid
),
loanerBidder as 
(
	select distinct advertiser as loaner, bidder
	from loanerAdvertisement as la inner join advertisementBidders as ab 
	on la.advID = ab.advID
),
loanersDistinctItems as 
(
	select userID as loanerID, count(itemID) as distinctItems
	from loanerItem
	group by userID
),
loanersBorrowersOfDistinctItems as 
(
	select borrowerID, loanerID, count(itemID) as numItemsBorrowed
	from invoicedLoan
	group by loanerID,  itemID, borrowerid
),
loanersBorrowersAtLeast90Percent as 
(
	select ld.loanerID, borrowerID
	from loanersDistinctItems as ld inner join loanersBorrowersOfDistinctItems as lb  
		on ld.loanerID = lb.loanerID
	where numItemsBorrowed  >= (0.9 * distinctItems)
)
select *
from loanerBidder
intersect
select * 
from loanersBorrowersAtLeast90Percent;


create view worstEnemy (hated, hater) as
with reportedReporteePairs as 
(
	select reportee, reporter
	from Report
),
revieweeReviewerPairsWhereAvgRatingAtMost2 as 
(
	select itemOwnerID as reviewee, userID as reviewer, avg(rating) as avgRating
	from UserReviewItem
	group by itemOwnerID, userID
	having avg(rating) <= 2
),
upvoteeUpvoterPair as 
(
	select distinct uri.userID as upvotee, u.userID as upvoter
	from Upvote as u inner join userReviewItem as uri 
		on u.reviewID = uri.reviewID
),
similarInterestGroupPairs as 
(
	select j1.userID as user1, j2.userID as user2
	from joins as j1 inner join joins as j2 
		on j1.groupName = j2.groupName
),
revieweeReviewerPairsWithNoUpvote as 
(
	select *
	from revieweeReviewerPairsWhereAvgRatingAtMost2
	where (reviewee,reviewer) not in 
		(
			select upvotee as reviewee, upvoter as reviewer 
			from upvoteeUpvoterPair
		)
),
revieweeReviewerPairsWithNoUpvoteAndNoInterest as 
(
	select *
	from revieweeReviewerPairsWithNoUpvote
	where (reviewee,reviewer) not in 
		(
			select user1 as reviewee, user2 as reviewer 
			from similarInterestGroupPairs
		)
),
revieweeLowestAvgScore as 
(
	select reviewee, min(avgRating) as avgRating
	from revieweeReviewerPairsWithNoUpvoteAndNoInterest
	group by reviewee 
)
select distinct rlow.reviewee as hated, reviewer as hater
from revieweeLowestAvgScore as rlow inner join revieweeReviewerPairsWithNoUpvoteAndNoInterest as rui
	on rlow.reviewee = rui.reviewee and rlow.avgRating = rui.avgRating;




create view popularItem (month, year, mostPopularItem, secondMostPopularItem, thirdMostPopularItem) as
with advertisementNumBid as 
(
	select adv.advID, count(borrowerID)
	from advertisement as adv inner join bid
		on adv.advid = bid.advid
	group by adv.advID
),
bidForAdvMonthAndYear as 
(
	select bidID, advID, 
		extract(month from bidDate) as bidMonth, 
		extract(year from bidDate) as bidYear
	from Bid
),
advBidMonthAndYearCount as 
(
	select advID, count(bidID) as numBids, bidMonth, bidYear
	from bidForAdvMonthAndYear
	group by advID, bidMonth, bidYear
),
itemAvgRating as 
(
	select itemOwnerID, itemID, avg(rating) as avgRating
	from userReviewItem 
	group by itemOwnerID, itemID
),
itemAvgRatingAtLeast3 as 
(
	select * 
	from itemAvgRating
	where avgRating >= 3
),
advBidMonthAndYearCountAndItemAdvertiserID as 
(
	select ab.advID, numBids, ab.bidMonth, ab.bidYear, advertiser, itemID
	from advBidMonthAndYearCount as ab inner join advertisement as ad  
		on ab.advID = ad.advID
),
advBidMonthAndYearCountAbove3 as 
(
	select advID, numBids, bidMonth, bidYear
	from advBidMonthAndYearCountAndItemAdvertiserID
	where (advertiser, itemID) in 
		(
			select itemOwnerID as advertiser, itemID 
			from itemAvgRatingAtLeast3
		)
),
mostPopularNumBidsInYearMonth as 
(
	select bidMonth, bidYear, max(numBids) as numBids
	from advBidMonthAndYearCountAbove3
	group by bidMonth, bidYear
),
mostPopularAdvInYearMonth as 
(
	select distinct ac.bidMonth, ac.bidYear, min(advID) as advID
	from advBidMonthAndYearCountAbove3 as ac inner join mostPopularNumBidsInYearMonth as mm
		on ac.numBids = mm.numBids and ac.bidmonth = mm.bidMonth and ac.bidYear = mm.bidYear
	group by ac.bidMonth, ac.bidYear
),
advBidMonthAndYearCountMinusMostPopular as 
(
	select *
	from advBidMonthAndYearCountAbove3
	where (advID,bidMonth, bidYear) not in 
		(
			select advID, bidMonth, bidYear
			from mostPopularAdvInYearMonth
		)
),
secondMostPopularNumBidsInYearMonth as 
(
	select bidMonth, bidYear, max(numBids) as numBids
	from advBidMonthAndYearCountMinusMostPopular
	group by bidMonth, bidYear
),
secondMostPopularAdvInYearMonth as 
(
	select distinct ac.bidMonth, ac.bidYear, min(advID) as advID
	from secondMostPopularNumBidsInYearMonth as ac inner join advBidMonthAndYearCountMinusMostPopular as mm
		on ac.numBids = mm.numBids and ac.bidmonth = mm.bidMonth and ac.bidYear = mm.bidYear
	group by ac.bidMonth, ac.bidYear
),
advBidMonthAndYearCountMinusSecondMostPopular as 
(
	select *
	from advBidMonthAndYearCountMinusMostPopular
	where (advID,bidMonth, bidYear) not in 
		(
			select advID, bidMonth, bidYear
			from secondMostPopularAdvInYearMonth
		)
),
thirdMostPopularNumBidsInYearMonth as 
(
	select bidMonth, bidYear, max(numBids) as numBids
	from advBidMonthAndYearCountMinusSecondMostPopular
	group by bidMonth, bidYear
),
thirdMostPopularAdvInYearMonth as 
(
	select distinct ac.bidMonth, ac.bidYear, min(advID) as advID
	from thirdMostPopularNumBidsInYearMonth as ac inner join advBidMonthAndYearCountMinusSecondMostPopular as mm
		on ac.numBids = mm.numBids and ac.bidmonth = mm.bidMonth and ac.bidYear = mm.bidYear
	group by ac.bidMonth, ac.bidYear
),
firstAndSecondMostPopularAdvInYearMonth as 
(
	select fm.bidMonth, fm.bidYear, fm.advID, sm.advID as advID2
	from mostPopularAdvInYearMonth as fm left join secondMostPopularAdvInYearMonth as sm 
		on fm.bidMonth = sm.bidMonth and fm.bidYear = sm.bidYear
),
firstAndSecondAndThirdMostPopularAdvInYearMonth as 
(
	select fm.bidMonth, fm.bidYear, fm.advID, fm.advID2, sm.advID as advID3
	from firstAndSecondMostPopularAdvInYearMonth as fm left join thirdMostPopularAdvInYearMonth as sm 
		on fm.bidMonth = sm.bidMonth and fm.bidYear = sm.bidYear
)
select *
from firstAndSecondAndThirdMostPopularAdvInYearMonth;

