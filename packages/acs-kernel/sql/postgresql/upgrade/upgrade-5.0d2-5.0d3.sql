-- 
-- Upgrade script from 5.0d2 to 5.0d3
--
-- @author Peter Marklund (peter@collaboraid.biz)
--
-- @cvs-id $Id$
--

-- ****** New authentication datamodel

create table auth_authorities (
    authority_id             integer
                             constraint auth_authorities_pk
                             primary key
                             constraint auth_authorities_aid_fk
                             references acs_objects(object_id)
                             on delete cascade,
    short_name               varchar(255)
                             constraint auth_authority_short_name_un
                             unique,
    pretty_name              varchar(4000),
    help_contact_text        varchar(4000),
    enabled_p                boolean default 't' 
                             constraint auth_authority_enabled_p_nn
                             not null,
    sort_order               integer not null,
    -- Id of the authentication service contract implementation
    -- Cannot reference acs_sc_impls table as it doesn't exist yet
    auth_impl_id             integer
                             constraint auth_authority_auth_impl_fk
                             references acs_objects(object_id),
    -- Id of the password management service contact implementation
    pwd_impl_id              integer
                             constraint auth_authority_pwd_impl_fk
                             references acs_objects(object_id),
    forgotten_pwd_url        varchar(4000),
    change_pwd_url           varchar(4000),
    -- Id of the registration service contract implementation
    register_impl_id         integer
                             constraint auth_authority_reg_impl_fk
                             references acs_objects(object_id),
    register_url             varchar(4000),
    -- batch sync
    -- Id of service contract getting batch sync doc
    get_doc_impl_id          integer references acs_objects(object_id),
    -- Id of service contract processing batch sync doc
    process_doc_impl_id      integer references acs_objects(object_id),
    -- Are batch syncs snapshots or of incremental type
    snapshot_p               boolean default 'f'
                             constraint auth_authority_snapshot_p_nn
                             not null,
    batch_sync_enabled_p     boolean default 'f'
                             constraint auth_authority_bs_enabled_p_nn
                             not null
);

comment on column auth_authorities.help_contact_text is '
    Contact information (phone, email, etc.) to be displayed
    as a last resort when people are having problems with an authority.
';

comment on column auth_authorities.forgotten_pwd_url is '
    Any username in this url must be on the syntax foo={username}
    and {username} will be replaced with the real username
';

comment on column auth_authorities.change_pwd_url is '
    Any username in this url must be on the syntax foo={username}
    and {username} will be replaced with the real username
';


-- Define the acs object type
select acs_object_type__create_type (
    'authority',
    'Authority',
    'Authorities',
    'acs_object',
    'auth_authorities',
    'authority_id',
    null,
    'f',
    null,
    null
);

-- Create PLSQL functions
create or replace function authority__new (
    integer, -- authority_id
    varchar, -- object_type
    varchar, -- short_name
    varchar, -- pretty_name
    boolean, -- enabled_p
    integer, -- sort_order
    integer, -- auth_impl_id
    integer, -- pwd_impl_id
    varchar, -- forgotten_pwd_url
    varchar, -- change_pwd_url
    integer, -- register_impl_id
    varchar, -- register_url
    varchar, -- help_contact_text
    integer, -- creation_user
    varchar, -- creation_ip
    integer  -- context_id
)
returns integer as '
declare
    p_authority_id alias for $1; -- default null,
    p_object_type alias for $2; -- default ''authority''
    p_short_name alias for $3;
    p_pretty_name alias for $4;
    p_enabled_p alias for $5; -- default ''t''
    p_sort_order alias for $6;
    p_auth_impl_id alias for $7; -- default null
    p_pwd_impl_id alias for $8; -- default null
    p_forgotten_pwd_url alias for $9; -- default null
    p_change_pwd_url alias for $10; -- default null
    p_register_impl_id alias for $11; -- default null
    p_register_url alias for $12; -- default null
    p_help_contact_text alias for $13; -- default null,
    p_creation_user alias for $14; -- default null
    p_creation_ip alias for $15; -- default null
    p_context_id alias for $16; -- default null
  
    v_authority_id           integer;
    v_object_type            varchar;    
    v_sort_order             integer;
  
begin
    if p_object_type is null then
        v_object_type := ''authority'';
    else
        v_object_type := p_object_type;
    end if;

    if p_sort_order is null then
          select into v_sort_order max(sort_order) + 1
                         from auth_authorities;
    else
        v_sort_order := p_sort_order;
    end if;

    -- Instantiate the ACS Object super type with auditing info
    v_authority_id  := acs_object__new(
        p_authority_id,
        v_object_type,
        now(),
        p_creation_user,
        p_creation_ip,
        p_context_id,
        ''t''
    );

    insert into auth_authorities (authority_id, short_name, pretty_name, enabled_p, 
                                  sort_order, auth_impl_id, pwd_impl_id, 
                                  forgotten_pwd_url, change_pwd_url, register_impl_id,
                                  help_contact_text)
    values (v_authority_id, p_short_name, p_pretty_name, p_enabled_p, 
                                  v_sort_order, p_auth_impl_id, p_pwd_impl_id, 
                                  p_forgotten_pwd_url, p_change_pwd_url, p_register_impl_id,
                                  p_help_contact_text);

   return v_authority_id;
end;
' language 'plpgsql';

create or replace function authority__del (integer)
returns integer as '
declare
  p_authority_id            alias for $1;
begin
  perform acs_object__delete(p_authority_id);

  return 0; 
end;' language 'plpgsql';


-- Create the local authority
select authority__new(
    null,              -- authority_id
    null,              -- object_type
    'local',           -- short_name
    'OpenACS Local',   -- pretty_name 
    't',               -- enabled_p
    1,                 -- sort_order
    null,              -- auth_impl_id
    null,              -- pwd_impl_id
    null,              -- forgotten_pwd_url
    null,              -- change_pwd_url
    null,              -- register_impl_id
    null,              -- register_url
    null,              -- help_contact_text
    null,              -- creation_user
    null,              -- creation_ip
    null               -- context_id
);


-- ****** Changes to the users table

alter table users add authority_id integer
                      constraint users_auth_authorities_fk
                      references auth_authorities(authority_id);

alter table users add username varchar(100);
update users set username = (select email from parties where party_id = users.user_id);
-- Does not work with PG 7.2
-- alter table users alter column username set not null;

alter table users add constraint users_authority_username_un
                      unique (authority_id, username);

drop view cc_users;
create view cc_users
as
select o.*, pa.*, pe.*, u.*, mr.member_state, mr.rel_id
from acs_objects o, parties pa, persons pe, users u, group_member_map m, membership_rels mr, acs_magic_objects amo
where o.object_id = pa.party_id
  and pa.party_id = pe.person_id
  and pe.person_id = u.user_id
  and u.user_id = m.member_id
  and amo.name = 'registered_users'
  and m.group_id = amo.object_id
  and m.rel_id = mr.rel_id
  and m.container_id = m.group_id;
