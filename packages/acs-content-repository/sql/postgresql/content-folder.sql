-- Data model to support content repository of the ArsDigita Community
-- System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- create or replace package body content_folder

create function content_folder__new(varchar,varchar,varchar,integer) 
returns integer as '
declare
  new__name                   alias for $1;  
  new__label                  alias for $2;  
  new__description            alias for $3;  -- default null  
  new__parent_id              alias for $4;  -- default null
begin
        return content_folder__new(new__name,
                                   new__label,
                                   new__description,
                                   new__parent_id,
                                   null,
                                   null,
                                   now(),
                                   null,
                                   null
               );

end;' language 'plpgsql';
-- function new
create function content_folder__new (varchar,varchar,varchar,integer,integer,integer,timestamp with time zone,integer,varchar)
returns integer as '
declare
  new__name                   alias for $1;  
  new__label                  alias for $2;  
  new__description            alias for $3;  -- default null
  new__parent_id              alias for $4;  -- default null
  new__context_id             alias for $5;  -- default null
  new__folder_id              alias for $6;  -- default null
  new__creation_date          alias for $7;  -- default now()
  new__creation_user          alias for $8;  -- default null
  new__creation_ip            alias for $9;  -- default null
  v_folder_id                 cr_folders.folder_id%TYPE;
  v_context_id                acs_objects.context_id%TYPE;
begin

  -- set the context_id
  if new__context_id is null then
    v_context_id := new__parent_id;
  else
    v_context_id := new__context_id;
  end if;

  -- parent_id = 0 means that this is a mount point
  if new__parent_id != 0 and 
     content_folder__is_registered(new__parent_id,''content_folder'',''f'') = ''f'' then

    raise EXCEPTION ''-20000: This folder does not allow subfolders to be created'';
    return null;

  else

    v_folder_id := content_item__new(
        new__name, 
        new__parent_id,
        new__folder_id,
        null,
        new__creation_date, 
        new__creation_user, 
	v_context_id,
        new__creation_ip, 
        ''content_folder'',
        ''content_folder'',
        null,
        null,
        ''text/plain'',
        null,
        null,
        ''text''    
    );

    insert into cr_folders (
      folder_id, label, description
    ) values (
      v_folder_id, new__label, new__description
    );

    -- inherit the attributes of the parent folder
    if new__parent_id is not null then
    
      insert into cr_folder_type_map
        select
          v_folder_id as folder_id, content_type
        from
          cr_folder_type_map
        where
          folder_id = new__parent_id;
    end if;

    -- update the child flag on the parent
    update cr_folders set has_child_folders = ''t''
      where folder_id = new__parent_id;

    return v_folder_id;

  end if;

  return null; 
end;' language 'plpgsql';

-- function new -- accepts security_inherit_p DaveB

create function content_folder__new (varchar,varchar,varchar,integer,integer,integer,timestamp with time zone,integer,varchar, boolean)
returns integer as '
declare
  new__name                   alias for $1;  
  new__label                  alias for $2;  
  new__description            alias for $3;  -- default null
  new__parent_id              alias for $4;  -- default null
  new__context_id             alias for $5;  -- default null
  new__folder_id              alias for $6;  -- default null
  new__creation_date          alias for $7;  -- default now()
  new__creation_user          alias for $8;  -- default null
  new__creation_ip            alias for $9;  -- default null
  new__security_inherit_p     alias for $10;  -- default true	
  v_folder_id                 cr_folders.folder_id%TYPE;
  v_context_id                acs_objects.context_id%TYPE;
