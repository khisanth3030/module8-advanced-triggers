/*
OpportunityHelper Overview


*/
public with sharing class OpportunityHelper extends TriggerHandler {
  
    public override void beforeInsert() { 
        defaultType(Trigger.new);
    }

    public override void beforeUpdate() {
        validateAmount(Trigger.new);
        setPrimaryContactToCEO(Trigger.new);
    }    

    public override void beforeDelete() {
        preventClosedOpportunityDeletion(Trigger.old);
    }

    public override void afterInsert() {
        createTaskForNewOpportunities(Trigger.new);
    }
    public override void afterUpdate() {
        appendStageChangesInDescription(Trigger.new, Trigger.old);
    }

    public override void afterDelete() {
        notifyOwnersOpportunityDeleted(Trigger.old);
        preventClosedOpportunityDeletionForBankingAccounts(Trigger.old);           
    }
    
    public override void afterUndelete() {
        assignPrimaryContact(Trigger.new, Trigger.old);         
    }




    // Set default Type for new Opportunities

     private void defaultType(List<SObject> objectsNew){
             Schema.SObjectType objType = objectsNew.getSObjectType();
             if (objType == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
             List<Opportunity> opps = (List<Opportunity>)objectsNew; // Cast the whole list
             for(Opportunity opp : opps) {
                if (opp.Type == null){
                    opp.Type = 'New Customer';
                }        
            }  
        } 
    } 
    /*
    * Opportunity Trigger
    * When an opportunity is updated validate that the amount is greater than 5000.
    * Trigger should only fire on update.
    */
    private void validateAmount(List<SObject> objectsNew){
    Schema.SObjectType objType = objectsNew.getSObjectType();
    if (objType == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
        List<Opportunity> opps = (List<Opportunity>)objectsNew; // Cast the whole list
        for(Opportunity opp : opps){
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }
    }

    /*
    * Opportunity Trigger
    * When an opportunity is updated set the primary contact on the opportunity to the contact with the title of 'CEO'.
    * Trigger should only fire on update.
    */
    private void setPrimaryContactToCEO(List<SObject> objectsNew){
        Schema.SObjectType objType = objectsNew.getSObjectType();
        if (objType == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
            List<Opportunity> opps = (List<Opportunity>)objectsNew; // Cast the whole list
            
            //Get contacts related to the opportunity account
            Set<Id> accountIds = new Set<Id>();
            for(Opportunity opp : opps){
                accountIds.add(opp.AccountId);
            }
            
            Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
            Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

            for (Contact cont : contacts.values()) {
                if (!accountIdToContact.containsKey(cont.AccountId)) {
                    accountIdToContact.put(cont.AccountId, cont);
                }
            }

            for(Opportunity opp : opps){
                if(opp.Primary_Contact__c == null){
                    if (accountIdToContact.containsKey(opp.AccountId)){
                        opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                    }
                }
            }
        }
}

// Prevent deletion of closed Opportunities
    private void preventClosedOpportunityDeletion(List<SObject> objectsOld){
            Schema.SObjectType objType = objectsOld.getSObjectType();
            if (objType == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
            List<Opportunity> opps = (List<Opportunity>)objectsOld; // Cast the whole list
            
           for (Opportunity oldOpp : opps){
               if (oldOpp.IsClosed){
                   oldOpp.addError('Cannot delete closed opportunity');
               }
           }
       }
    }
    // Create a new Task for newly inserted Opportunities
    private void createTaskForNewOpportunities( List<SObject> objectsNew){
                
            Schema.SObjectType objType = objectsNew.getSObjectType();
            if (objType == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
                List<Opportunity> opps = (List<Opportunity>)objectsNew; // Cast the whole list
                List<Task> tasksToInsert = new List<Task>();
                for (Opportunity opp : opps){
                    Task tsk = new Task();
                    tsk.Subject = 'Call Primary Contact';
                    tsk.WhatId = opp.Id;
                    tsk.WhoId = opp.Primary_Contact__c;
                    tsk.OwnerId = opp.OwnerId;
                    tsk.ActivityDate = Date.today().addDays(3);
                    tasksToInsert.add(tsk);                    
                }
                insert tasksToInsert;
            }
        }

// Append Stage changes in Opportunity Description        
private void appendStageChangesInDescription(List<SObject> newObjects, List<SObject> oldObjects){
            
        Schema.SObjectType objTypeNew = newObjects.getSObjectType();
        Schema.SObjectType objTypeOld = oldObjects.getSObjectType();
        if (objTypeNew == Schema.Opportunity.SObjectType && 
            objTypeOld == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
            List<Opportunity> oppNs = (List<Opportunity>)newObjects; // Cast the whole list
            List<Opportunity> oppOs = (List<Opportunity>)oldObjects; // Cast the whole list
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            Map<Id, Opportunity> oppOMap = new Map<Id, Opportunity>(oppOs);

            String currentDateTime = DateTime.now().format();
            for (Opportunity opp : oppNs) {
                if (opp.StageName != null && opp.StageName != oppOMap.get(opp.Id).StageName) {
                    Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                    oppToUpdate.Description += '\n  Stage Change:' + opp.StageName + ':' + currentDateTime;
                    oppsToUpdate.add(oppToUpdate);
                }
            }
            if (oppsToUpdate.size() > 0){
                System.debug('Number of Opportunities updated: ' + oppsToUpdate.size());
                if (Schema.sObjectType.Opportunity.isUpdateable())
                try{update oppsToUpdate;} catch (Exception e){
                    System.debug('Exception: ' + e.getMessage());
                throw e;}    else {
                    System.debug('Insufficient permissions to update Opportunity records.');
                }         
            }
        }
    }


    /*
    * Opportunity Trigger
    * When an opportunity is deleted prevent the deletion of a closed won opportunity if the account industry is 'Banking'.
    * Trigger should only fire on delete.
    */
    private void preventClosedOpportunityDeletionForBankingAccounts(List<SObject> objectsOld){
        Schema.SObjectType objType = objectsOld.getSObjectType();
        if (objType == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
            List<Opportunity> opps = (List<Opportunity>)objectsOld; // Cast the whole list

            //Account related to the opportunities 
            Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :opps)]);
            for(Opportunity opp : opps){
                if(opp.StageName == 'Closed Won'){
                    if(accounts.get(opp.AccountId).Industry == 'Banking'){
                        opp.addError('Cannot delete a closed won opportunity for a banking account');
                    }
                }
            }
        }    
    }    

    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */
    private static void notifyOwnersOpportunityDeleted(List<SObject> objectsOld) {
        Schema.SObjectType objType = objectsOld.getSObjectType();
        if (objType == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
            List<Opportunity> opps = (List<Opportunity>)objectsOld; // Cast the whole list

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
    }

    /*
    assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact.
    */
    private static void assignPrimaryContact(List<SObject> objectsNew, List<SObject> objectsOld) {     
        Schema.SObjectType objType = objectsOld.getSObjectType();
        if (objType == Schema.Opportunity.SObjectType) { // Check if it's an Opportunity SObjectType
            List<Opportunity> opps = (List<Opportunity>)objectsOld; // Cast the whole list
            Map<Id, Opportunity> oppNewMap = new Map<Id, Opportunity>(opps);   
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
}
