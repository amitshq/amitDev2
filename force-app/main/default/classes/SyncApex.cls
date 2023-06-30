public class SyncApex {
    public static void queryAgg(){
        list<Contact> csp = [select id,account.name, name from contact where accountid!=null];
        system.debug(csp.size());
        system.debug('Query executed'+Limits.getDmlRows());
    }
}