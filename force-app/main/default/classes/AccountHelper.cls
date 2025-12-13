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
    
    public override void beforeInsert() {
        setTypeProspect(Trigger.new);
        addressCopy(Trigger.new);
        setRating(Trigger.new);
    }
    public override void afterInsert() {
        createDefaultContact(Trigger.new);
    }

    /*
    * setTypeProspect
    * When an account is inserted change the account type to 'Prospect' if there is no value in the type field.
    * Trigger should only fire on insert.
    */
    private void setTypeProspect(List<SObject> objects){

        Schema.SObjectType objType = objects.getSObjectType();
        if (objType == Schema.Account.SObjectType) { // Check if it's an Account    SObjectType
            List<Account> accounts = (List<Account>)objects; // Cast the whole list
        
            for (Account acc : accounts) {   
                    if (acc.Type == null) {acc.Type = 'Prospect';}   
            }    
        }
    }
 
    /*
    * addressCopy
    * When an account is inserted copy the shipping address to the billing address.
    * Trigger should only fire on insert.
    */
    private void addressCopy(List<SObject> objects){

        Schema.SObjectType objType = objects.getSObjectType();
        if (objType == Schema.Account.SObjectType) { // Check if it's an Account    SObjectType
            List<Account> accounts = (List<Account>)objects; // Cast the whole list
    

            for (Account acc : accounts) {
                if (acc.ShippingStreet != null) {acc.BillingStreet = acc.ShippingStreet;}
                if (acc.ShippingCity != null) {acc.BillingCity = acc.ShippingCity;}
                if (acc.ShippingState != null) {acc.BillingState = acc.ShippingState;}
                if (acc.ShippingPostalCode != null) {acc.BillingPostalCode = acc.ShippingPostalCode;}
                if (acc.ShippingCountry != null) {acc.BillingCountry = acc.ShippingCountry;}
            }               
        }    
    }

    
    /*
    * setRating
    * When an account is inserted set the rating to 'Hot' if the Phone, Website, and Fax is not empty.
    * Trigger should only fire on insert.
    */
    private void setRating(List<SObject> objects){

        Schema.SObjectType objType = objects.getSObjectType();
        if (objType == Schema.Account.SObjectType) { // Check if it's an Account    SObjectType
            List<Account> accounts = (List<Account>)objects; // Cast the whole list
        
            for (Account acc : accounts) {   
                    if (acc.Phone != null && acc.Website != null && acc.Fax != null) {
                        acc.Rating = 'Hot';
                    }   
            }    
        }
    }
 
    /*
    * createDefaultContact
    * When an account is inserted create a contact related to the account with the following default values:
    * LastName = 'DefaultContact'
    * Email = 'default@email.com'
    * Trigger should only fire on insert.
    */    
    private void createDefaultContact(List<SObject> objects){

        Schema.SObjectType objType = objects.getSObjectType();
        if (objType == Schema.Account.SObjectType) {  
            List<Account> accounts = (List<Account>)objects; // Cast the whole list
            List<Contact> contacts = new List<Contact>();   
            for(Account acc : accounts){
                Contact con = new Contact();
                con.LastName = 'DefaultContact';
                con.Email = 'default@email.com';
                con.AccountId = acc.Id;
                contacts.add(con);
            }
            insert contacts; 
        }
        
    }


}
