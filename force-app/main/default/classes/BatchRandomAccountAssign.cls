global class BatchRandomAccountAssign implements Database.Batchable<sObject>
{
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query = 'SELECT Id,Name,title,accountid FROM Contact where accountid=null';
        
        return Database.getQueryLocator(query); 
    }
    global void execute(Database.BatchableContext BC, List<Contact> scope)
    {
        list<Account> acs = [select id from account];
        for(Contact a : scope)
        {
            if(a.accountid==null){
                Integer randomNumber = Integer.valueof((Math.random() * acs.size()-1));
                a.accountid=acs[randomNumber].id;
            }
            
        }
        update scope;
    }
    global void finish(Database.BatchableContext BC) {
    }
}