set datestyle = "mdy";
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
	reportee integer not null,
	primary key (reportID),
	foreign key (reporter) references UserAccount (userID) on delete set null,
	foreign key (reportee) references UserAccount (userID) on delete cascade,
	--You cannot report yourself
	check (reportee != reporter)
);
--group admin cannot simply delete his account.  he needs to hoto responsibilities first.
create table InterestGroup
(
	groupName varchar(80),
	groupDescription varchar(8000) not null,
	groupAdminID integer not null,
	creationDate date not null,
	lastModifiedBy integer not null,
	primary key (groupName),
	foreign key (groupAdminID) references UserAccount (userID) on delete no action,
	foreign key (lastModifiedBy) references UserAccount (userID) on delete no action
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
	eventName varchar(80) not null,
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
	loanFee integer not null, -- in dollars
	loanDuration integer not null, -- in days
	primary key (userID, itemID),
	foreign key (userID) references Loaner (userID) on delete cascade,
	check(loanFee >= 0),
	check(loanDuration > 0)
);

--we want to keep the invoices, as we want to see which item has been borrowed by how many people
create table InvoicedLoan
(
	invoiceID serial,
	startDate date not null,
	endDate date not null,
	penalty integer not null,
	loanFee integer not null,
	loanerID integer not null,
	borrowerID integer,
	itemID integer,
	isReturned boolean default null,
	primary key (invoiceID),
	foreign key (loanerID)references Loaner (userID) on delete cascade,
	foreign key (borrowerID) references Borrower (userID) on delete set null,
	foreign key (loanerID, itemID) references LoanerItem (userID, itemID) on delete cascade,
	check(startDate <= endDate),
	check(loanerID != borrowerID)
);

--we would like the ratings to be between 0 and 5
--users are ony allowed to review an item if they have used that particular item before
--these constraints are enforced in triggers
--if the invoice is deleted, this review should no longer be valid, hence delete.
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
	foreign key (invoiceID) references InvoicedLoan (invoiceID) on delete cascade,
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


-- check startdate cannot clash with current item loans starts, and duration.
-- new invoicedloans should not clash with ads too in this case

--later the chooses will follow this adveretisement specs, and direct insert into loaner item.
create table Advertisement
(
	advID serial,
	highestBidder integer,
	highestBid integer,
	minimumPrice integer not null,
	minimumIncrease integer not null,
	openingDate date not null,
	closingDate date not null,
	advertiser integer,
	itemID integer,
	penalty integer not null,  --default value is the loanerItem penalty, but there is no need to ensure it matches the value in loanerItem at all times.
	loanDuration integer not null, --special duration for ad
	startDate date not null, --special startdate for ads
	endDate date not null,
	itemName varchar(100) not null, --by default follows itemName and description in loanersItem
	itemDescription varchar(8000) not null,
	primary key (advID),
	foreign key (advertiser) references Loaner(userID) on delete cascade,
	foreign key (advertiser, itemID) references LoanerItem(userID, itemID) on delete cascade,
	check(minimumIncrease > 0),
	check(openingDate <= closingDate),
	check(startDate > closingDate),
	check(startDate < endDate),
	check(endDate = startDate + interval '1' day * loanDuration)
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
	chooseDate date not null,
	primary key (userID, bidID, advID),
	foreign key (bidID) references Bid (bidID) on delete cascade,
	foreign key (userID) references Loaner (userID) on delete cascade,
	foreign key (advID) references Advertisement (advID) on delete cascade
);


create or replace function checkSuitableBid()
returns trigger as 
$$
	declare adMinimumIncrease integer;
			previousHighestBid integer;
			adMinimumPrice integer;
			targetAdvOpening date;
			targetAdvClosing date;
			originalAdvertiser integer;
			reportAgainstNum integer;
			windowDate date;
	begin
		windowDate := new.bidDate - interval '7' day;

		select highestBid, minimumIncrease, minimumPrice, openingDate, closingDate, advertiser
		into previousHighestBid, adMinimumIncrease, adMinimumPrice, targetAdvOpening, targetAdvClosing, originalAdvertiser
		from Advertisement
		where advID = new.advID;
	
		select count(*)
		into reportAgainstNum 
		from (select *
			from report 
			where reportDate >= windowDate) as innerCall
		group by reportee 
		having reportee = new.borrowerID;
		
		if (previousHighestBid is null and new.price < adMinimumPrice) then 
			raise exception 'You have to at least bid the minimum price'
				using hint = 'You have to at least bid the minimum price';
			return null;
		elsif
		(previousHighestBid is not null and new.price < previousHighestBid + adMinimumIncrease) then 
			raise exception 'You have to at least bid the highest bid price, plus the minimum increase'
				using hint = 'You have to at least bid the highest bid price, plus the minimum increase';
			return null;
		elsif (new.bidDate < targetAdvOpening or new.bidDate > targetAdvClosing) then
			raise exception 'You can only bid when the adverisement is open'
				using hint = 'You can only bid when the adverisement is open';
			return null;
		elsif (new.borrowerID = originalAdvertiser) then 
			raise exception 'You cannot bid for your own advertisements'
				using hint = 'You cannot bid for your own advertisements';
			return null;
		elsif (reportAgainstNum > 5) then 
			raise exception 'You have too many reports against you in the past week, and so you are not allowed to bid for advertisements'
				using hint = 'You have too many reports against you in the past week, and so you are not allowed to bid for advertisements';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig1SuitableBidTrig
before
update or insert on Bid
for each row
execute procedure checkSuitableBid();


