--
-- acs-kernel/sql/acs-permissions-create.sql
--
-- The ACS core permissioning system. The knowledge level of system
-- allows you to define a hierarchichal system of privilages, and
-- associate them with low level operations on object types. The
-- operational level allows you to grant to any party a privilege on
-- any object.
--
-- @author Rafael Schloming (rhs@mit.edu)
--
-- @creation-date 2000-08-13
--
-- @cvs-id $Id$
--


---------------------------------------------
-- KNOWLEDGE LEVEL: PRIVILEGES AND ACTIONS --
---------------------------------------------

-- suggestion: acs_methods, acs_operations, acs_transactions?
-- what about cross-type actions? new-stuff? site-wide search?

--create table acs_methods (
--	object_type	not null constraint acs_methods_object_type_fk
--			references acs_object_types (object_type),
--	method		varchar2(100) not null,
--	constraint acs_methods_pk
--	primary key (object_type, method)
--);

--comment on table acs_methods is '
-- Each row in the acs_methods table directly corresponds to a
-- transaction on an object. For example an sql statement that updates a
-- bboard message would require an entry in this table.
--'

create table acs_privileges (
	privilege	varchar2(100) not null constraint acs_privileges_pk
			primary key,
	pretty_name	varchar2(100),
	pretty_plural	varchar2(100)
);

create table acs_privilege_hierarchy (
	privilege	not null constraint acs_priv_hier_priv_fk
			references acs_privileges (privilege),
    child_privilege	not null constraint acs_priv_hier_child_priv_fk
			references acs_privileges (privilege),
	constraint acs_privilege_hierarchy_pk
	primary key (privilege, child_privilege)
);

-- create bitmap index acs_priv_hier_child_priv_idx on acs_privilege_hierarchy (child_privilege);
create index acs_priv_hier_child_priv_idx on acs_privilege_hierarchy (child_privilege);

--create table acs_privilege_method_rules (
--	privilege	not null constraint acs_priv_method_rules_priv_fk
--			references acs_privileges (privilege),
--	object_type	varchar2(100) not null,
--	method		varchar2(100) not null,
--	constraint acs_privilege_method_rules_pk
--	primary key (privilege, object_type, method),
--	constraint acs_priv_meth_rul_type_meth_fk
--	foreign key (object_type, method) references acs_methods
--);

comment on table acs_privileges is '
 The rows in this table correspond to aggregations of specific
 methods. Privileges share a global namespace. This is to avoid a
 situation where granting the foo privilege on one type of object can
 have an entirely different meaning than granting the foo privilege on
 another type of object.
';

comment on table acs_privilege_hierarchy is '
 The acs_privilege_hierarchy gives us an easy way to say: The foo
 privilege is a superset of the bar privilege.
';

--comment on table acs_privilege_method_rules is '
-- The privilege method map allows us to create rules that specify which
-- methods a certain privilege is allowed to invoke in the context of a
-- particular object_type. Note that the same privilege can have
-- different methods for different object_types. This is because each
-- method corresponds to a piece of code, and the code that displays an
-- instance of foo will be different than the code that displays an
-- instance of bar. If there are no methods defined for a particular
-- (privilege, object_type) pair, then that privilege is not relavent to
-- that object type, for example there is no way to moderate a user, so
-- there would be no additional methods that you could invoke if you
-- were granted moderate on a user.
--'

--create or replace view acs_privilege_method_map
--as select r1.privilege, pmr.object_type, pmr.method
--     from acs_privileges r1, acs_privileges r2, acs_privilege_method_rules pmr
--    where r2.privilege in (select distinct rh.child_privilege
--                           from acs_privilege_hierarchy rh
--                           start with privilege = r1.privilege
--                           connect by prior child_privilege = privilege
--                           union
--                           select r1.privilege
--                           from dual)
--      and r2.privilege = pmr.privilege;

create or replace package acs_privilege
as

  procedure create_privilege (
    privilege	in acs_privileges.privilege%TYPE,
    pretty_name   in acs_privileges.pretty_name%TYPE default null,
    pretty_plural in acs_privileges.pretty_plural%TYPE default null 
  );

  procedure drop_privilege (
    privilege	in acs_privileges.privilege%TYPE
  );

  procedure add_child (
    privilege		in acs_privileges.privilege%TYPE,
    child_privilege	in acs_privileges.privilege%TYPE
  );

  procedure remove_child (
    privilege		in acs_privileges.privilege%TYPE,
    child_privilege	in acs_privileges.privilege%TYPE
  );

end;
/
show errors

