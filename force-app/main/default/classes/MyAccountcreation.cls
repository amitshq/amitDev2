Public class MyAccountcreation{
    public static List<Account> createacc(){
        List<Account> acc = new List<Account>([SELECT CreatedbyID,Account.Name,(SELECT name,Contact.FirstName, Contact.LastName FROM Account.Contacts) FROM Account]); 

        
        
        
        for (Account ac : acc) { 
            system.debug(ac); 
        }
        return acc;    
    }
}