create or replace function checkChoosesYourOwnAdvertisementAndCorrectBidAndAtLeast3Bids()
returns trigger as 
$$
	declare creatorID integer;
			numBids integer;
			advertisementOpeningDate date;
			advertisementClosingDate date;
			loanStartDate date;
	begin
		select advertiser, openingDate, closingDate, startdate
		into creatorID, advertisementOpeningDate, advertisementClosingDate, loanStartDate
		from Advertisement
		where advID = new.advID;
	
		select count(bidID)as numBidsTemp
		from bid 
		into numBids
		group by advID
		having advID = new.advID;
	
		if (new.userID != creatorID) then 
			raise exception 'You can only choose bids that you created the advertisements for'
      			using hint = 'You can only choose bids that you created the advertisements for';
			return null;
		elsif new.bidID not in
		(select bidID
		from Bid
		where advID = new.advID)  then 
			raise exception 'You can only choose the bids for your own advertisement'
     			 using hint = 'You can only choose the bids for your own advertisement';
			return null;
		elsif (numBids < 3 and new.chooseDate <= advertisementClosingDate) then 
			raise exception 'Your advertisement has to have at least 3 bids if you want to choose before the advertisement closes'
     			 using hint = 'Your advertisement has to have at least 3 bids if you want to choose before the advertisement closes';
			return null;
		elsif (new.chooseDate < advertisementOpeningDate) then 
			raise exception 'You can unable to choose before your advertisement has opened'
				using hint = 'You can unable to choose before your advertisement has opened';
		elsif (new.chooseDate >= loanStartDate) then 
			raise exception  'You are unable to choose a bid when the loan was supposed to have already begun'
     			 using hint = 'You are unable to choose a bid when the loan was supposed to have already begun';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig1CheckChoosesYourOwnAdvertisementAndCorrectBidAndAtLeast3Bids
before
update or insert on Chooses
for each row
execute procedure checkChoosesYourOwnAdvertisementAndCorrectBidAndAtLeast3Bids();


create or replace function checkSuitableReview()
returns trigger as 
$$
	declare invoiceDate date;
			invoiceOwner integer;
			oneWeekAgo date;
			twoWeeksAgo date;
			numComplaintsFromOwner integer;
			numComplaintsFromEveryone integer;
	begin
		oneWeekAgo := new.reviewDate - interval '7' day;
		twoWeeksAgo := new.reviewDate - interval '14' day;

		select startdate, borrowerID
		into invoiceDate, invoiceOwner
		from invoicedLoan
		where invoiceID = new.invoiceID;
	
		select count(*)
		into numComplaintsFromOwner
		from (select * 
			from report
			where reportDate >= oneWeekAgo and reporter = new.itemOwnerID) as innerCall
		group by reportee
		having (reportee = new.userID);
	
		select count(*)
		into numComplaintsFromEveryone
		from (
			select * 
			from report
			where reportDate >= twoWeeksAgo and reportee = new.userID) as innerCall
		group by reportee
		having reportee = new.userID;
		
	
		if (new.reviewDate < invoiceDate) then 
			raise exception 'Reviews cannot be written before the loan begins'
				using hint = 'Reviews cannot be written before the loan begins';
			return null;
		elsif(new.userID != invoiceOwner) then 
			raise exception 'Reviews can only be written with reference to your own invoices, and not someone elses'
				using hint = 'Reviews can only be written with reference to your own invoices, and not someone elses';
			return null;
		elsif(numComplaintsFromOwner != 0) then 
			raise exception 'Sorry you cannot write a review now because the item owner has made a reports against you this week.  Perhaps you could take some time to cool off'
				using hint = 'Sorry you cannot write a review now because the item owner has made a reports against you this week.  Perhaps you could take some time to cool off';
			return null;
		elsif(numComplaintsFromEveryone >3) then 
			raise exception 'Sorry you cannot write a review now because you have more than 3 reports against you in the past 2 weeks.  Perhaps you could take some time to cool off'
				using hint = 'Sorry you cannot write a review now because you have more than 3 reports against you in the past 2 weeks.  Perhaps you could take some time to cool off';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig1CheckSuitableReview
before
update or insert on UserReviewItem
for each row
execute procedure checkSuitableReview();


create or replace function checkLoanDateClash()
returns trigger as
$$
	begin
		if (select max(invoiceID)
		from InvoicedLoan
		where new.startDate >= startDate and new.startDate <= endDate and new.loanerID = loanerID and new.itemID = itemID and new.invoiceID != invoiceID) is not null then 
			raise exception  'You cannot begin a loan when that item is on loan during that time'
    			  using hint = 'You cannot begin a loan when that item is on loan during that time';
			return null;
		elsif
		(select max(invoiceID)
		from InvoicedLoan
		where new.endDate >= startDate and new.endDate <= endDate and new.loanerID = loanerID and new.itemID = itemID and new.invoiceID != invoiceID) is not null then 
			raise exception 'You cannot have an item on loan when that item is on loan to someone else during that time'
     			 using hint = 'You cannot have an item on loan when that item is on loan to someone else during that time';
			return null;
		elsif
		(select max(invoiceID)
		from InvoicedLoan
		where new.startDate <= startDate and new.endDate >= endDate and new.loanerID = loanerID and new.itemID = itemID and new.invoiceID != invoiceID) is not null then 
			raise exception 'You cannot have an item on loan when that item is on loan to someone else within that time'
     			 using hint = 'You cannot have an item on loan when that item is on loan to someone else within that time';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig1CheckInvoicedLoanClash
before
insert or update on InvoicedLoan
for each row
execute procedure checkLoanDateClash();


