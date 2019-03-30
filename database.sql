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
	check (reporter != reportee)
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
	itemID serial,
	itemName varchar(80) not null,
	value integer not null,
	itemDescription varchar(8000),
	userID integer,
	primary key (userID, itemID),
	foreign key (userID) references Loaner (userID) on delete cascade
);

--we would like the ratings to be between 0 and 5
--users are ony allowed to review an item if they have used that particular item before
--these constraints are enforced in triggers
create table UserReviewItem
(
	reviewID serial,
	userID integer,
	itemID integer,
	itemOwnerID integer,
	reviewComment varchar(1000),
	reviewDate date not null,
	rating integer not null,
	primary key (reviewID),
	foreign key (userID) references UserAccount (userID) on delete set null,
	foreign key (itemOwnerID, itemID) references LoanerItem (userID, itemID) on delete cascade
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
	foreign key (advertiser, itemID) references LoanerItem(userID, itemID) on delete cascade
);


create table Bid
(
	bidID serial,
	price integer not null,
	borrowerID integer,
	advID integer,
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

--currently startdate can be after end date
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
	foreign key (loanerID, itemID) references LoanerItem (userID, itemID) on delete cascade
);


create or replace function checkReportYourself
()
returns trigger as
$$
begin
	if (new.reporter = new.reportee) then
		raise notice 'You cannot report yourself';
return null;
else
return new;
end
if;
end
$$
language plpgsql;

create trigger trig1CheckSelfReport
before
update or insert on Report
for each row
execute procedure checkReportYourself
();


create or replace function checkMinimumIncrease
()
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
		raise notice 'You have to at least bid the minimum price';
	return null;
	elsif
	(previousHighestBid is not null and new.price < previousHighestBid + adMinimumIncrease) then 
		raise notice 'You have to at least bid the highest bid price, plus the minimum increase';
	return null;
	else
	return new;

end
if;
end
$$
language plpgsql;

create trigger trig1MinimumBidIncreaseTrig
before
update or insert on Bid
for each row
execute procedure checkMinimumIncrease
();


create or replace function updateHighestBidder
()
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
before
update or insert on Bid
for each row
execute procedure updateHighestBidder
();


create or replace function checkUnableToBidForYourOwnAdvertisement
()
returns trigger as 
$$
declare originalAdvertiser integer;
begin
	select advertiser
	into originalAdvertiser
	from Advertisement
	where advID = new.advID;
	if (new.borrowerID = originalAdvertiser) then 
		raise notice 'You cannot bid for your own advertisements';
	return null;
	else
	return new;
end
if;
end
$$
language plpgsql;

create trigger trig3CheckUnableToBidForYourOwnAdvertisement
before
update or insert on Bid
for each row
execute procedure checkUnableToBidForYourOwnAdvertisement
();


create or replace function checkChoosesYourOwnAdvertisementAndCorrectBid
()
returns trigger as 
$$
declare creatorID integer;
begin
	select advertiser
	into creatorID
	from Advertisement
	where advID = new.advID;

	if (new.userID != creatorID) then 
		raise notice 'creator ID is %', creatorID;
raise notice 'You can only choose bids that you created the advertisements for';
return null;
elsif new.bidID not in
(select bidID
from Bid
where advID = new.advID)
then 
		raise notice 'You can only choose the bids for your own advertisement';
return null;
else
return new;
end
if;
end
$$
language plpgsql;

create trigger trig1CheckChoosesYourOwnAdvertisementAndCorrectBid
before
update or insert on Chooses
for each row
execute procedure checkChoosesYourOwnAdvertisementAndCorrectBid
();


--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

-- Commenting this out for now since it's gonna be changed


-- --should only be able to review AFTER you have made a loan
-- create or replace function checkReviewAfterLoan
-- ()
-- returns trigger as 
-- $$
-- declare earliestLoanDate date;
-- begin
-- 	select min(startDate)
-- 	into earliestLoanDate
-- 	from InvoicedLoan
-- 	where new.userID = borrowerID and new.itemOwnerID = loanerID and new.itemID = itemID;

-- 	if (earliestLoanDate is null or earliestLoanDate > new.reviewDate) then 
-- 		raise notice 'You have to use the item first before reviewing it';
-- 	return null;
-- 	else
-- 	return new;
-- end
-- if;
-- end
-- $$
-- language plpgsql;

-- create trigger trig1CheckReviewAfterLoan
-- before
-- update or insert on UserReviewItem
-- for each row
-- execute procedure checkReviewAfterLoan
-- ();


-- create or replace function checkProperRating
-- ()
-- returns trigger as 
-- $$
-- begin
-- 	if (new.rating < 0 or new.rating > 5) then 
-- 		raise notice 'ratings have to be between 0 and 5';
-- return null;
-- else
-- return new;
-- end
-- if;
-- end
-- $$
-- language plpgsql;

-- create trigger trig2CheckProperRating
-- before
-- update or insert on UserReviewItem
-- for each row
-- execute procedure checkProperRating
-- ();


--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------


create or replace function checkLoanDateClash
()
returns trigger as
$$
declare
begin
	if (select max(invoiceID)
	from InvoicedLoan
	where new.startDate >= startDate and new.startDate <= endDate and new.loanerID = loanerID and new.itemID = itemID) is not null then 
		raise notice  'You cannot begin a loan when that item is on loan during that time';
return null;
elsif
(select max(invoiceID)
from InvoicedLoan
where new.endDate >= startDate and new.endDate <= endDate and new.loanerID = loanerID and new.itemID = itemID)
is not null then 
		raise notice 'You cannot have an item on loan when that item is on loan to someone else during that time';
