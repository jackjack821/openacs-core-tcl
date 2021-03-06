<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="auth::sync::job::get.select_job">
        <querytext>
            select job_id,
                   to_char(job_start_time, 'YYYY-MM-DD HH24:MI:SS') as job_start_time,
                   to_char(job_end_time, 'YYYY-MM-DD HH24:MI:SS') as job_end_time,
                   interactive_p,
                   snapshot_p,
                   authority_id,
                   (select aa.pretty_name from auth_authorities aa where aa.authority_id = j.authority_id) as authority_pretty_name,
                   message,
                   creation_user,
                   to_char(doc_start_time, 'YYYY-MM-DD HH24:MI:SS') as doc_start_time,
                   to_char(doc_end_time, 'YYYY-MM-DD HH24:MI:SS') as doc_end_time,
                   doc_status,
                   doc_message,
                   round((j.job_end_time - j.job_start_time) * 24*60*60) as run_time_seconds,
                   (select count(e1.entry_id)
                    from   auth_batch_job_entries e1
                    where  e1.job_id = j.job_id) as num_actions,
                   (select count(e2.entry_id)
                    from   auth_batch_job_entries e2
                    where  e2.job_id = j.job_id
                    and    e2.success_p = 'f') as num_problems
            from    auth_batch_jobs j
            where  j.job_id = :job_id
        </querytext>
    </fullquery>

    <fullquery name="auth::sync::job::end_get_document.update_doc_end">
        <querytext>
            update auth_batch_jobs
            set    doc_end_time = sysdate,
                   doc_status = :doc_status,
                   doc_message = :doc_message,
                   document = empty_clob(),
                   snapshot_p = :snapshot_p 
            where  job_id = :job_id
            returning document into :1
        </querytext>
    </fullquery>

    <fullquery name="auth::sync::job::create_entry.insert_entry">
        <querytext>

            insert into auth_batch_job_entries
            (entry_id, job_id, operation, username, user_id, success_p, message, element_messages)
            values
            (:entry_id, :job_id, :operation, :username, :user_id, :success_p_db, :message, empty_clob())
            returning element_messages into :1

        </querytext>
    </fullquery>

</queryset>




