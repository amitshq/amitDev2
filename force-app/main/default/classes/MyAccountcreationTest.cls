@isTest 
public class MyAccountcreationTest 
{
	  @isTest static void accContact()
	{
		  Account accObj=new Account();
        accObj.Name='Account1';
        accObj.Description='Account Created';
        insert accObj;
        
        Contact con=new Contact();
        con.LastName='Account Related Contact';
        con.AccountId=accObj.id;
        insert con;

        Test.startTest();
       MyAccountcreation.createacc();
        Test.stopTest();
	}
}