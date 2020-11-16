-- COMP3311 20T3 Assignment 2

-- Q1: students who've studied many courses

create or replace view Q1(unswid,name)
as
select people.unswid, people.name
From People, course_enrolments
where people.id = course_enrolments.student
group by people.unswid, people.name
having count(course_enrolments.student) > 65
;

-- Q2: numbers of students, staff and both

create or replace view Q2(nstudents,nstaff,nboth)
as
select 
(select count(*) 
 from students left join staff on (staff.id = students.id)
 where staff.id is NULL) as nstudents, 
(select count(*) 
 from students right join staff on (staff.id = students.id)
 where students.id is NULL) as nstaff,
(select count(*) 
 from students left join staff on (staff.id = students.id)
 where staff.id is NOT NULL) as nboth
;

-- Q3: prolific Course Convenor(s)
-- course_staff where role = 1870;
-- people.name
-- LIC count: from people join course_staff on (people.id = course_staff.staff)) where role = 1870 group by people.id;

create or replace view Q3_1(name,ncourses)
as
select people.name, 
	count(*) as ncourses from people join course_staff on (people.id = course_staff.staff) 
	where role = 1870 group by people.id order by ncourses DESC
;

create or replace view Q3(name,ncourses)
as
select name, ncourses from Q3_1 
where ncourses = (select max(ncourses) from Q3_1)
;


-- Q4: Comp Sci students in 05s2 and 17s1

create or replace view Q4a(id,name)
as
select people.unswid, people.name 
from people join program_enrolments on (people.id = program_enrolments.student) 
where program_enrolments.term = 138 and program_enrolments.program = 554;
;

create or replace view Q4b(id,name)
as
select people.unswid, people.name 
from people join program_enrolments on (people.id = program_enrolments.student) 
where program_enrolments.term = 214 and program_enrolments.program = 6788;
;

-- Q5: most "committee"d faculty

create or replace view Q5_a(name, count)
as
select facultyOf(orgunits.id) as name, count(*) from orgunit_groups join orgunits 
on(orgunit_groups.member = orgunits.id) 
where orgunits.utype = 9 and facultyOf(orgunits.id) is not null 
group by facultyOf(orgunits.id)
;

create or replace view Q5(name)
as
	select orgunits.name from Q5_a join orgunits on orgunits.id = Q5_a.name
	where count = (select max(count) from Q5_a);



-- Q6: nameOf function

create or replace function
   Q6(id integer) returns text
as $$
	select people.name from people 
	where people.id = $1 or people.unswid = $1;
$$ language sql;

-- Q7: offerings of a subject

create or replace function
   Q7(subject text)
     returns table (subject text, term text, convenor text)
as $$
	select subjects.code::text, termname(terms.id), people.name 
	from subjects join courses on (subjects.id = courses.subject)
	join terms on (courses.term = terms.id)	
	join course_staff on (course_staff.course = courses.id)
	join people on (people.id = course_staff.staff)
	where course_staff.role = 1870 and subjects.code = $1;
$$ language sql;


-- Q8: transcript

create or replace function
   Q8(zid integer) returns setof TranscriptRecord
as $$
DECLARE
	record TranscriptRecord;
	wamValue integer := 0;
	weightedSumOfMarks float := 0;
	gradeUoc float := 0;
	totalUOC integer := 0;
	UOCpassed integer := 0;
begin 
	perform s.id
    from students s 
    	join people p on (s.id = p.id)
    where  p.unswid = $1;

    -- if no unswid found, 'ERROR:  Invalid student xxxxx'
    if (not found) then
            raise EXCEPTION 'Invalid student %', zid;
    end if;

    for record in 
    	select distinct subjects.code, termname(terms.id) as term, programs.code as prog, 
    					substr(subjects.name,1,20) as name, Course_enrolments.mark,
    					Course_enrolments.grade, subjects.uoc
    	from people
    		join students on (students.id = people.id)
    		join program_enrolments on (program_enrolments.student = people.id)
    		join programs on (programs.id = Program_enrolments.program)
    		join Course_enrolments on (Course_enrolments.student = students.id)
    		join courses on (courses.id = Course_enrolments.course)
    		join terms on (courses.term = terms.id)
    		join subjects on (Courses.subject = subjects.id)
    	where people.unswid = $1 and Courses.term = Program_enrolments.term
    	order by term, subjects.code
    loop 
    	if (record.grade in ('PT','PC','PS','CR','DN','HD','A','B','C')) then
			totalUOC := totalUOC + record.uoc;
			UOCpassed := UOCpassed + record.uoc;
			if (record.mark >= 0) then
				gradeUoc := gradeUoc + record.uoc;
				weightedSumOfMarks := weightedSumOfMarks + record.mark * record.uoc;
			end if;	
		elsif (record.grade in ('SY', 'XE', 'T', 'PE', 'RC', 'RS')) then
			totalUOC := totalUOC + record.uoc;
			UOCpassed := UOCpassed + record.uoc;
		elsif (record.grade = NULL) then 
			record.uoc = null;
			
		else 
			if (record.mark >= 0) then
				weightedSumOfMarks := weightedSumOfMarks + record.mark * record.uoc;
				gradeUoc := gradeUoc + record.uoc;
			end if;	
			
			record.uoc = NULL;	
		end if;
		return next record;
	end loop;
	
	if (totalUOC = 0) then
        record := (null, null, null, 'No WAM available', null, null, null);
    else
    	wamValue := round(weightedSumOfMarks/gradeUoc);
    	record := (null, null, null, 'Overall WAM/UOC', wamValue, null, UOCpassed);
    end if;
    return next record;
end;
$$ language plpgsql;

-- Q9: members of academic object group

create or replace function
   Q9(gid integer) returns setof AcObjRecord
as $$
DECLARE

begin

end;
$$ language plpgsql;

-- Q10: follow-on courses

create or replace function
   Q10(code text) returns setof text
as $$
DECLARE
	result text;
	sub_code text := '%'||code||'%';
begin
	for result in 
		select subjects.code as q10 
		from acad_object_groups
			join rules on (rules.ao_group = acad_object_groups.id)
			join subject_prereqs on(subject_prereqs.rule = rules.id)
			join subjects on (subject_prereqs.subject = subjects.id)
		where acad_object_groups.definition like sub_code
	loop 
		return next result;
	end loop;		
end;
$$ language plpgsql;
