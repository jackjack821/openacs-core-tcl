ad_library {
    Installation procs for authentication, account management, and password management,

    @author Lars Pind (lars@collaobraid.biz)
    @creation-date 2003-05-13
    @cvs-id $Id$
}

namespace eval auth {}
namespace eval auth::authentication {}
namespace eval auth::password {}
namespace eval auth::registration {}
namespace eval auth::get_doc {}
namespace eval auth::process_doc {}


ad_proc -private auth::package_install {} {} {

    db_transaction {
        # Create service contracts
        auth::authentication::create_contract
        auth::password::create_contract
        auth::registration::create_contract
        auth::get_doc::create_contract
        auth::process_doc::create_contract

        # Register local authentication implementations and update the local authority
        auth::local::install

        # Register HTTP method for GetDocument
        auth::sync::get_doc::http::register_impl

        # Register IMS Enterprise 1.1 ProcessDocument implementation
        auth::sync::process_doc::ims::register_impl
    }
}

ad_proc -private auth::package_uninstall {} {} {

    db_transaction {

        # Unregister IMS Enterprise 1.1 ProcessDocument implementation
        auth::sync::process_doc::ims::unregister_impl

        # Unregister HTTP method for GetDocument
        auth::sync::get_doc::http::unregister_impl

        # Unregister local authentication implementations and update the local authority
        auth::local::uninstall

        # Delete service contracts
        auth::authentication::delete_contract
        auth::password::delete_contract
        auth::registration::delete_contract
        auth::get_doc::delete_contract
        auth::process_doc::delete_contract
    }
}


#####
#
# auth_authentication service contract
#
#####

ad_proc -private auth::authentication::create_contract {} {
    Create service contract for authentication.
} {
    set spec {
        name "auth_authentication"
        description "Authenticate users and retrieve their account status."
        operations {
            Authenticate {
                description {
                    Validate this username/password combination, and return the result.
                    Valid auth_status codes are 'ok', 'no_account', 'bad_password', 'auth_error', 'failed_to_connect'. 
                    The last, 'failed_to_connect', is reserved for communications or implementation errors.
                    auth_message is a human-readable explanation of what went wrong, may contain HTML. 
                    Only checked if auth_status is not ok.
                    Valid account_status codes are 'ok' and 'closed'.
                    account_message may be supplied regardless of account_status, and may contain HTML.
                }
                input {
                    username:string
                    password:string
                    parameters:string,multiple
                }
                output {
                    auth_status:string
                    auth_message:string
                    account_status:string
                    account_message:string
                }
            }
            GetParameters {
                description {
                    Get an arraay-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}

ad_proc -private auth::authentication::delete_contract {} {
    Delet service contract for authentication.
} {
    acs_sc::contract::delete -name "auth_authentication"
}

#####
#
# auth_password service contract
#
#####

ad_proc -private auth::password::create_contract {} {
    Create service contract for password management.
} {
    set spec {
        name "auth_password"
        description "Update, reset, and retrieve passwords for authentication."
        operations {
            CanChangePassword {
                description {
                    Return whether the user can change his/her password through this implementation.
                    The value is not supposed to depend on the username and should be cachable.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    changeable_p:boolean
                }
                iscachable_p "t"
            }
            ChangePassword {
                description {
                    Change the user's password. 
                }
                input {
                    username:string
                    old_password:string
                    new_password:string
                    parameters:string,multiple
                }
                output {
                    password_status:string
                    password_message:string
                }
            }
            CanRetrievePassword {
                description {
                    Return whether the user can retrieve his/her password through this implementation.
                    The value is not supposed to depend on the username and should be cachable.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    retrievable_p:boolean
                }
                iscachable_p "t"
            }
            RetrievePassword {
                description {
                    Retrieve the user's password. The implementation can either return the password, in which case
                    the authentication API will email the password to the user. Or it can email the password
                    itself, in which case it would return the empty string for password.
                }
                input {
                    username:string
                    parameters:string,multiple
                }
                output {
                    password_status:string
                    password_message:string
                    password:string
                }
            }
            CanResetPassword {
                description {
                    Return whether the user can reset his/her password through this implementation.
                    The value is not supposed to depend on the username and should be cachable.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    resettable_p:boolean
                }
                iscachable_p "t"
            }
            ResetPassword {
                description {
                    Reset the user's password to a new, randomly generated value. 
                    The implementation can either return the password, in which case
                    the authentication API will email the password to the user. Or it can email the password
                    itself, in which case it would return the empty string.
                }
                input {
                    username:string
                    parameters:string,multiple
                }
                output {
                    password_status:string
                    password_message:string
                    password:string
                }
            }
            GetParameters {
                description {
                    Get an arraay-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}

ad_proc -private auth::password::delete_contract {} {
    Delete service contract for password management.
} {
    acs_sc::contract::delete -name "auth_password"
}


#####
#
# auth_registration service contract
#
#####

ad_proc -private auth::registration::create_contract {} {
    Create service contract for account registration.
} {
    set spec {
        name "auth_registration"
        description "Registering accounts for authentication"
        operations {
            GetElements {
                description {
                    Get a list of required and a list of optional fields available when registering accounts through this
                    service contract implementation.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    requiered:string,multiple
                    optional:string,multiple
                }
            }
            Register {
                description {
                    Register a new account. Valid status codes are: 'ok', 'data_error', and 'reg_error', and 'fail'.
                    'data_error' means that the implementation is returning an array-list of element-name, message 
                    with error messages for each individual element. 'reg_error' is any other registration error, 
                    and 'fail' is reserved to communications or implementation errors.
                }
                input {
                    parameters:string,multiple
                    username:string
                    authority_id:integer
                    first_names:string
                    last_name:string
                    email:string
                    url:string
                    password:string
                    secret_question:string
                    secret_answer:string
                }
                output {
                    creation_status:string
                    creation_message:string
                    element_messages:string,multiple
                    account_status:string
                    account_message:string
                }
            }
            GetParameters {
                description {
                    Get an array-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}


ad_proc -private auth::registration::delete_contract {} {
    Delete service contract for account registration.
} {
    acs_sc::contract::delete -name "auth_registration"
}


#####
#
# auth_get_doc service contract
#
#####

ad_proc -private auth::get_doc::create_contract {} {
    Create service contract for account registration.
} {
    set spec {
        name "GetDocument"
        description "Retrieve a document, e.g. using HTTP, SMP, FTP, SOAP, etc."
        operations {
            GetDocument {
                description {
                    Retrieves the document. Returns doc_status of 'ok', 'get_error', or 'failed_to_connect'. 
                    If not 'ok', then it should  set doc_message to explain the problem. If 'ok', it must set
                    document to the document retrieved.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    doc_status:string
                    doc_message:string
                    document:string
                }
            }
            GetParameters {
                description {
                    Get an array-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}


ad_proc -private auth::get_doc::delete_contract {} {
    Delete service contract for account registration.
} {
    acs_sc::contract::delete -name "GetDocument"
}



#####
#
# auth_process_doc service contract
#
#####

ad_proc -private auth::process_doc::create_contract {} {
    Create service contract for account registration.
} {
    set spec {
        name "auth_sync_process"
        description "Process a document containing user information from a remote authentication authority"
        operations {
            ProcessDocument {
                description {
                    Process a user synchronization document.
                }
                input {
                    job_id:integer
                    document:string
                    parameters:string,multiple
                }
            }
            GetParameters {
                description {
                    Get an array-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}


ad_proc -private auth::process_doc::delete_contract {} {
    Delete service contract for account registration.
} {
    acs_sc::contract::delete -name "auth_sync_process"
}