begin

  -- set the context_id
  if new__context_id is null then
    v_context_id := new__parent_id;
  else
    v_context_id := new__context_id;
  end if;

  -- parent_id = 0 means that this is a mount point
  if new__parent_id != 0 and 
     content_folder__is_registered(new__parent_id,''content_folder'',''f'') = ''f'' then

    raise EXCEPTION ''-20000: This folder does not allow subfolders to be created'';
    return null;

  else

    v_folder_id := content_item__new(
	new__folder_id,
	new__name, 
        new__parent_id,
        null,
        new__creation_date, 
        new__creation_user, 
	new__context_id,
	new__creation_ip, 
	''f'',
	''text/plain'',
	null,
	''text'',
	new__security_inherit_p,
	''CR_FILES'',
	''content_folder'',
        ''content_folder'');

    insert into cr_folders (
      folder_id, label, description
    ) values (
      v_folder_id, new__label, new__description
    );

    -- inherit the attributes of the parent folder
    if new__parent_id is not null then
    
      insert into cr_folder_type_map
        select
          v_folder_id as folder_id, content_type
        from
          cr_folder_type_map

where
          folder_id = new__parent_id;
    end if;

    -- update the child flag on the parent
    update cr_folders set has_child_folders = ''t''
      where folder_id = new__parent_id;

    return v_folder_id;

  end if;

  return null; 
end;' language 'plpgsql';

-- procedure delete
create function content_folder__delete (integer)
returns integer as '
declare
  delete__folder_id              alias for $1;  
  v_count                        integer;       
  v_parent_id                    integer;  
  v_path                         varchar;     
begin

  -- check if the folder contains any items

  select count(*) into v_count from cr_items 
   where parent_id = delete__folder_id;

  if v_count > 0 then
    v_path := content_item__get_path(delete__folder_id, null);
    raise EXCEPTION ''-20000: Folder ID % (%) cannot be deleted because it is not empty.'', delete__folder_id, v_path;
  end if;  

  PERFORM content_folder__unregister_content_type(
      delete__folder_id,
      ''content_revision'',
      ''t'' 
  );

  delete from cr_folder_type_map
    where folder_id = delete__folder_id;

  select parent_id into v_parent_id from cr_items 
    where item_id = delete__folder_id;

  PERFORM content_item__delete(delete__folder_id);

  -- check if any folders are left in the parent
  update cr_folders set has_child_folders = ''f'' 
    where folder_id = v_parent_id and not exists (
      select 1 from cr_items 
        where parent_id = v_parent_id and content_type = ''content_folder'');

  return 0; 
end;' language 'plpgsql';


-- procedure rename
create function content_folder__rename (integer,varchar,varchar,varchar)
returns integer as '
declare
  rename__folder_id              alias for $1;  
  rename__name                   alias for $2;  -- default null  
  rename__label                  alias for $3;  -- default null
  rename__description            alias for $4;  -- default null
  v_name_already_exists_p        integer;
