<?xml version="1.0"?>

<queryset>

    <fullquery name="search_indexer.search_observer_queue_entry">
        <querytext>
            select object_id, date, event
            from search_observer_queue
            order by date asc
        </querytext>
    </fullquery>

    <fullquery name="search_content_get.get_file_data">
        <querytext>
	    select ':content' as content,
                   'file' as storage_type
            from dual
        </querytext>
    </fullquery>

    <fullquery name="content_get.get_lob_data">
        <querytext>
            select :content as content,
                   'lob' as storage_type
            from dual
        </querytext>
    </fullquery>

</queryset>