return null;
else
return new;
end
if;
end
$$
language plpgsql;

create trigger trig1CheckInvoicedLoanClash
before
update or insert on InvoicedLoan
for each row
execute procedure checkLoanDateClash
();


create or replace function checkLoanYourOwnItem
()
returns trigger as
$$
begin
	if (new.loanerID = new.borrowerID) then 
		raise notice 'You cannot make a loan on your own item';
return null;
else
return new;
end
if;
end
$$
language plpgsql;

create trigger trig1CheckLoanYourOwnItem
before
update or insert on InvoicedLoan 
for each row
execute procedure checkLoanYourOwnItem
();


create or replace function checkStartDateEqualsOrAfterEndDate
()
returns trigger as
$$
begin
	if (new.startDate > new.endDate) then 
		raise notice 'Start date cannot be after the end date';
return null;
else
return new;
end
if;
end
$$
language plpgsql;

create trigger trig2CheckStartAndEndDateOfLoan
before
update or insert on InvoicedLoan 
for each row
execute procedure checkStartDateEqualsOrAfterEndDate
();


create or replace function checkOpeningDateEqualsOrAfterClosingDate
()
returns trigger as
$$
begin
	if (new.openingDate > new.closingDate) then 
		raise notice 'Opening date cannot be after the closing date';
return null;
else
return new;
end
if;
end
$$
language plpgsql;

create trigger trig1CheckStartAndEndDateOfAdvertisement
before
update or insert on Advertisement 
for each row
execute procedure checkOpeningDateEqualsOrAfterClosingDate
();


create  or replace function checkMinimumIncreaseIsGreaterThanZero
()
returns trigger as 
$$
begin
	if (new.minimumIncrease <= 0) then 
		raise notice 'Minimum Increase of the bid in an advertisement should be greater than zero';
return null;
else
return new;
end
if;
end
$$
language plpgsql;

create trigger trig2CheckMinimumIncreaseIsGreaterThanZero
before
update or insert on Advertisement
for each row
execute procedure checkMinimumIncreaseIsGreaterThanZero
();





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
	('01-17-2018', 12, 'Refined Music People');


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
	(100);

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
	(null, null, 15, '04-02-2019', '05-04-2019', 2, 3, 3);

INSERT INTO Bid
	(borrowerID,advID,price)
VALUES
	(64, 1, 10),
	(85, 1, 12),
	(76, 1, 14),
	(57, 2, 12);

INSERT INTO Chooses
	(bidID,userID,advID)
VALUES
	(13, 22, 2);


--Invoiced Loan is a loan between the first loaner and the first borrower.  I.e. id 1 and id 41, id 2 and 42 and so on.  
--There are a total of 40 + 15 invoicedLoans.  The later 15 have reviews tagged to them

INSERT INTO InvoicedLoan
	(startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID)
VALUES
	('02-14-2019', '06-27-2019', 15, 6, 1, 42, 201, 1),
	('07-31-2018', '11-19-2018', 11, 2, 2, 43, 202, 2),
	('05-31-2018', '03-26-2019', 12, 5, 3, 44, 203, 3),
	('10-17-2018', '09-30-2019', 12, 9, 4, 45, 204, 4),
	('01-14-2018', '07-14-2018', 17, 5, 5, 46, 205, 5),
	('05-21-2019', '03-26-2020', 10, 3, 6, 47, 206, 6),
	('10-04-2018', '10-10-2018', 19, 3, 7, 48, 207, 7),
	('01-14-2019', '08-26-2019', 14, 2, 8, 49, 208, 8),
	('05-05-2018', '09-16-2018', 14, 7, 9, 50, 209, 9);
--date format is month, day, year



--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

-- Commenting this out for now since it's gonna be changed


--User review item
-- INSERT INTO UserReviewItem
-- 	(userID,itemOwnerID,reviewComment,reviewDate,rating)
-- VALUES
-- 	(58, 11, 'Enjoyable camera to use!  I really like it.', '01-17-2019', 5),
-- 	(59, 22, 'This iPad was not working properly when I got it', '01-12-2019', 1),
-- 	(60, 21, 'This is not as good as the other cameras I used', '02-19-2019', 2);

-- INSERT INTO UserReviewItem
-- 	(userID,itemOwnerID,reviewDate,rating)
-- VALUES
-- 	(46, 11, '01-17-2019', 2),
-- 	(47, 22, '01-12-2019', 4),
-- 	(48, 21, '02-19-2019', 1),
-- 	(49, 11, '01-17-2019', 4),
-- 	(50, 22, '01-12-2019', 1),
-- 	(51, 21, '02-19-2019', 5),
-- 	(52, 11, '01-17-2019', 1),
-- 	(53, 22, '01-12-2019', 4),
-- 	(54, 21, '02-19-2019', 3),
-- 	(55, 11, '01-17-2019', 1),
-- 	(56, 22, '01-12-2019', 2),
-- 	(57, 21, '02-19-2019', 5);

-- INSERT INTO Upvote
-- 	(userID,reviewID)
-- VALUES
-- 	(74, 1),
-- 	(51, 2),
-- 	(56, 3),
-- 	(61, 4),
-- 	(71, 5),
-- 	(86, 6),
-- 	(95, 7),
-- 	(10, 8),
-- 	(16, 9),
-- 	(41, 10),
-- 	(43, 1),
-- 	(94, 1);

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------