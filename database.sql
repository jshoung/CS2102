--user is a superclass, and a user has to be either a loaner or borrower, and can be both
create table UserAccount(
	userID integer,
	name varchar(80) not null,
	address varchar(80) not null,
	primary key (userID)
);

create table Loaner(
	userID integer references UserAccount,
	primary key (userID)
);

create table Borrower(
	userID integer references UserAccount,
	primary key (userID)
);

create table LoanerItem(
	itemID integer,
	value integer,
	userID integer,
	primary key (userID, itemID),
	foreign key (userID) references Loaner on delete cascade
);

--currently startdate can be after end date
--loaner and borrower can be the same person
create table InvoicedLoan(
	startDate date not null,
	endDate date not null,
	penalty integer not null,
	loanFee integer not null,
	loanerID integer not null,
	borrowerID integer not null,
	invoiceID integer,
	itemID integer,
	foreign key (loanerID)references Loaner,
	foreign key (borrowerID) references Borrower,
	foreign key (loanerID, itemID) references LoanerItem,
	primary key (invoiceID)
);

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
INSERT INTO LoanerItem (itemID,value,userID) VALUES (100,5,1),(101,2,2),(102,6,3),(103,3,4),(104,9,5),(105,4,6),(106,2,7),(107,10,8),(108,1,9),(109,6,10);
INSERT INTO LoanerItem (itemID,value,userID) VALUES (110,10,11),(111,9,12),(112,10,13),(113,9,14),(114,6,15),(115,7,16),(116,10,17),(117,1,18),(118,5,19),(119,7,20);
INSERT INTO LoanerItem (itemID,value,userID) VALUES (120,1,21),(121,5,22),(122,2,23),(123,8,24),(124,7,25),(125,7,26),(126,4,27),(127,10,28),(128,7,29),(129,5,30);
INSERT INTO LoanerItem (itemID,value,userID) VALUES (130,5,31),(131,7,32),(132,2,33),(133,8,34),(134,9,35),(135,7,36),(136,6,37),(137,5,38),(138,4,39),(139,6,40);
INSERT INTO LoanerItem (itemID,value,userID) VALUES (140,6,41),(141,6,42),(142,7,43),(143,9,44),(144,6,45),(145,9,46),(146,8,47),(147,6,48),(148,9,49),(149,2,50);

--Invoiced Loan is a loan between the first loaner and the first borrower.  I.e. id 1 and id 41, id 2 and 42 and so on.  
--There are a total of 40 invoicedLoans
--The loan start and end date are not very accurate (endDate can be after startDate), but i guess they will do for now.
INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID) VALUES ('02-19-2019','10-16-2018',14,2,1,41,200,100),('12-14-2019','06-27-2019',15,6,2,42,201,101),('07-31-2019','11-19-2018',11,2,3,43,202,102),('05-31-2019','03-26-2019',12,5,4,44,203,103),('10-17-2018','09-30-2019',12,9,5,45,204,104),('01-14-2020','07-14-2018',17,5,6,46,205,105),('05-21-2019','03-26-2020',10,3,7,47,206,106),('10-14-2018','10-10-2018',19,3,8,48,207,107),('01-14-2019','08-26-2019',14,2,9,49,208,108),('05-05-2019','09-16-2018',14,7,10,50,209,109);
INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID) VALUES ('04-24-2018','06-07-2019',13,4,11,51,210,110),('10-08-2018','12-15-2019',13,8,12,52,211,111),('11-01-2019','02-29-2020',19,2,13,53,212,112),('01-24-2019','06-16-2019',10,7,14,54,213,113),('07-30-2018','05-13-2018',19,3,15,55,214,114),('04-18-2019','05-14-2018',15,6,16,56,215,115),('09-19-2019','10-12-2018',19,5,17,57,216,116),('10-07-2019','01-05-2019',16,2,18,58,217,117),('06-09-2018','06-06-2019',13,8,19,59,218,118),('09-09-2019','10-13-2019',12,8,20,60,219,119);
INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID) VALUES ('11-06-2018','11-11-2018',19,9,21,61,220,120),('03-10-2018','06-11-2018',19,5,22,62,221,121),('07-07-2018','08-02-2019',10,7,23,63,222,122),('09-09-2019','05-13-2019',16,10,24,64,223,123),('04-28-2018','07-22-2018',14,8,25,65,224,124),('09-04-2019','11-08-2018',11,9,26,66,225,125),('06-20-2019','07-22-2019',18,9,27,67,226,126),('04-12-2018','12-28-2018',13,7,28,68,227,127),('05-31-2018','05-12-2018',16,7,29,69,228,128),('05-20-2018','02-13-2019',15,5,30,70,229,129);
INSERT INTO InvoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID) VALUES ('02-09-2020','09-10-2018',10,3,31,71,230,130),('03-27-2019','07-10-2018',16,2,32,72,231,131),('10-29-2018','04-01-2018',10,9,33,73,232,132),('07-24-2019','07-28-2019',17,6,34,74,233,133),('09-24-2018','05-30-2018',10,3,35,75,234,134),('12-08-2019','02-18-2020',16,9,36,76,235,135),('01-18-2019','02-10-2020',16,5,37,77,236,136),('08-09-2018','07-25-2018',10,3,38,78,237,137),('07-24-2018','08-08-2019',10,8,39,79,238,138),('12-08-2019','01-05-2019',13,7,40,80,239,139);
--date format is month, day, year