create or replace package body acs_privilege
as

  procedure create_privilege (
    privilege	  in acs_privileges.privilege%TYPE,
    pretty_name   in acs_privileges.pretty_name%TYPE default null,
    pretty_plural in acs_privileges.pretty_plural%TYPE default null 
  )
  is
  begin
    insert into acs_privileges
     (privilege, pretty_name, pretty_plural)
    values
     (create_privilege.privilege, 
      create_privilege.pretty_name, 
      create_privilege.pretty_plural);
  end;

  procedure drop_privilege (
    privilege	in acs_privileges.privilege%TYPE
  )
  is
  begin
    delete from acs_privileges
    where privilege = drop_privilege.privilege;
  end;

  procedure add_child (
    privilege		in acs_privileges.privilege%TYPE,
    child_privilege	in acs_privileges.privilege%TYPE
  )
  is
  begin
    insert into acs_privilege_hierarchy
     (privilege, child_privilege)
    values
     (add_child.privilege, add_child.child_privilege);
  end;

  procedure remove_child (
    privilege		in acs_privileges.privilege%TYPE,
    child_privilege	in acs_privileges.privilege%TYPE
  )
  is
  begin
    delete from acs_privilege_hierarchy
    where privilege = remove_child.privilege
    and child_privilege = remove_child.child_privilege;
  end;


end;
/
show errors


------------------------------------
-- OPERATIONAL LEVEL: PERMISSIONS --
------------------------------------

create table acs_permissions (
	object_id		not null
				constraint acs_permissions_on_what_id_fk
				references acs_objects (object_id),
	grantee_id		not null
				constraint acs_permissions_grantee_id_fk
				references parties (party_id),
	privilege		not null constraint acs_permissions_priv_fk
				references acs_privileges (privilege),
	constraint acs_permissions_pk
	primary key (object_id, grantee_id, privilege)
);

create index acs_permissions_grantee_idx on acs_permissions (grantee_id);
-- create bitmap index acs_permissions_privilege_idx on acs_permissions (privilege);
create index acs_permissions_privilege_idx on acs_permissions (privilege);

create or replace view acs_privilege_descendant_map
as select p1.privilege, p2.privilege as descendant
   from acs_privileges p1, acs_privileges p2
   where p2.privilege in (select child_privilege
			  from acs_privilege_hierarchy
			  start with privilege = p1.privilege
			  connect by prior child_privilege = privilege)
   or p2.privilege = p1.privilege;

create or replace view acs_permissions_all
as select op.object_id, p.grantee_id, p.privilege
   from acs_object_paths op, acs_permissions p
   where op.ancestor_id = p.object_id;

create or replace view acs_object_grantee_priv_map
as select a.object_id, a.grantee_id, m.descendant as privilege
   from acs_permissions_all a, acs_privilege_descendant_map m
   where a.privilege = m.privilege;

-- The last two unions make sure that the_public gets expaned to all
-- users plus 0 (the default user_id) we should probably figure out a
-- better way to handle this eventually since this view is getting
-- pretty freaking hairy. I'd love to be able to move this stuff into
-- a Java middle tier.

create or replace view acs_object_party_privilege_map
as select ogpm.object_id, gmm.member_id as party_id, ogpm.privilege
   from acs_object_grantee_priv_map ogpm, group_approved_member_map gmm
   where ogpm.grantee_id = gmm.group_id
   union
   select ogpm.object_id, rsmm.member_id as party_id, ogpm.privilege
   from acs_object_grantee_priv_map ogpm, rel_seg_approved_member_map rsmm
   where ogpm.grantee_id = rsmm.segment_id
   union
   select object_id, grantee_id as party_id, privilege
   from acs_object_grantee_priv_map
   union
   select object_id, u.user_id as party_id, privilege
   from acs_object_grantee_priv_map m, users u
   where m.grantee_id = -1
   union
   select object_id, 0 as party_id, privilege
   from acs_object_grantee_priv_map
   where grantee_id = -1;

----------------------------------------------------
-- ALTERNATE VIEW: ALL_OBJECT_PARTY_PRIVILEGE_MAP --
----------------------------------------------------

-- This view is a helper for all_object_party_privilege_map
create or replace view acs_grantee_party_map as
   select -1 as grantee_id, 0 as party_id from dual
   union all
   select -1 as grantee_id, user_id as party_id
   from users
   union all
   select party_id as grantee_id, party_id
   from parties
   union all
   select segment_id as grantee_id, member_id
   from rel_seg_approved_member_map
   union all
   select group_id as grantee_id, member_id as party_id
   from group_approved_member_map;

-- This view is like acs_object_party_privilege_map, but does not 
-- necessarily return distinct rows.  It may be *much* faster to join
-- against this view instead of acs_object_party_privilege_map, and is
-- usually not much slower.  The tradeoff for the performance boost is
-- increased complexity in your usage of the view.  Example usage that I've
-- found works well is:
--
--    select DISTINCT 
--           my_table.*
--    from my_table,
--         (select object_id
--          from all_object_party_privilege_map 
--          where party_id = :user_id and privilege = :privilege) oppm
--    where oppm.object_id = my_table.my_id;
--