create or replace function checkInvoicedLoanClashWithCurrentAdvertisement()
returns trigger as
$$
	declare correctBorrowerID integer;
			correctLoanFee integer;
			correspondingAdvID integer;
			correspondingBidID integer;
			
			
	--only the borrower who won the bid should be allowed to loan during that time.
	begin
		select advID
		into correspondingAdvID
		from advertisement
		where new.loanerID = advertiser and new.itemID = itemID and new.startDate = startDate and new.endDate = endDate;
	
		select bidID 
		into correspondingBidID
		from chooses
		where advID = correspondingAdvID;
	
		select borrowerID, price
		into correctBorrowerID, correctLoanFee
		from bid 
		where bidID = correspondingBidID;
		
		
		if (select max(advID)
		from Advertisement
		where new.startDate = startDate and new.endDate = endDate and new.loanerID = advertiser and new.itemID = itemID and new.borrowerID = correctBorrowerID and new.loanFee = correctLoanFee) is not null then 
			--only the borrower who won the bid should be allowed to loan during that time, and only exactly that time, for that price
			return new;
		elsif (select max(advID)
		from Advertisement
		where new.startDate >= startDate and new.startDate <= endDate and new.loanerID = advertiser and new.itemID = itemID) is not null then 
			raise exception  'You cannot begin a loan when that item is advertised to be on loan during that time'
				using hint = 'You cannot begin a loan when that item is advertised to be on loan during that time';
			return null;
		elsif
		(select max(advID)
		from Advertisement
		where new.endDate >= startDate and new.endDate <= endDate and new.loanerID = advertiser and new.itemID = itemID) is not null then 
			raise exception 'You cannot have an item on loan when that item is advertised to be on loan during that time'
				using hint = 'You cannot have an item on loan when that item is advertised to be on loan during that time';
			return null;
		elsif
		(select max(advID)
		from Advertisement
		where new.startDate <= startDate and new.endDate >= endDate and new.loanerID = advertiser and new.itemID = itemID) is not null then 
			raise exception 'You cannot have an item on loan when that item is advertised to be on loan within that time'
				using hint = 'You cannot have an item on loan when that item is advertised to be on loan within that time';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig2CheckInvoicedLoanClashWithCurrentAdvertisement
before
insert or update on InvoicedLoan
for each row
execute procedure checkInvoicedLoanClashWithCurrentAdvertisement();


create or replace function checkItemAlreadyLost()
returns trigger as
$$
	begin
		if (select max(invoiceID)
		from InvoicedLoan
		where new.loanerID = loanerID and new.itemID = itemID and new.invoiceID != invoiceID and (isReturned = false )) is not null then 
			raise exception  'You cannot begin a loan or modify previous loans when that item is already lost'
    			  using hint = 'You cannot begin a loan  or modify previous loans when that item is already lost';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig3CheckItemAlreadyLost
before
insert or update on InvoicedLoan
for each row
execute procedure checkItemAlreadyLost();


create  or replace function checkLoanDateWithinAdvertisementForTheSameItemDoesNotClash()
returns trigger as 
$$
	begin
		if(select max(advID)
		from advertisement
		where new.startDate >= startDate and new.startDate <= endDate and new.advertiser = advertiser and new.itemID = itemID and new.advID != advID) is not null then 
			raise exception  'You cannot advertise an item for a loan period that starts when it is currently already on loan for the same loan period'
     		 	using hint = 'You cannot advertise an item for a loan period that starts when it is currently already on loan for the same loan period';
			return null;
		elsif(select max(advID)
			from advertisement
			where new.endDate >= startDate and new.endDate <= endDate and new.advertiser = advertiser and new.itemID = itemID and new.advID != advID) is not null then 
			raise exception 'You cannot advertise an item for a loan period that ends when it is currently already being advertised for the same loan period'
      			using hint = 'You cannot advertise an item for a loan period that ends when it is currently already being advertised for the same loan period';
			return null;
		elsif(select max(advID)
			from advertisement
			where new.startDate <= startDate and new.endDate >= endDate and new.advertiser = advertiser and new.itemID = itemID and new.advID != advID) is not null then 
			raise exception 'You cannot advertise an item for a loan period that is currently already being advertised for the same loan period'
     			 using hint = 'You cannot advertise an item for a loan period that is currently already being advertised for the same loan period';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig1CheckLoanDateWithinAdvertisementForTheSameItemDoesNotClash
before
update or insert on Advertisement
for each row
execute procedure checkLoanDateWithinAdvertisementForTheSameItemDoesNotClash();


create  or replace function checkLoanDateWithinAdvertisementForTheSameItemDoesNotClashWithExistingInvoicedLoans()
returns trigger as 
$$
	begin
		if(select max(loanerID)
		from invoicedLoan
		where new.startDate >= startDate and new.startDate <= endDate and new.advertiser = loanerID and new.itemID = itemID) is not null then 
			raise exception  'You cannot advertise an item for a loan period that start when it is currently already on loan for that period'
				using hint = 'You cannot advertise an item for a loan period that start when it is currently already on loan for that period';
			return null;
		elsif(select max(loanerID)
			from invoicedLoan
			where new.endDate >= startDate and new.endDate <= endDate and new.advertiser = loanerID and new.itemID = itemID) is not null then 
			raise exception 'You cannot advertise an item for a loan period that ends when it is currently already on loan for that period'
				using hint =  'You cannot advertise an item for a loan period that ends when it is currently already on loan for that period';
			return null;
		elsif(select max(loanerID)
			from invoicedLoan
			where new.startDate <= startDate and new.endDate >= endDate and new.advertiser = loanerID and new.itemID = itemID) is not null then 
			raise exception 'You cannot advertise an item for a loan period that is currently already on loan for that period'
				using hint = 'You cannot advertise an item for a loan period that is currently already on loan for that period';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig2CheckLoanDateWithinAdvertisementForTheSameItemDoesNotClashWithExistingInvoicedLoans
before
update or insert on Advertisement
for each row
execute procedure checkLoanDateWithinAdvertisementForTheSameItemDoesNotClashWithExistingInvoicedLoans();


create or replace function checkAdvertisedItemNotAlreadyLost()
returns trigger as
$$
	begin
		if (select max(invoiceID)
		from InvoicedLoan
		where new.advertiser = loanerID and new.itemID = itemID and (isReturned = false )) is not null then 
			raise exception  'You cannot advertise or modify previous advertisements for an item when that item is already lost'
    			  using hint = 'You cannot advertise or modify previous advertisements for an item when that item is already lost';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;


