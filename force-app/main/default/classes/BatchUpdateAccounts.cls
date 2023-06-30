global class BatchUpdateAccounts implements Database.Batchable<sObject>
{
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query = 'SELECT Id,Name,title FROM Contact';
        
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Contact> scope)
    {
        //nullMr.
        list<String> titles=new list<String>{'Dev','Design','HR','Marketing', 'PM', 'SDEV', 'Manager'};
        for(Contact a : scope)
        {
            if(a.title=='nullMr.'){
                Integer randomNumber = Integer.valueof((Math.random() * titles.size()-1));
                a.title = titles[randomNumber];
            }
        }
        update scope;
    }
    global void finish(Database.BatchableContext BC) {
    }
}