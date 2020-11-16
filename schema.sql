-- COMP3311 20T3 Assignment 1
-- Calendar schema
-- Written by Zixuan Guo (z5173593)

-- Types

create type AccessibilityType as enum ('read-write','read-only','none');
create type InviteStatus as enum ('invited','accepted','declined');

-- add more types/domains if you want
create type VisibilityType as enum ('public','private');
create type DayType as enum ('mon', 'tue','wed','thu','fri','sat','sun');
-- Tables

create table Users (
	id          serial,
	email       text not null unique,
	name		text not null,
	passwd		text not null,
	is_admin	boolean not null,
	primary key (id)
);

create table Groups (
	id          serial,
	name        text not null,
	owner		serial not null,
	primary key (id)
);

create table Calendars (
	id          	serial,
	name        	text not null,
	color			text not null,
	default_access	AccessibilityType not null,
	owner			serial not null,
	primary key (id)
);

create table Events (
	id          serial,
	start_time  time,
	title		text not null,
	visibility	VisibilityType not null,
	location	text,
	end_time	time,
	created_by	serial not null,
	part_of		serial not null,
	primary key (id)
);

create table One_Day_Events (
	id          serial,
	date        date not null,
	primary key (id)
);

create table Spanning_Events (
	id          serial,
	start_date  date not null,
	end_date	date not null,
	primary key (id)
);

create table Recurring_Events (
	id          serial,
	start_date  date not null,
	end_date	date,
	ntimes		int,
	primary key (id)
);

create table Alarms (
	event_id    int,
	alarm       timestamp not null,
	primary key (event_id),
	foreign key (event_id) references Events(id)
);

create table Weekly_Events (
	id          serial,
	day_of_week DayType not null,
	frequency	int not null,
	primary key (id)
);

create table Monthly_By_Day_Events (
	id          	serial,
	day_of_week 	DayType not null,
	week_In_month	int not null check(week_In_month >= 1 and week_In_month <= 5),
	primary key (id)
);

create table Monthly_By_Date_Events (
	id          	serial,
	date_in_month	int not null check(date_in_month >= 1 and date_in_month <= 31),
	primary key (id)
);

create table Annual_Events (
	id         serial,
	date       date not null,
	primary key (id)
);

create table Members (
	user_id 	serial,
	group_id	serial,
	primary key (user_id, group_id),
	foreign key (user_id) references Users(id),
	foreign key (group_id) references Groups(id)	
);

create table Accessibility (
	Calendar_id 	serial,
	Access 		AccessibilityType not null,
	user_id 		serial,
	primary key (calendar_id, user_id),
	foreign key (calendar_id) references Calendars(id),
	foreign key (user_id) references Users(id)
);

create table Subscribed (
	Calendar_id 	serial,
	User_id 		serial, 		
	colour 		text,
	primary key (calendar_id, user_id),
	foreign key (calendar_id) references Calendars(id),
	foreign key (user_id) references Users(id)
);

create table Invited (
	Event_id 	serial,
	user_id 	serial,
	status 	InviteStatus not null,
	primary key (event_id, user_id),
	foreign key (event_id) references Events(id),
	foreign key (user_id) references Users(id)
);