create trigger trig3CheckAdvertisedItemNotAlreadyLost
before
update or insert on Advertisement
for each row
execute procedure checkAdvertisedItemNotAlreadyLost();


create  or replace function checkCreatorCannotLeave()
returns trigger as 
$$
	declare groupLeader integer;
	begin
		select groupAdminID
		into groupLeader
		from InterestGroup 
		where old.groupName = groupName;
		if(old.userID = groupLeader) then 
			raise exception  'The group admin cannot leave the group, you have to hand over responsibilities first'
				 using hint = 'The group admin cannot leave the group, you have to hand over responsibilities first';
			return null;
		else
			return old;
		end if;
	end
$$
language plpgsql;

create trigger trig1CheckCreatorCannotLeave
before
delete on Joins
for each row
execute procedure checkCreatorCannotLeave();


create  or replace function checkSuccessorMustBeMember()
returns trigger as 
$$
	declare currentGroupAdminID integer;
			successorID integer;
	begin
		select groupAdminID
			into currentGroupAdminID
			from InterestGroup
			where new.groupName = groupName;
		
		select userID
			into successorID
			from Joins
			where new.groupName = groupName and new.groupAdminID = userID;
		
		if(currentGroupAdminID != new.groupAdminID and (successorID is null) ) then 
			raise exception 'The new group admin has to be have joined this group'
				using hint = 'The new group admin has to be have joined this group';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig1CheckSuccessorMustBeMember
before
update on InterestGroup
for each row
execute procedure checkSuccessorMustBeMember();


create  or replace function checkOnlyGroupAdminCanMakeChangesButNoOneCanChangeCreationDate()
returns trigger as 
$$
	declare currentAdminID integer;
			currentCreationDate date;
	begin
		select groupAdminID, creationDate
		into currentAdminID, currentCreationDate
		from interestGroup 
		where groupName = new.groupName;
	
		if(new.creationDate != currentCreationDate) then 
			raise exception 'Creation date should never be changed'
				using hint = 'Creation date should never be changed';

			return null;
	
		elsif(new.lastModifiedBy != currentAdminID)then 
			raise exception 'Only the group admin can make changes to group details'
      			using hint = 'Only the group admin can make changes to group details';
			return null;
		else
			return new;
		end if;
	end
$$
language plpgsql;

create trigger trig2CheckOnlyGroupAdminCanMakeChangesButNoOneCanChangeCreationDate
before
update on InterestGroup
for each row
execute procedure checkOnlyGroupAdminCanMakeChangesButNoOneCanChangeCreationDate();

-- Procedures
drop procedure if exists insertNewBid, insertNewInterestGroup, updateInterestGroupAdmin, insertNewAdvertisement, insertNewChooses, updateChooses, deleteChooses, updateStatusOfLoanedItem;


create or replace procedure deleteChooses(oldUserID integer, oldAdvID integer)
as
$$
	declare oldStartDate date;
			oldEndDate date;
			oldLoanerID integer; --should be the advertiser
			oldItemID integer; --should be the itemID of the advertisement item
			
	begin	
		delete from chooses
		where advID  = oldAdvID and userID = oldUserID;
		
		select startDate, endDate, advertiser, itemID
		into oldStartDate, oldEndDate, oldLoanerID, oldItemID
		from advertisement
		where oldAdvID = advID;
		
		delete from invoicedLoan
		where loanerID = oldLoanerID and itemID = oldItemID and startDate = oldStartDate and endDate = oldEndDate;
		
	commit;
	end;
$$
language plpgsql;


create or replace procedure updateChooses(newBidID integer, newUserID integer, newAdvID integer, newChooseDate date)
as
$$
	declare newStartDate date;
			newEndDate date;
			newPenalty integer;
			newLoanDuration integer;
			newLoanerID integer; --should be the advertiser
			newItemID integer; --should be the itemID of the advertisement item
			
			newLoanFee integer; -- bidprice, can see from the bidID
			newBorrowerID integer; --can see from the bidID
			
	begin	
		update chooses
		set bidID = newBidID,
			chooseDate = newChooseDate 
		where userID = newUserID and advID = newAdvID;
		
		select startDate, endDate, penalty, loanDuration, advertiser, itemID
		into newStartDate, newEndDate, newPenalty, newLoanDuration, newLoanerID, newItemID
		from advertisement
		where newAdvID = advID;
	
		select price, borrowerID
		into newLoanFee, newBorrowerID
		from bid
		where newBidID = bidID;
		
		update invoicedLoan
		set loanFee = newLoanFee, borrowerID = newBorrowerID
		where loanerID = newLoanerID and itemID = newItemID and startDate = newStartDate and endDate = newEndDate;
		
	commit;
	end;
$$
language plpgsql;


create or replace procedure insertNewChooses(newBidID integer, newUserID integer, newAdvID integer, newChooseDate date)
as
$$
	declare newStartDate date;
			newEndDate date;
			newPenalty integer;
			newLoanDuration integer;
			newLoanerID integer; --should be the advertiser
			newItemID integer; --should be the itemID of the advertisement item
			
			newLoanFee integer; -- bidprice, can see from the bidID
			newBorrowerID integer; --can see from the bidID
			
	begin	
		insert into chooses (bidID, userID, advID, chooseDate) values 
		(newBidID, newUserID, newAdvID, newChooseDate);
		
		select startDate, endDate, penalty, loanDuration, advertiser, itemID
		into newStartDate, newEndDate, newPenalty, newLoanDuration, newLoanerID, newItemID
		from advertisement
		where newAdvID = advID;
	
		select price, borrowerID
		into newLoanFee, newBorrowerID
		from bid
		where newBidID = bidID;
		
	
		insert into invoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,itemID) values 
		(newStartDate, newEndDate, newPenalty, newLoanFee, newLoanerID, newBorrowerID, newItemID);
		
	commit;
	end;
