//The trigger adds a set of default products to an opportunity as soon as it gets created. 
//code can be modifed to have different set of products for different conditions, e.g. record-types or owners 
//the trigger uses for-inside-for, which isn't good for governor limit, so be careful while you implement this or modify this to remain within governor limits. 
trigger RetentionToOpportunity on Opportunity (after insert,after update) {
        
    List<OpportunityLineItem> oliList = new List<OpportunityLineItem>(); 		
    for(Opportunity o: trigger.new){
        list<OpportunityLineItem> pbeList = [SELECT id,product2.id,product2.name,product2.productcode,ListPrice,Description,Total_Best_Case_value__c,Best_Case_Delta__c ,
                                             Total_Promise_Case_value__c,Total_Worst_Case_value__c,Promise_Case_Delta__c ,Worst_Case_Delta__c , Worst_Retention__c,
                                             total_px__c,UnitPrice,Quantity from OpportunityLineItem where OpportunityId=:o.id];	
        if(pbeList.size() > 0 ){
            for(OpportunityLineItem op: pbeList){
                // o.Worst_Retention__c=Math.ceil(op.Total_Worst_Case_value__c/op.total_px__c);
            }
           
        }
       // update oliList; 
        
    }
    
}