<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="content::get_folder_labels.get_url">      
      <querytext>

    select
      0 as tree_level, '' as name , 'Home' as title
    from
      dual
    UNION
    select
      t.tree_level, i.name, content_item.get_title(t.context_id) as title
    from (
      select 
        context_id, level as tree_level
      from 
        acs_objects
      where
        context_id <> content_item.get_root_folder
      connect by
        prior context_id = object_id
      start with
        object_id = :item_id
      ) t, cr_items i
    where
      i.item_id = t.context_id
    order by
      tree_level

      </querytext>
</fullquery>

<fullquery name="content::init.get_item_info">      
      <querytext>

    select 
      item_id, content_type
    from 
      cr_items
    where
      item_id = content_item.get_id(:url, :content_root)

      </querytext>
</fullquery>

<fullquery name="content::init.get_template_url">      
      <querytext>

        select 
          content_template.get_path(
          content_item.get_template(:item_id, :context),:template_root) as template_url 
        from 
          dual

      </querytext>
</fullquery>

</queryset>
