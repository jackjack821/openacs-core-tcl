# 

ad_library {
    
    Procedures for tsearch full text enginge driver
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    @arch-tag: 49a5102d-7c06-4245-8b8d-15a3b12a8cc5
    @cvs-id $Id$
}

namespace eval tsearch2 {}

ad_proc -private tsearch2::index {
    object_id
    txt
    title
    keywords
} {
    
    add object to full text index
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    
    @param object_id
    @param txt
    @param title
    @param keywords
    
    @return 
    
    @error 
} {
    set index_exists_p [db_0or1row object_exists "select 1 from txt where object_id=:object_id"]
    if {!$index_exists_p} {
	db_dml index "insert into txt (object_id,fti) values ( :object_id, to_tsvector('default',:txt))"

    } else {
	tsearch2::update_index $object_id $txt $title $keywords
    }
	     
}

ad_proc -private tsearch2::unindex {
    object_id
} {
    Remove item from FTS index
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    
    @param object_id

    @return 
    
    @error 
} {
    db_dml unindex "delete from txt where object_id=:object_id"
}

ad_proc -private tsearch2::update_index {
    object_id
    txt
    title
    keywords
} {
    
    update full text index
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    
    @param object_id
    @param txt
    @param title
    @param keywords
    
    @return 
    
    @error 
} {
    set index_exists_p [db_0or1row object_exists "select 1 from txt where object_id=:object_id"]
    if {!$index_exists_p} {
	db_dml index "insert into txt (object_id,fti) values ( :object_id, to_tsvector('default',:txt))"
    } else {
	db_dml update_index "update txt set fti = to_tsvector('default',:txt) where object_id=:object_id"
    }
	     
}

ad_proc -private tsearch2::search {
    query
    offset
    limit
    user_id
    df
    dt
} {
    
    ftsenginedriver search operation implementation for tsearch2
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    
    @param query

    @param offset

    @param limit

    @param user_id

    @param df

    @param dt

    @return 
    
    @error 
} {
    # clean up query
    # turn and into &
    # turn or into |
    # turn not into !

    # FIXME actually write the regsub to do that, string map will
    # probably be too tricky to use
    
    set results_ids [db_list search "select object_id from txt where fti @@ to_tsquery(:query) order by rank(fti,to_tsquery(:query));"]
    
    set stop_words [list]
    # lovely the search package requires count to be returned but the
    # service contract definition doesn't specify it! 
    return [list ids $results_ids stopwords $stop_words count [llength $results_ids]]
}

ad_proc -private tsearch2::summary {
    query
    txt
} {
    
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    
    @param query

    @param txt

    @return summary containing search query terms
    
    @error 
} {
    return [db_string summary "select headline(:txt,to_tsquery(:query))"]
}

ad_proc -private tsearch2::driver_info {
} {
    
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    
    @return 
    
    @error 
} {
    return [list package_key tsearch2-driver version 2 automatic_and_queries_p 0  stopwords_p 1]
}

