/*
AccountHelper Overview

The `AccountHelper` class is designed to provide helper methods that assist in performing specific operations on Account records. 
This class is intended to modularize the logic used in the `AccountTrigger` to ensure separation of concerns, improve readability, and ease maintenance. 

This class is currently stubbed out. As part of this exercise, you are expected to:
1. Implement the method bodies to carry out the specified operations on Account records.
2. Refactor the `AccountTrigger` to utilize the methods provided in this `AccountHelper` class.

Methods:
- `setTypeProspect(SObject objects)`: 
    - Purpose: Update the 'Type' field of the given Account record to 'Prospect' if it's not already set.
    - Note: You'll likely need to adjust the method signature to accept the necessary parameters.

- `addressCopy()`: 
    - Purpose: Copy the shipping address of the Account to its billing address. 
    - Note: You'll likely need to adjust the method signature to accept the necessary parameters.

- `setRating`: 
    - Purpose: Evaluate certain conditions on the Account and assign a rating based on that evaluation. You'll need to define the method's signature and implement its logic.

- `defaultContact`: 
    - Purpose: Create a default contact related to the Account after the Account is inserted. You'll need to define the method's signature and implement its logic.

Remember:
Always ensure that your helper methods are bulk-safe to handle multiple records efficiently. 
*/
public with sharing class AccountHelper extends TriggerHandler {
    

        /*
    * Account Trigger
    * When an account is inserted change the account type to 'Prospect' if there is no value in the type field.
    * Trigger should only fire on insert.
    */

    public void setTypeProspect(List<SObject> objects){

        Schema.SObjectType objType = objects.getSObjectType();
        if (objType == Schema.Account.SObjectType) { // Check if it's an Account    SObjectType
            List<Account> accounts = (List<Account>)objects; // Cast the whole list

        for (Account acc : accounts) {
      
                if (acc.Type == null) {
                acc.Type = 'Prospect';
                }   
            }    
        }
    }

    public void addressCopy(){

    }

    //[public | private ] [static] data_type setRating (input parameters) {
    //  The body of the method
    //}

    //[public | private ] [static] data_type defaultContact (input parameters) {
    //  The body of the method
    //}

    public override void beforeInsert() {
        // Implement logic to be executed before inserting Account records
        setTypeProspect(Trigger.new);
    }
    public override void afterInsert() {
        // Implement logic to be executed after inserting Account records
    }

}
