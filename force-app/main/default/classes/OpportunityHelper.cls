/*
OpportunityHelper Overview

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
public with sharing class OpportunityHelper extends TriggerHandler {
    private List<Opportunity> newOpps;
    private Map<Id, SObject> oldOppMap;
   
    public override void beforeInsert() { 
             // Set default Type for new Opportunities
             Schema.SObjectType objType = Trigger.new.getSObjectType();
             if (objType == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
             List<Opportunity> opps = (List<Opportunity>)Trigger.new; // Cast the whole list
             for(Opportunity opp : opps) {
                if (opp.Type == null){
                    opp.Type = 'New Customer';
                }        
             }  
            }  
    }

    public override void beforeUpdate() {}    

    public override void beforeDelete() {
            // Prevent deletion of closed Opportunities
             // Set default Type for new Opportunities
             Schema.SObjectType objType = Trigger.old.getSObjectType();
             if (objType == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
             List<Opportunity> opps = (List<Opportunity>)Trigger.old; // Cast the whole list
             
            for (Opportunity oldOpp : opps){
                if (oldOpp.IsClosed){
                    oldOpp.addError('Cannot delete closed opportunity');
                }
            }
        }
    }

    public override void afterInsert() {
            // Create a new Task for newly inserted Opportunities
            Schema.SObjectType objType = Trigger.new.getSObjectType();
            if (objType == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
            List<Opportunity> opps = (List<Opportunity>)Trigger.new; // Cast the whole list
           for (Opportunity opp : opps){
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                tsk.WhoId = opp.Primary_Contact__c;
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3);
                insert tsk;                    
            }
        }
    }
    public override void afterUpdate() {/*
            // Append Stage changes in Opportunity Description
            Schema.SObjectType objType = Trigger.new.getSObjectType();
            if (objType == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
            List<Opportunity> opps = (List<Opportunity>)Trigger.new; // Cast the whole list
           for (Opportunity opp : opps){
                for (Opportunity oldOpp : Trigger.old){
                    if (opp.StageName != null){
                        opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                    }
                }                
            }
            update Trigger.new;
        }*/
    }
    public override void afterDelete() {
        //notifyOwnersOpportunityDeleted(objects);
    }
    public override void afterUndelete() {
        //assignPrimaryContact(objects);
    }


    //[public | private ] [static] data_type setRating (input parameters) {
    //  The body of the method
    //}

    //[public | private ] [static] data_type defaultContact (input parameters) {
    //  The body of the method
    //}
    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */
    private static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : opps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {[SELECT Id, Email FROM User WHERE Id = :opp.OwnerId].Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }

    /*
    assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact.
    */
    private static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for (Opportunity opp : oppNewMap.values()){            
            Contact primaryContact = [SELECT Id, AccountId FROM Contact WHERE Title = 'VP Sales' AND AccountId = :opp.AccountId LIMIT 1];
            if (opp.Primary_Contact__c == null){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = primaryContact.Id;
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
        update oppMap.values();
    }
}
