--
-- packages/acs-kernel/sql/acs-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-08-22
-- @cvs-id acs-create.sql,v 1.1.2.9 2000/08/24 07:09:18 rhs Exp
--

create table acs_magic_objects (
        name                varchar2(100)
                        constraint acs_magic_objects_pk primary key,
        object_id        not null constraint acs_magic_objects_object_id_fk
                        references acs_objects(object_id)
);

create index acs_mo_object_id_idx on acs_magic_objects (object_id);

comment on table acs_magic_objects is '
 This table allows us to provide semantic names for certain special
 objects like the site-wide organization, and the all users party.
';

create or replace package acs
as

    function add_user (
        user_id in users.user_id%TYPE default null,
        object_type in acs_objects.object_type%TYPE default 'user',
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        email in parties.email%TYPE,
        url in parties.url%TYPE default null,
        first_names in persons.first_names%TYPE,
        last_name in persons.last_name%TYPE,
        password in users.password%TYPE,
        salt in users.salt%TYPE,
        password_question in users.password_question%TYPE default null,
        password_answer in users.password_answer%TYPE default null,
        screen_name in users.screen_name%TYPE default null,
        email_verified_p in users.email_verified_p%TYPE default 't',
        member_state in membership_rels.member_state%TYPE default 'approved'
    ) return users.user_id%TYPE;

    procedure remove_user (
        user_id in users.user_id%TYPE
    );

    function magic_object_id (
        name in acs_magic_objects.name%TYPE
    ) return acs_objects.object_id%TYPE;

end acs;
/
show errors

create or replace package body acs
as
    function add_user (
        user_id in users.user_id%TYPE default null,
        object_type in acs_objects.object_type%TYPE default 'user',
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        email in parties.email%TYPE,
        url in parties.url%TYPE default null,
        first_names in persons.first_names%TYPE,
        last_name in persons.last_name%TYPE,
        password in users.password%TYPE,
        salt in users.salt%TYPE,
        password_question in users.password_question%TYPE default null,
        password_answer in users.password_answer%TYPE default null,
        screen_name in users.screen_name%TYPE default null,
        email_verified_p in users.email_verified_p%TYPE default 't',
        member_state in membership_rels.member_state%TYPE default 'approved'
    ) return users.user_id%TYPE
    is
        v_user_id                users.user_id%TYPE;
        v_rel_id                membership_rels.rel_id%TYPE;
    begin
        v_user_id := acs_user.new(
            user_id => user_id,
            object_type => object_type,
            creation_date => creation_date,
            creation_user => creation_user,
            creation_ip => creation_ip,
            email => email,
            url => url,
            first_names => first_names,
            last_name => last_name,
            password => password,
            salt => salt,
            password_question => password_question,
            password_answer => password_answer,
            screen_name => screen_name,
            email_verified_p => email_verified_p
        );
    
        v_rel_id := membership_rel.new (
            object_id_two => v_user_id,
            object_id_one => acs.magic_object_id('registered_users'),
            member_state => member_state
        );

        acs_permission.grant_permission (
            object_id => v_user_id,
            grantee_id => v_user_id,
            privilege => 'read'
        );

        acs_permission.grant_permission (
            object_id => v_user_id,
            grantee_id => v_user_id,
            privilege => 'write'
        );

        return v_user_id;
    end;

    procedure remove_user (
        user_id in users.user_id%TYPE
    )
    is
    begin
        delete
        from acs_permissions
        where grantee_id = user_id;

        for row in (select rel_id
                    from acs_rels
                    where object_id_two = user_id) loop

            acs_rel.delete(rel_id => row.rel_id);

        end loop;

        acs_user.delete(user_id => user_id);
    end;

    function magic_object_id (
        name in acs_magic_objects.name%TYPE
    ) return acs_objects.object_id%TYPE
    is
        object_id acs_objects.object_id%TYPE;
    begin
        select object_id
        into magic_object_id.object_id
        from acs_magic_objects
        where name = magic_object_id.name;

        return object_id;
    end magic_object_id;
end acs;
/
show errors

-- ******************************************************************
-- * Community Core API
-- ******************************************************************

create or replace view registered_users
as
  select p.email, p.url, pe.first_names, pe.last_name, u.*, mr.member_state
  from parties p, persons pe, users u, group_member_map m, membership_rels mr
  where party_id = person_id
  and person_id = user_id
  and u.user_id = m.member_id
  and m.rel_id = mr.rel_id
  and m.group_id = (select acs.magic_object_id('registered_users') from dual)
  and mr.member_state = 'approved'
  and u.email_verified_p = 't';

create or replace view cc_users
as
select o.*, pa.*, pe.*, u.*, mr.member_state, mr.rel_id
from acs_objects o, parties pa, persons pe, users u, group_member_map m, membership_rels mr
where o.object_id = pa.party_id
and pa.party_id = pe.person_id
and pe.person_id = u.user_id
and u.user_id = m.member_id
and m.group_id = acs.magic_object_id('registered_users')
and m.rel_id = mr.rel_id
and m.container_id = m.group_id;

-----------------------------------
-- Community Core Initialization --
-----------------------------------

-- The very first thing we must do is create the security_context_root
-- object.

declare
  root_id integer;
begin
  root_id := acs_object.new (
    object_id => 0
  );

  insert into acs_magic_objects
   (name, object_id)
  values
   ('security_context_root', 0);
end;
/
show errors

begin
 --------------------------------------------------------------
 -- Some privilege that will be fundamental to all objects. --
 --------------------------------------------------------------

 acs_privilege.create_privilege('read');
 acs_privilege.create_privilege('write');
 acs_privilege.create_privilege('create');
 acs_privilege.create_privilege('delete');
 acs_privilege.create_privilege('admin');

 ---------------------------------------------------------
 -- Administrators can read, write, create, and delete. -- 
 ---------------------------------------------------------

 acs_privilege.add_child('admin', 'read');
 acs_privilege.add_child('admin', 'write');
 acs_privilege.add_child('admin', 'create');
 acs_privilege.add_child('admin', 'delete');

 commit;
end;
/
show errors

begin
 insert into acs_objects
  (object_id, object_type)
 values
  (-1, 'party');

 insert into parties
  (party_id)
 values
  (-1);

 insert into acs_magic_objects
  (name, object_id)
 values
  ('the_public', -1);

 commit;
end;
/
show errors

-- Insert the site-wide group. The members of this
-- group correspond to all registered users.
declare
  group_id integer;
begin
  group_id := acs_group.new (
    group_id => -2,
    group_name => 'Registered Users'
  );

 insert into acs_magic_objects
  (name, object_id)
 values
  ('registered_users', -2);

 commit;
end;
/
show errors

-- Create the default context.
declare
  object_id integer;
begin
  object_id := acs_object.new (
    object_id => -3
  );

  insert into acs_magic_objects
   (name, object_id)
  values
   ('default_context', object_id);

  commit;
end;
/
show errors