$$
language plpgsql;


create or replace procedure insertNewAdvertisement(newMinimumPrice integer,newOpeningDate date,newClosingDate date,newMinimumIncrease integer,newAdvertiser integer,newItemID integer, newLoanDuration integer, newStartDate date)
as
$$
	declare newPenalty integer;
			newItemName varchar(100);
			newItemDescription varchar(8000);
			newEndDate date;
			
	begin
		newEndDate := newStartDate + interval '1' day * newLoanDuration;
		select value, itemDescription, itemName
		into newPenalty, newItemDescription,  newItemName
		from loanerItem 
		where newAdvertiser = userID and newItemID = itemID;
		insert into Advertisement (highestBidder,highestBid,minimumPrice,openingDate,closingDate,minimumIncrease,advertiser,itemID, loanDuration, penalty, startDate, endDate, itemName, itemDescription) values 
		(null,null,newMinimumPrice,newOpeningDate,newClosingDate,newMinimumIncrease,newAdvertiser,newItemID, newLoanDuration, newPenalty, newStartDate, newEndDate, newItemName, newItemDescription);
		
	commit;
	end;
$$
language plpgsql;
create or replace procedure insertNewInterestGroup(newGroupName varchar(80),newGroupDescription varchar(8000),newGroupAdminID integer,newCreationDate date)
as
$$
	begin
		insert into InterestGroup (groupName, groupDescription, groupAdminID, creationDate, lastModifiedBy) values 
		(newGroupName, newGroupDescription, newGroupAdminID, newCreationDate, newGroupAdminID);

		insert into Joins (joinDate, userID, groupname) values
		(newCreationDate, newGroupAdminID, newGroupName);
		
	commit;
	end;
$$
language plpgsql;

create or replace procedure updateInterestGroup(newLastModifiedBy integer, newGroupName varchar(80),newGroupAdminID integer, newGroupDescription varchar(8000))
as
$$
	begin

		update InterestGroup
		set lastModifiedBy = newLastModifiedBy, groupAdminID = newGroupAdminID, groupDescription = newGroupDescription
		where groupName = newGroupName;
		
	commit;
	end;
$$
language plpgsql;

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


create or replace procedure insertNewInvoicedLoan(newStartDate date, newLoanerID integer,newBorrowerID integer,newItemID integer)
as
$$
	declare newEndDate date;
			newPenalty integer;
			newLoanFee integer;
			currentLoanDuration integer;
	begin	
		select value, loanFee, loanDuration
		into newPenalty, newLoanFee, currentLoanDuration
		from loanerItem
		where newLoanerID = userID and newItemID = itemID;
		
		newEndDate := newStartDate + interval '1' day * currentLoanDuration;
		insert into invoicedLoan (startDate,endDate,penalty,loanFee,loanerID,borrowerID,itemID) values 
		(newStartDate, newEndDate, newPenalty, newLoanFee, newLoanerID, newBorrowerID, newItemID);
		
	commit;
	end;
$$
language plpgsql;


create or replace procedure updateStatusOfLoanedItem(newIsReturned boolean, newInvoiceID integer)
as
$$
	declare loanEndDate date;
			newLoanerID integer;
			newItemID integer;
	begin
		select endDate, loanerId, itemID
		into loanEndDate, newLoanerID, newItemID
		from invoicedLoan  
		where invoiceID = newInvoiceID;

		update invoicedLoan
		set isReturned = newIsReturned
		where invoiceID = newInvoiceID;
		
		if (not newIsReturned) then 
			delete from invoicedLoan where loanerID = newLoanerID and itemID = newItemID and (loanEndDate <= startDate) and (invoiceID != newInvoiceID);
			delete from advertisement where advertiser = newLoanerID and itemID = newItemID and (loanEndDate <= startDate);
		end if;
	
	commit;
	end;
$$
language plpgsql;


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
	('No manners', '04-24-2017', 'This person never reply me with smiley face', 1, 2),
	('Self-entitled', '04-24-2017', 'This person thinks he deserves a smiley face', 2, 1),
	('Pedophile', '03-23-2018', 'This person is insinuating pedophilic actions and comments', 1, 7);
INSERT INTO Report
	(title,reportDate,reporter,reportee)
VALUES
	('Rude', '01-15-2018', 9, 2),
	('Bad vibes', '02-22-2018', 15, 2),
	('Salty person', '03-15-2018', 35, 2),
	('Rude', '01-15-2018', 19, 2),
	('Bad negotiator', '02-14-2018', 83, 2),
	('Not gentleman/gentlewoman', '03-14-2018', 74, 2),
	( 'No basic respect', '03-29-2018', 25, 2);

--5 groups are created, only the first 3 have descriptions.
call insertNewInterestGroup('Photography Club','For all things photos',1,'02-22-2016');
call insertNewInterestGroup('Spiderman Fans','Live and Die by the web',5,'02-22-2016');
call insertNewInterestGroup('Tech Geeks','Self-explanatory.  We like tech && are geeks',8,'02-22-2016');
call insertNewInterestGroup('Refined Music People','pish-posh',3,'02-22-2016');
call insertNewInterestGroup('Clothes Club','forever 22 i guess',1,'02-22-2016');


--We have userAccounts joining interestgroups
INSERT INTO Joins
	(joinDate, userID, groupname)
VALUES
	('02-21-2017', 2, 'Photography Club'),
	('02-24-2017', 3, 'Photography Club'),
	('02-22-2017', 4, 'Photography Club'),
	('02-27-2017', 2, 'Clothes Club'),
	('02-17-2017', 4, 'Refined Music People'),
	('01-21-2017', 6, 'Spiderman Fans'),
	('01-24-2017', 7, 'Spiderman Fans'),
	('01-20-2017', 9, 'Tech Geeks'),
	('01-27-2017', 10, 'Clothes Club'),
	('01-15-2017', 11, 'Refined Music People'),
	('01-17-2017', 12, 'Refined Music People'),
	('04-14-2016', 48, 'Refined Music People');