begin

  if rename__name is not null and rename__name != '''' then
    PERFORM content_item__rename(rename__folder_id, rename__name);
  end if;

  if rename__label is not null and rename__label != '''' and 
     rename__description is not null and rename__description != '''' then 

    update cr_folders
      set label = rename__label,
      description = rename__description
      where folder_id = rename__folder_id;

  else if(rename__label is not null and rename__label != '''') and 
         (rename__description is null or rename__description = '''') then  
    update cr_folders
      set label = rename__label
      where folder_id = rename__folder_id;

  end if; end if;

  return 0; 
end;' language 'plpgsql';

-- 1) make sure we are not moving the folder to an invalid location:
--   a. destination folder exists
--   b. folder is not the webroot (folder_id = -1)
--   c. destination folder is not the same as the folder
--   d. destination folder is not a subfolder
-- 2) make sure subfolders are allowed in the target_folder
-- 3) update the parent_id for the folder

-- procedure move
create function content_folder__move (integer,integer)
returns integer as '
declare
  move__folder_id              alias for $1;  
  move__target_folder_id       alias for $2;  
  v_source_folder_id           integer;       
  v_valid_folders_p            integer;
begin

  select 
    count(*)
  into 
    v_valid_folders_p
  from 
    cr_folders
  where
    folder_id = move__target_folder_id
  or 
    folder_id = move__folder_id;

  if v_valid_folders_p != 2 then
    raise EXCEPTION ''-20000: content_folder.move - Not valid folder(s)'';
  end if;

  if move__folder_id = content_item__get_root_folder(null) or
    move__folder_id = content_template__get_root_folder() then
    raise EXCEPTION ''-20000: content_folder.move - Cannot move root folder'';
  end if;
  
  if move__target_folder_id = move__folder_id then
    raise EXCEPTION ''-20000: content_folder.move - Cannot move a folder to itself'';
  end if;

  if content_folder__is_sub_folder(move__folder_id, move__target_folder_id) = ''t'' then
    raise EXCEPTION ''-20000: content_folder.move - Destination folder is subfolder'';
  end if;

  if content_folder__is_registered(move__target_folder_id,''content_folder'',''f'') != ''t'' then
    raise EXCEPTION ''-20000: content_folder.move - Destination folder does not allow subfolders'';
  end if;

  select parent_id into v_source_folder_id from cr_items 
    where item_id = move__folder_id;

   -- update the parent_id for the folder
   update cr_items 
     set parent_id = move__target_folder_id
     where item_id = move__folder_id;

  -- update the has_child_folders flags

  -- update the source
  update cr_folders set has_child_folders = ''f'' 
    where folder_id = v_source_folder_id and not exists (
      select 1 from cr_items 
        where parent_id = v_source_folder_id 
          and content_type = ''content_folder'');

  -- update the destination
  update cr_folders set has_child_folders = ''t''
    where folder_id = move__target_folder_id;

  return 0; 
end;' language 'plpgsql';


-- procedure copy
create function content_folder__copy (integer,integer,integer,varchar)
returns integer as '
declare
  copy__folder_id              alias for $1;  
  copy__target_folder_id       alias for $2;  
  copy__creation_user          alias for $3;  
  copy__creation_ip            alias for $4;  -- default null  
  v_valid_folders_p            integer        
  v_current_folder_id          cr_folders.folder_id%TYPE;
  v_name                       cr_items.name%TYPE;
  v_label                      cr_folders.label%TYPE;
  v_description                cr_folders.description%TYPE;
  v_new_folder_id              cr_folders.folder_id%TYPE;
  v_folder_contents_val        record;
begin

  select 
    count(*)
  into 
    v_valid_folders_p
  from 
    cr_folders
  where
    folder_id = copy__target_folder_id
  or 
    folder_id = copy__folder_id;

  select
    parent_id
  into
    v_current_folder_id
  from
    cr_items
  where
    item_id = copy__folder_id;  

  if copy__folder_id = content_item__get_root_folder(null) 
     or copy__folder_id = content_template__get_root_folder() 
     or copy__target_folder_id = copy__folder_id 
     or v_current_folder_id = copy__target_folder_id then

    v_valid_folders_p := 0;
  end if;

  if v_valid_folders_p = 2 then 
    if content_folder__is_sub_folder(copy__folder_id, copy__target_folder_id) != ''t'' then

      -- get the source folder info
      select
        name, label, description
      into
        v_name, v_label, v_description
      from 
        cr_items i, cr_folders f
      where
        f.folder_id = i.item_id
      and
        f.folder_id = copy__folder_id;

      -- create the new folder
      v_new_folder_id := content_folder__new(
          v_name,
	  v_label,
	  v_description,
	  copy__target_folder_id,
          null,
          null,
          now(),
	  copy__creation_user,
	  copy__creation_ip
      );

      -- copy attributes of original folder
      insert into cr_folder_type_map
        select 
          v_new_folder_id as folder_id, content_type
        from
          cr_folder_type_map map
        where
          folder_id = copy__folder_id
        and
	  -- do not register content_type if it is already registered
          not exists ( select 1 from cr_folder_type_map
	               where folder_id = v_new_folder_id 
		       and content_type = map.content_type ) ;

      -- for each item in the folder, copy it
      for v_folder_contents_val in select
                                     item_id
                                   from
                                     cr_items
                                   where
                                     parent_id = copy__folder_id 
      LOOP
        
	PERFORM content_item__copy(
	    v_folder_contents_val.item_id,
	    v_new_folder_id,
	    copy__creation_user,
	    copy__creation_ip    
	);

      end loop;
    end if;
  end if;

  return 0; 
end;' language 'plpgsql';


-- function is_folder
create function content_folder__is_folder (integer)
returns boolean as '
declare
  item_id                alias for $1;  
begin

  return count(*) > 0 from cr_folders
    where folder_id = item_id;

end;' language 'plpgsql';


-- function is_sub_folder
create function content_folder__is_sub_folder (integer,integer)
returns boolean as '
declare
  is_sub_folder__folder_id              alias for $1;  
  is_sub_folder__target_folder_id       alias for $2;  
  v_parent_id                           integer default 0;       
  v_sub_folder_p                        boolean default ''f'';           
  v_rec                                 record;
begin

  if is_sub_folder__folder_id = content_item__get_root_folder(null) or
    is_sub_folder__folder_id = content_template__get_root_folder() then

    v_sub_folder_p := ''t'';
  end if;

--               select
--                 parent_id
--               from 
--                 cr_items
--               connect by
--                 prior parent_id = item_id
--               start with
--                 item_id = is_sub_folder__target_folder_id

  for v_rec in select i2.parent_id
               from cr_items i1, cr_items i2
               where i1.item_id = is_sub_folder__target_folder_id
                 and i1.tree_sortkey between i2.tree_sortkey and tree_right(i2.tree_sortkey)
               order by i2.tree_sortkey desc
  LOOP
    v_parent_id := v_rec.parent_id;
    exit when v_parent_id = is_sub_folder__folder_id;
  end LOOP;

  if v_parent_id != 0 then 
    v_sub_folder_p := ''t'';
  end if;

  return v_sub_folder_p;
 
end;' language 'plpgsql';


-- function is_empty
create function content_folder__is_empty (integer)
returns boolean as '
declare
  is_empty__folder_id              alias for $1;  
  v_return                         boolean;    
begin

  select
    count(*) = 0 into v_return
  from
    cr_items
  where
    parent_id = is_empty__folder_id;

  return v_return;
 
end;' language 'plpgsql';


-- procedure register_content_type
create function content_folder__register_content_type (integer,varchar,boolean)
returns integer as '
declare
  register_content_type__folder_id              alias for $1;  
  register_content_type__content_type           alias for $2;  
  register_content_type__include_subtypes       alias for $3;  -- default ''f''
  v_is_registered                               varchar;  
begin

  if register_content_type__include_subtypes = ''f'' then

    v_is_registered := content_folder__is_registered(
        register_content_type__folder_id,
	register_content_type__content_type, 
	''f'' 
    );

    if v_is_registered = ''f'' then

        insert into cr_folder_type_map (
	  folder_id, content_type
	) values (
	  register_content_type__folder_id, 
	  register_content_type__content_type
	);

    end if;

  else

--    insert into cr_folder_type_map
--      select 
--        register_content_type__folder_id as folder_id, 
--        object_type as content_type
--      from
--        acs_object_types
--      where
--        object_type <> ''acs_object''
--      and
--        not exists (select 1 from cr_folder_type_map
--                    where folder_id = register_content_type__folder_id
--                    and content_type = acs_object_types.object_type)
--      connect by 
--        prior object_type = supertype
--      start with 
--        object_type = register_content_type__content_type;
    
    insert into cr_folder_type_map
      select register_content_type__folder_id as folder_id, 
        o.object_type as content_type
      from acs_object_types o, acs_object_types o2
      where o.object_type <> ''acs_object''
        and not exists (select 1
                        from cr_folder_type_map
                        where folder_id = register_content_type__folder_id
                          and content_type = o.object_type)
        and o2.object_type = register_content_type__content_type
        and o.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey);
  end if;

  return 0; 
end;' language 'plpgsql';


-- procedure unregister_content_type
create function content_folder__unregister_content_type (integer,varchar,boolean)
returns integer as '
declare
  unregister_content_type__folder_id              alias for $1;  
  unregister_content_type__content_type           alias for $2;  
  unregister_content_type__include_subtypes       alias for $3; -- default ''f'' 
begin

  if unregister_content_type__include_subtypes = ''f'' then
    delete from cr_folder_type_map
      where folder_id = unregister_content_type__folder_id
      and content_type = unregister_content_type__content_type;
  else

--    delete from cr_folder_type_map
--    where folder_id = unregister_content_type__folder_id
--    and content_type in (select object_type
--           from acs_object_types    
--	   where object_type <> ''acs_object''
--	   connect by prior object_type = supertype
--	   start with 
--             object_type = unregister_content_type__content_type);

    delete from cr_folder_type_map
    where folder_id = unregister_content_type__folder_id
    and content_type in (select o.object_type
                           from acs_object_types o, acs_object_types o2
	                  where o.object_type <> ''acs_object''
                            and o2.object_type = unregister_content_type__content_type
                            and o.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey));

  end if;

  return 0; 
end;' language 'plpgsql';


-- function is_registered
create function content_folder__is_registered (integer,varchar,boolean)
returns boolean as '
declare
  is_registered__folder_id              alias for $1;  
  is_registered__content_type           alias for $2;  
  is_registered__include_subtypes       alias for $3;  -- default ''f''  
  v_is_registered                       integer;
  v_subtype_val                         record;
begin

  if is_registered__include_subtypes = ''f'' then
    select 
      count(1)
    into 
      v_is_registered
    from
      cr_folder_type_map
    where
      folder_id = is_registered__folder_id
    and
      content_type = is_registered__content_type;

  else
--                         select
--                            object_type
--                          from 
--                            acs_object_types
--                          where 
--                            object_type <> ''acs_object''
--                          connect by 
--                            prior object_type = supertype
--                          start with 
--                            object_type = is_registered.content_type 

    v_is_registered := 1;
    for v_subtype_val in select o.object_type
                         from acs_object_types o, acs_object_types o2
                         where o.object_type <> ''acs_object''
                           and o2.object_type = is_registered__content_type
                           and o.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
                         order by o.tree_sortkey
    LOOP
      if content_folder__is_registered(is_registered__folder_id,
                       v_subtype_val.object_type, ''f'') = ''f'' then
        v_is_registered := 0;
      end if;
    end loop;
  end if;

  if v_is_registered = 0 then
    return ''f'';
  else
    return ''t'';
  end if;
 
end;' language 'plpgsql';


-- function get_label
create function content_folder__get_label (integer)
returns varchar as '
declare
  get_label__folder_id              alias for $1;  
  v_label                           cr_folders.label%TYPE;
begin

  select 
    label into v_label 
  from 
    cr_folders       
  where 
    folder_id = get_label__folder_id;

  return v_label;
 
end;' language 'plpgsql';


-- function get_index_page
create function content_folder__get_index_page (integer)
returns integer as '
declare
  get_index_page__folder_id              alias for $1;  
  v_folder_id                            cr_folders.folder_id%TYPE;
  v_index_page_id                        cr_items.item_id%TYPE;
begin

  -- if the folder is a symlink, resolve it
  if content_symlink__is_symlink(get_index_page__folder_id) = ''t'' then
    v_folder_id := content_symlink__resolve(get_index_page__folder_id);
  else
    v_folder_id := get_index_page__folder_id;
  end if;

  select
    item_id into v_index_page_id
  from
    cr_items
  where
    parent_id = v_folder_id
  and
    name = ''index''
  and
    content_item__is_subclass(
      content_item__get_content_type(content_symlink__resolve(item_id)),
    ''content_folder'') = ''f''
  and
    content_item__is_subclass(
      content_item__get_content_type(content_symlink__resolve(item_id)),
    ''content_template'') = ''f'';

  if NOT FOUND then 
     return null;
  end if;

  return v_index_page_id;

end;' language 'plpgsql';


-- function is_root
create function content_folder__is_root (integer)
returns boolean as '
declare
  is_root__folder_id              alias for $1;  
  v_is_root                       boolean;       
begin

  select parent_id = 0 into v_is_root 
    from cr_items where item_id = is_root__folder_id;

  return v_is_root;
 
end;' language 'plpgsql';



-- show errors
