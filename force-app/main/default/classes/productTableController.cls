public with sharing class productTableController {
   
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getContacts(List<String> selectedFields, String recordId){
        String s = '';
        Integer i = 0;
        List<OpportunityLineItem> opList = new List<OpportunityLineItem>();
        List<Product2> opListProd = new list<Product2>();
        for(String field : selectedFields){
            if(i == 0){
                s+= field;
            }else{
                s+= ','+field;
            }
            i++;
            
        }
        
        String query;
        if(recordId!=null){
            //Fetch the OpportunityLineItems from Opportunityid
            opList= [SELECT id,product2.id,product2.name,product2.productcode,ListPrice,Description,Total_Best_Case_value__c,Best_Case_Delta__c ,
                     Total_Promise_Case_value__c,Total_Worst_Case_value__c,Promise_Case_Delta__c ,Worst_Case_Delta__c ,
                     UnitPrice,Quantity from OpportunityLineItem where OpportunityId=:recordId];
            if(opList!=null){
                return opList;
            }
            
        }
        return opList;
    }
    
    @AuraEnabled(cacheable=false)
    public static List<OpportunityLineItem> getSyncProducts(String recordId){
        List<OpportunityLineItem> opList = new List<OpportunityLineItem>();
        String query;
        if(recordId!=null){
            //Fetch the OpportunityLineItems from Opportunityid
            opList= [SELECT id,product2.id,product2.name,product2.productcode,ListPrice,Description,Total_Best_Case_value__c,Best_Case_Delta__c ,
                     Total_Promise_Case_value__c,Total_Worst_Case_value__c,Promise_Case_Delta__c ,Worst_Case_Delta__c ,
                     UnitPrice,Quantity from OpportunityLineItem where OpportunityId=:recordId];
            if(opList!=null){
                return opList;
            }
        }
        return opList;
    }
        
    @AuraEnabled(cacheable=true)
    public static List<String> getContactFields(){
        SObjectType contactType = Schema.getGlobalDescribe().get('Product2');
        Map<String,Schema.SObjectField> mfields = contactType.getDescribe().fields.getMap();
        
        List<String> sObjectDetailsList = new List<String>();
        for(String s : mfields.keySet()){
            sObjectDetailsList.add(String.valueOf(mfields.get(s)));
        }
        return sObjectDetailsList;
    }
}