INSERT INTO OrganizedEvent
	(eventDate,eventName,venue,organizer)
VALUES
	('01-17-2018', 'Beach Photography', 'East Coast Park', 'Photography Club'),
	('01-18-2018', 'Blockchain tech: Smart Contracts','Suntec City', 'Tech Geeks'),
	('01-19-2018', 'Adventures of Spoderman','Vivocity Movie Theatre', 'Spiderman Fans'),
	('02-17-2018','High Street Fashion Competition', 'Scape', 'Clothes Club'),
	('07-17-2018', 'A Night with Beethoven','Esplanade', 'Refined Music People');


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
	(itemName,value,itemDescription,userID,loanFee,loanDuration)
VALUES
	('Fuji Camera', 500, 'Hello All, renting out a immaculate condition Camera, lightly used without usage mark. Shutter click less the 3k. Comes with all standard accessories. Self collect only at Blk 421 Hougang Ave 10, low ballers stayout.', 1, 50, 5),
	('iPad Pro', 200, 'As good as new with no signs if usage, item in perfect condition, bought on 17th June 2016 Locally, finest tempered glass on since bought. Comes with warranty,  box and all standard accessories. Will throw in Apple original pencil, 3rd party book case.', 2, 40, 2),
	('Toshiba Laptop', 600, 'Very good condition, Well kept and still looks new, Condition 9/10, No Battery, Intel Core(TM) 2 Duo CPU T6600 @ 2.2 GHz, DDR2 SDRAM, HDD 500GB, Memory 2GB, Windows 7 Professional', 3, 10, 1),
	('Sony Headphones', 300, 'Hello renting a as good as new headphone , used less then 1 hr. Renting as seldom used. Comes with all standard accessories . Item is perfect conditioning with zero usage marks. Item is bought from Expansys on 24th Nov 2017. Price is firm and Low baller will be ignored.  First offer first serve . Thank you ', 4, 30, 3),
	('Canon Camera Lens', 900, 'Hello all renting a full working condition lens with no box,  receipt,  warranty.  Item physical condition is 8/10.  With only light users mark which is only visible on strong sunlight. ', 5, 50, 5),
	('Black Tuxedo', 400, 'Who doesnt love a black tuxedo', 6, 10, 1),
	('Pink Shoes', 200, 'Not only for pedophiles', 7, 0, 2),
	('Metal Watch', 100, 'To impress that girl and make her think that you are rich', 8, 5, 3),
	('Vintage Music CD', 100, 'Put this in your uni dorm to make visitors think that you are cultured', 9, 1, 10),
	('Spiderman Movie', 60, 'Shoot webs and fight crime with your favourite neighbourhood superhero', 10, 2, 3);
INSERT INTO LoanerItem
	(itemName,value,userID, loanFee, loanDuration)
VALUES
	('Fuji Camera', 100, 11, 10, 2),
	('iPad Pro', 900, 12, 100, 6),
	('Toshiba Laptop', 100, 13, 50, 2),
	('Sony Headphones', 900, 14, 50, 5),
	('Canon Camera Lens', 600, 15, 30, 4),
	('Black Tuxedo', 700, 16, 50, 7),
	('Pink Shoes', 100, 17, 2, 5),
	('Metal Watch', 100, 18, 0, 1),
	('Vintage Music CD', 500, 19, 5, 7),
	('Spiderman Movie', 700, 20, 10, 5),
	('Fuji Camera', 100, 21, 10, 3),
	('iPad Pro', 500, 22, 50, 4),
	('Toshiba Laptop', 200, 23, 30, 3),
	('Sony Headphones', 800, 24, 40, 5),
	('Canon Camera Lens', 700, 25, 65, 3),
	('Black Tuxedo', 700, 26, 10, 1),
	('Pink Shoes', 400, 27, 3, 2),
	('Metal Watch', 100, 28, 12, 3),
	('Vintage Music CD', 700, 29, 30, 3),
	('Spiderman Movie', 500, 30, 5, 2),
	('Fuji Camera', 500, 31, 50, 5),
	('iPad Pro', 700, 32, 100, 7),
	('Toshiba Laptop', 200, 33, 20, 3),
	('Sony Headphones', 800, 34, 55, 4),
	('Canon Camera Lens', 900, 35, 56, 2),
	('Black Tuxedo', 700, 36, 52, 6),
	('Pink Shoes', 600, 37, 0, 1),
	('Metal Watch', 500, 38, 0, 2),
	('Vintage Music CD', 400, 39, 31, 2),
	('Spiderman Movie', 600, 40, 41, 3),
	('Fuji Camera', 600, 41, 36, 5),
	('iPad Pro', 600, 42, 65, 4),
	('Toshiba Laptop', 700, 43, 33, 3),
	('Sony Headphones', 900, 44, 56, 8),
	('Canon Camera Lens', 600, 45, 66, 3),
	('Black Tuxedo', 900, 46, 56, 3),
	('Pink Shoes', 800, 47, 65, 3),
	('Metal Watch', 600, 48, 11, 2),
	('Vintage Music CD', 900, 49, 32, 5),
	('Spiderman Movie', 200, 50, 26, 1);

