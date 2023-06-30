trigger ContactManage on Contact (after insert,after update, after delete) {
    if(Trigger.isInsert|| Trigger.isUpdate){
        Map<ID,list<Contact>> mapcon = new Map<ID,list<Contact>>();
        list<Contact> cons = new list<Contact>();
        system.debug(LimitsSnapshot.getInstance());
        for(Contact cs :Trigger.new){
            cons = [select id,name,AccountId from contact where accountid=:cs.accountid and accountid!=null];
        }
        if(cons.size()>0){
            for(Contact cs :cons){
                //if the AccountId is present, add the contact 
                if(mapcon.containsKey(cs.AccountId)) {
                    mapcon.get(cs.AccountId).add(cs);
                    
                }
                //else, create a new list
                else{
                    mapcon.put(cs.AccountId,new list<Contact>{cs});
                }
            }
        }
        
        if(mapcon.size()>0){
            //Iterate the Map with key[acID]>>AccountID
            for(ID acID: mapcon.keySet()){
                Account ac = [select id,Total_Contact__c  from account where id=:acID limit 1];
                if(ac!=null && ac.Total_Contact__c!=mapcon.get(acID).size()){
                    ac.Total_Contact__c=mapcon.get(acID).size();
                }
                if(ac!=null){
                    update ac; 
                }
            }
            cons.clear();
        }
        
    }
    //Delete
    if(Trigger.isDelete){
        for(Contact cs :Trigger.old){
            //Get the list of contacts
            list<Contact> cons = [select id,name from contact where accountid=:cs.accountid and accountid!=null];
            if(cons!=null && cons.size()>0){
                Account ac = [select id,Total_Contact__c  from account where id=:cs.accountid limit 1];
                if(ac!=null){
                    ac.Total_Contact__c=cons.size();
                }
                update ac;
            }
        }
    }
}