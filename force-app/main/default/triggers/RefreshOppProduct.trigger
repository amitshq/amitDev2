trigger RefreshOppProduct on OpportunityLineItem (after insert, after update) {
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate){
            List<RefreshProductPassive__e > refreshDataTableEvents = new List<RefreshProductPassive__e >();
            for (OpportunityLineItem opItem : Trigger.new) {
                refreshDataTableEvents.add(new RefreshProductPassive__e (
                    recordId__c  = opItem.OpportunityId      
                ));
            }
            EventBus.publish(refreshDataTableEvents);
        }
    }
 }