call insertNewAdvertisement(10, '03-01-2018', '05-01-2018', 2, 1, 1,5,'05-01-2019');
call insertNewAdvertisement(12, '01-04-2018', '04-02-2018', 2, 2, 2,6,'04-02-2019');
call insertNewAdvertisement(5, '04-02-2018', '05-04-2018', 2, 3, 3,7,'05-04-2021');
call insertNewAdvertisement(10, '03-01-2018', '05-01-2018', 2, 4, 4,5,'05-01-2019');
call insertNewAdvertisement(12, '01-04-2018', '07-02-2018', 2, 5, 5,6,'07-02-2019');
call insertNewAdvertisement(15, '04-02-2018', '05-04-2018', 2, 6, 6,7,'05-04-2019');
call insertNewAdvertisement(10, '03-01-2018', '05-01-2018', 2, 7, 7,5,'05-01-2019');
call insertNewAdvertisement(12, '01-04-2018', '07-02-2018', 2, 8, 8,7,'07-02-2019');
call insertNewAdvertisement(15, '04-02-2018', '05-04-2018', 2, 9, 9,5,'05-04-2019');
call insertNewAdvertisement(15, '04-02-2019', '05-04-2019', 2, 9, 9,5,'05-04-2020'); --we would use this for our demo

call insertNewBid(64, 1,'03-01-2018',10);
call insertNewBid(49, 1,'03-02-2018',12);
call insertNewBid(85, 1,'03-03-2018',14);
call insertNewBid(76, 1,'03-04-2018',16);
call insertNewBid(57, 2,'01-04-2018',12);
call insertNewBid(64, 3,'04-02-2018',15);
call insertNewBid(49, 3,'05-03-2018',17);
call insertNewBid(85, 3,'05-04-2018',19);
call insertNewBid(85, 4,'03-01-2018',14);
call insertNewBid(76, 4,'03-02-2018',16);
call insertNewBid(76, 5,'01-04-2018',18);
call insertNewBid(64, 5,'02-04-2018',20);
call insertNewBid(57, 6,'04-02-2018',15);
call insertNewBid(49, 6,'04-03-2018',17);
call insertNewBid(57, 6,'04-03-2018',19);
call insertNewBid(64, 7,'03-01-2018',10);
call insertNewBid(49, 7,'04-02-2018',12);
call insertNewBid(57, 7,'04-02-2018',14);
call insertNewBid(85, 8,'02-04-2018',12);
call insertNewBid(76, 9,'05-02-2018',16);
	

--Invoiced Loan is a loan between the first loaner and the first borrower.  I.e. id 1 and id 41, id 2 and 42 and so on.  
--There are a total of 40 + 15 invoicedLoans.  The later 15 have reviews tagged to them

call insertNewInvoicedLoan('02-19-2017', 1,41,1);
call insertNewInvoicedLoan('02-14-2018',2,42,2);
call insertNewInvoicedLoan('07-31-2017',3,43,3);
call insertNewInvoicedLoan('05-31-2017',4,44,4);
call insertNewInvoicedLoan('10-17-2017',5,45,5);
call insertNewInvoicedLoan('01-14-2017',6,46,6);
call insertNewInvoicedLoan('05-21-2018',7,47,7);
call insertNewInvoicedLoan('10-04-2017',8,48,8);
call insertNewInvoicedLoan('01-14-2018',9,49,9);
call insertNewInvoicedLoan('05-05-2017',10,50,10);
call insertNewInvoicedLoan('04-24-2017',11,51,11);
call insertNewInvoicedLoan('10-08-2017',12,52,12);
call insertNewInvoicedLoan('11-01-2018',13,53,13);
call insertNewInvoicedLoan('01-24-2018',14,54,14);
call insertNewInvoicedLoan('07-30-2016',15,55,15);
call insertNewInvoicedLoan('04-18-2017',16,56,16);
call insertNewInvoicedLoan('09-19-2017',17,57,17);
call insertNewInvoicedLoan('10-07-2017',18,58,18);
call insertNewInvoicedLoan('06-09-2017',19,59,19);
call insertNewInvoicedLoan('09-09-2018',20,60,20);
call insertNewInvoicedLoan('10-06-2017',21,61,21);
call insertNewInvoicedLoan('03-10-2017',22,62,22);
call insertNewInvoicedLoan('07-07-2017',23,63,23);
call insertNewInvoicedLoan('09-09-2017',24,64,24);
call insertNewInvoicedLoan('04-28-2017',25,65,25);
call insertNewInvoicedLoan('09-04-2017',26,66,26);
call insertNewInvoicedLoan('06-20-2017',27,67,27);
call insertNewInvoicedLoan('04-12-2017',28,68,28);
call insertNewInvoicedLoan('03-31-2017',29,69,29);
call insertNewInvoicedLoan('05-20-2017',30,70,30);
call insertNewInvoicedLoan('02-09-2017',31,71,31);
call insertNewInvoicedLoan('03-27-2017',32,72,32);
call insertNewInvoicedLoan('10-29-2016',33,73,33);
call insertNewInvoicedLoan('07-24-2018',34,74,34);
call insertNewInvoicedLoan('09-24-2016',35,75,35);
call insertNewInvoicedLoan('12-08-2018',36,76,36);
call insertNewInvoicedLoan('01-18-2018',37,77,37);
call insertNewInvoicedLoan('06-09-2017',38,78,38);
call insertNewInvoicedLoan('07-24-2017',39,79,39);
call insertNewInvoicedLoan('12-08-2018',40,80,40);


