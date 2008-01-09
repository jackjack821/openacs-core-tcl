<?xml version="1.0"?>
<queryset>

   <fullquery name="acs_mail_lite::log_mail_sending.record_mail_sent">
     <querytext>

       update acs_mail_lite_mail_log
       set last_mail_date = sysdate
       where party_id = :user_id

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::log_mail_sending.insert_log_entry">
     <querytext>

       insert into acs_mail_lite_mail_log (party_id, last_mail_date)
       values (:user_id, sysdate)

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::smtp.record_bounce">
     <querytext>

       update acs_mail_lite_bounce
       set bounce_count = bounce_count + 1
       where party_id = :rcpt_id

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::smtp.insert_bounce">
     <querytext>

       insert into acs_mail_lite_bounce (party_id, bounce_count)
       values (:rcpt_id, 1)

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::get_address_array.get_user_name_and_id">
     <querytext>

       select person_id as user_id, first_names || ' ' || last_name as user_name
       from parties, persons
       where email = :email
         and party_id = person_id
	order by party_id desc
	limit 1

     </querytext>
   </fullquery>


    <fullquery name="acs_mail_lite::sweeper.get_queued_message">
        <querytext>
            select id
            from acs_mail_lite_queue
            where id=:id and (locking_server = '' or locking_server is NULL)
        </querytext>
    </fullquery>

    <fullquery name="acs_mail_lite::sweeper.lock_queued_message">
        <querytext>
            update acs_mail_lite_queue
               set locking_server = :locking_server
            where id=:id
        </querytext>
    </fullquery> 


    <fullquery name="acs_mail_lite::sweeper.delete_queue_entry">
        <querytext>
            delete from acs_mail_lite_queue
            where id=:id
        </querytext>
    </fullquery>

  <fullquery name="acs_mail_lite::send_immediately.get_file_info">
    <querytext>
      select r.mime_type,r.title, r.content as filename, i.name
      from cr_revisions r, cr_items i
      where r.revision_id = i.latest_revision
        and i.item_id in ([join $item_ids ","])
    </querytext>
  </fullquery>

</queryset>
