<?xml version="1.0"?>

<queryset>

    <fullquery name="notification::get_interval_id.select_interval_id">
        <querytext>
            select interval_id
            from notification_intervals
            where name = :name
        </querytext>
    </fullquery>

    <fullquery name="notification::get_delivery_method_id.select_delivery_method_id">
        <querytext>
            select delivery_method_id
            from notification_delivery_methods
            where short_name = :name
        </querytext>
    </fullquery>

    <fullquery name="notification::get_all_intervals.select_all_intervals">
        <querytext>
            select name,
                   interval_id,
                   n_seconds
            from notification_intervals
            order by n_seconds
        </querytext>
    </fullquery>

    <fullquery name="notification::get_intervals.select_intervals">
        <querytext>
            select name,
                   notification_intervals.interval_id
            from notification_intervals,
                 notification_types_intervals
            where notification_intervals.interval_id = notification_types_intervals.interval_id
            and type_id = :type_id
            order by n_seconds
        </querytext>
    </fullquery>

    <fullquery name="notification::get_delivery_methods.select_delivery_methods">
        <querytext>
            select pretty_name,
                   notification_delivery_methods.delivery_method_id
            from notification_delivery_methods,
                 notification_types_del_methods
            where notification_delivery_methods.delivery_method_id = notification_types_del_methods.delivery_method_id
            and type_id = :type_id
            order by pretty_name
        </querytext>
    </fullquery>

    <fullquery name="notification::delete.delete_mappings">
        <querytext>
            delete
            from notification_user_map
            where notification_id = :notification_id
        </querytext>
    </fullquery>

</queryset>