create or replace view all_object_party_privilege_map as
select /*+ ORDERED */ 
               op.object_id,
               pdm.descendant as privilege,
               gpm.party_id as party_id
        from acs_object_paths op, 
             acs_permissions p, 
             acs_privilege_descendant_map pdm,
             acs_grantee_party_map gpm
        where op.ancestor_id = p.object_id 
          and pdm.privilege = p.privilege
          and gpm.grantee_id = p.grantee_id;


--create or replace view acs_object_party_method_map
--as select opp.object_id, opp.party_id, pm.object_type, pm.method
--   from acs_object_party_privilege_map opp, acs_privilege_method_map pm
--   where opp.privilege = pm.privilege;

create or replace package acs_permission
as

  procedure grant_permission (
    object_id	 acs_permissions.object_id%TYPE,
    grantee_id	 acs_permissions.grantee_id%TYPE,
    privilege	 acs_permissions.privilege%TYPE
  );

  procedure revoke_permission (
    object_id	 acs_permissions.object_id%TYPE,
    grantee_id	 acs_permissions.grantee_id%TYPE,
    privilege	 acs_permissions.privilege%TYPE
  );

  function permission_p (
    object_id	 acs_objects.object_id%TYPE,
    party_id	 parties.party_id%TYPE,
    privilege	 acs_privileges.privilege%TYPE
  ) return char;

end acs_permission;
/
show errors

create or replace package body acs_permission
as
  procedure grant_permission (
    object_id	 acs_permissions.object_id%TYPE,
    grantee_id	 acs_permissions.grantee_id%TYPE,
    privilege	 acs_permissions.privilege%TYPE
  )
  as
  begin
    insert into acs_permissions
      (object_id, grantee_id, privilege)
    values
      (object_id, grantee_id, privilege);
  exception
    when dup_val_on_index then
      return;
  end grant_permission;
  --
  procedure revoke_permission (
    object_id	 acs_permissions.object_id%TYPE,
    grantee_id	 acs_permissions.grantee_id%TYPE,
    privilege	 acs_permissions.privilege%TYPE
  )
  as
  begin
    delete from acs_permissions
    where object_id = revoke_permission.object_id
    and grantee_id = revoke_permission.grantee_id
    and privilege = revoke_permission.privilege;
  end revoke_permission;

  function permission_p (
    object_id	 acs_objects.object_id%TYPE,
    party_id	 parties.party_id%TYPE,
    privilege	 acs_privileges.privilege%TYPE
  ) return char
  as
    exists_p char(1);
  begin
    --
    -- direct permissions
    select decode(count(*),0,'f','t') into exists_p
    from dual where exists (
        select 'x'
          from acs_object_grantee_priv_map
         where object_id = permission_p.object_id
           and grantee_id = permission_p.party_id
           and privilege = permission_p.privilege);
    if exists_p = 't' then
        return 't';
    end if;
    --
    -- public-like permissions
    select decode(count(*),0,'f','t') into exists_p
    from dual where exists (
        select 'x'
          from acs_object_grantee_priv_map
         where object_id = permission_p.object_id
           and 0 = permission_p.party_id
           and privilege = permission_p.privilege
           and grantee_id = -1);
    if exists_p = 't' then
        return 't';
    end if;
    --
    -- public permissions
    select decode(count(*),0,'f','t') into exists_p
    from dual where exists (
        select 'x'
          from acs_object_grantee_priv_map m, users u
         where object_id = permission_p.object_id
           and u.user_id = permission_p.party_id
           and privilege = permission_p.privilege
           and m.grantee_id = -1);
    if exists_p = 't' then
        return 't';
    end if;
    --
    -- group permmissions
    select decode(count(*),0,'f','t') into exists_p
    from dual where exists (
          select 'x'
          from acs_object_grantee_priv_map ogpm,
               group_approved_member_map gmm
         where object_id = permission_p.object_id
           and gmm.member_id = permission_p.party_id
           and privilege = permission_p.privilege
           and ogpm.grantee_id = gmm.group_id);
    if exists_p = 't' then
        return 't';
    end if;
    --
    -- relational segment approved group
    select decode(count(*),0,'f','t') into exists_p
    from dual where exists (
        select 'x'
          from acs_object_grantee_priv_map ogpm,
               rel_seg_approved_member_map rsmm
         where object_id = permission_p.object_id
           and rsmm.member_id = permission_p.party_id
           and privilege = permission_p.privilege
           and ogpm.grantee_id = rsmm.segment_id);
    if exists_p = 't' then
        return 't';
    end if;
    return exists_p;
  end;
  --
end acs_permission;
/
show errors