call insertNewInvoicedLoan('02-14-2018', 1, 42, 1);
call insertNewInvoicedLoan('07-31-2017', 2, 43, 2);
call insertNewInvoicedLoan('05-31-2017', 3, 44, 3);
call insertNewInvoicedLoan('10-17-2017', 4, 45, 4);
call insertNewInvoicedLoan('01-14-2017', 1, 46, 1);
call insertNewInvoicedLoan('06-21-2018', 2, 47, 2);
call insertNewInvoicedLoan('10-04-2017', 3, 48, 3);
call insertNewInvoicedLoan('01-14-2018', 1, 49, 1);
call insertNewInvoicedLoan('05-05-2017', 2, 50, 2);
call insertNewInvoicedLoan('04-24-2017', 3, 51, 3);
call insertNewInvoicedLoan('09-17-2018', 1, 52, 1);
call insertNewInvoicedLoan('02-14-2017', 2, 53, 2);
call insertNewInvoicedLoan('03-10-2017', 3, 54, 3);
call insertNewInvoicedLoan('09-10-2018', 1, 55, 1);
call insertNewInvoicedLoan('08-14-2018', 2, 56, 2);
call insertNewInvoicedLoan('09-05-2017', 3, 57, 3);
call insertNewInvoicedLoan('02-05-2017', 2, 57, 2);
call insertNewInvoicedLoan('07-10-2018', 1, 64, 1);
call insertNewInvoicedLoan('02-03-2016', 3, 1, 3);
call insertNewInvoicedLoan('09-17-2019', 1, 52, 1);
--date format is month, day, year

call insertNewChooses(5,2,2, '10-03-2018');

call updateStatusOfLoanedItem(True, 1);
call updateStatusOfLoanedItem(True, 2);
call updateStatusOfLoanedItem(True, 3);
call updateStatusOfLoanedItem(True, 4);
call updateStatusOfLoanedItem(True, 5);
call updateStatusOfLoanedItem(True, 6);
call updateStatusOfLoanedItem(True, 7);
call updateStatusOfLoanedItem(True, 8);
call updateStatusOfLoanedItem(True, 9);
call updateStatusOfLoanedItem(True,10);
call updateStatusOfLoanedItem(True,11);
call updateStatusOfLoanedItem(True,12);
call updateStatusOfLoanedItem(True,13);
call updateStatusOfLoanedItem(True,14);
call updateStatusOfLoanedItem(True,15);
call updateStatusOfLoanedItem(True,16);
call updateStatusOfLoanedItem(True,17);
call updateStatusOfLoanedItem(True,18);
call updateStatusOfLoanedItem(True,19);
call updateStatusOfLoanedItem(True,20);
call updateStatusOfLoanedItem(True,21);
call updateStatusOfLoanedItem(True,22);
call updateStatusOfLoanedItem(True,23);
call updateStatusOfLoanedItem(True,24);
call updateStatusOfLoanedItem(True,25);
call updateStatusOfLoanedItem(True,26);
call updateStatusOfLoanedItem(True,27);
call updateStatusOfLoanedItem(True,28);
call updateStatusOfLoanedItem(True,29);
call updateStatusOfLoanedItem(True,30);
call updateStatusOfLoanedItem(True,31);
call updateStatusOfLoanedItem(True,32);
call updateStatusOfLoanedItem(True,33);
call updateStatusOfLoanedItem(True,34);
call updateStatusOfLoanedItem(True,35);
call updateStatusOfLoanedItem(True,36);
call updateStatusOfLoanedItem(True,37);
call updateStatusOfLoanedItem(True,38);
call updateStatusOfLoanedItem(True,39);
call updateStatusOfLoanedItem(True,40);
call updateStatusOfLoanedItem(True,41);
call updateStatusOfLoanedItem(True,42);
call updateStatusOfLoanedItem(True,43);
call updateStatusOfLoanedItem(True,44);
call updateStatusOfLoanedItem(True,45);
call updateStatusOfLoanedItem(True,46);
call updateStatusOfLoanedItem(True,47);
call updateStatusOfLoanedItem(True,48);
call updateStatusOfLoanedItem(True,49);
call updateStatusOfLoanedItem(True,50);
call updateStatusOfLoanedItem(True,52);
call updateStatusOfLoanedItem(True,53);
call updateStatusOfLoanedItem(True,54);
call updateStatusOfLoanedItem(True,55);
call updateStatusOfLoanedItem(True,56);
call updateStatusOfLoanedItem(True,57);
call updateStatusOfLoanedItem(True,58);
call updateStatusOfLoanedItem(True,59);
call updateStatusOfLoanedItem(True,60);


INSERT INTO UserReviewItem
 	(userID,itemOwnerID,itemID,reviewComment,reviewDate,rating,invoiceID)
VALUES
 	(42, 1,1, 'Enjoyable camera to use!  I really like it.', '02-17-2018', 5,41),
 	(43, 2,2, 'This iPad was not working properly when I got it', '01-12-2018', 1,42),
 	(44, 1,1, 'This is not as good as the other cameras I used', '02-19-2018', 2,43),
 	(1, 3, 3, 'This Toshiba laptop is an ancient beauty','06-02-2016', 5,59);

 
INSERT INTO UserReviewItem
 	(userID,itemOwnerID,itemID,reviewDate,rating,invoiceID)
VALUES
 	(46, 1,1, '01-17-2018', 2,45),
 	(47, 2,2, '10-12-2018', 4,46),
 	(48, 3,3, '02-19-2018', 1,47),
 	(49, 1,1, '01-17-2018', 4,48),
 	(50, 2,2, '01-12-2018', 1,49),
 	(51, 3,3, '02-19-2018', 5,50),
 	(52, 1,1, '10-17-2018', 1,51),
 	(53, 2,2, '10-12-2018', 4,52),
 	(54, 3,3, '02-19-2018', 3,53),
 	(55, 1,1, '12-17-2018', 1,54),
 	(56, 2,2, '09-12-2018', 2,55),
 	(57, 3,3, '10-19-2018', 5,56),
 	(44, 4,4, '05-31-2017', 4,4),
 	(45, 5,5, '10-17-2017', 4,5),
 	(46, 6,6, '05-31-2017', 4,6),
 	(47, 7,7, '05-23-2018', 4,7),
 	(48, 8,8, '10-10-2017', 4,8),
 	(49, 9,9, '01-31-2018', 4,9);

 
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


DROP VIEW IF EXISTS bigFanAward, enemy, popularItem CASCADE;

create view bigFanAward  (loanerID, fan) as
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


create view enemy (hated, hater) as
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