@isTest
private class SlackAPIExtTest {
    @testSetup static void setup() {
        Profile p2 =  [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='testk1@gmail.com', 
                          EmailEncodingKey='UTF-8', FirstName='TestBOX1',LastName='Testing2', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p2.Id,companyname='test',Title='Principal',
                          TimeZoneSidKey='America/Los_Angeles', UserName='nest230@gmail.com');
        INSERT u;
        ID communityId1 = Network.getnetworkid();
        List<String> Networkscope_list = System.Label.NetworkScopeID_List.split(',');
        CollaborationGroup cg = new CollaborationGroup();
        cg.CanHaveGuests = false;
        cg.CollaborationType = 'public';
        cg.Name = 'My topic Test Group';
        cg.NetworkId = communityId1;
        cg.OwnerId = userinfo.getuserid();
        INSERT cg;
        //Setup ContentVersion
        ContentVersion contentVersion = new ContentVersion(Title='testpicture',PathOnClient='Pic.jpg',VersionData=Blob.valueOf('Test Content'),IsMajorVersion = true);
        insert contentVersion;
        //create ContentDistribution  record
        ContentDistribution cdl = new ContentDistribution();
        cdl.ContentVersionID = contentVersion.Id;
        cdl.name='test docs';
        insert cdl;
        //FeedItems
        FeedItem post = new FeedItem();
        post.ParentId = userinfo.getuserid();
        post.NetworkScope = Networkscope_list[0];
        post.Body = 'THIS IS TEST';
        post.Title = 'Subject 2';
        post.IsRichText = true;
        post.Status = 'Published';
        post.Visibility = 'AllUsers';
        post.RelatedRecordId=contentVersion.id;//Relatedrecord Files ID
        //Cant add post as this is ContentPost Type
        post.type = 'QuestionPost';
        INSERT post;//INSERT Feeds
        //FeedComments
        list<FeedComment> ffds = new list<FeedComment>();
        for(Integer i=0;i<3;i++){
            FeedComment fedc = new FeedComment(feeditemid=post.id,commentbody='This is Comment',relatedrecordid=contentVersion.id);
            ffds.add(fedc);  
        }
        INSERT ffds;//INSERT FeedComment
        //Second Test fro Feeditems and FeedComments
        FeedItem post1 = new FeedItem();
        post1.ParentId = userinfo.getuserid(); 
        post1.NetworkScope = Networkscope_list[0];
        post1.Body =  'THIS IS TEST2 ';
        post1.IsRichText = true;
        post1.Status = 'Published';
        post1.Type = 'QuestionPost';
        post1.Visibility = 'AllUsers';
        post1.Title = 'Subject 1';
        post1.RelatedRecordId=contentVersion.id;//Relatedrecord Files ID
        INSERT post1;//INSERT Feeds
        
        //FeedComments
        list<FeedComment> ffds1 = new list<FeedComment>();
        for(Integer i=0;i<3;i++){
            FeedComment fedc = new FeedComment(feeditemid=post1.id,commentbody='This is Comment 22',relatedrecordid=contentVersion.id);
            ffds1.add(fedc);  
        }
        INSERT ffds1;
        
        //Topic 1
        Topic tt = new Topic(Name='topictest',NetworkId=Networkscope_list[0]);
        INSERT tt;
        //Topic 2
        Topic tt1 = new Topic(Name='topictest1',NetworkId=Networkscope_list[0]);
        INSERT tt1;
        
        //TopicAssigments 1
        for(Integer i=0;i<2;i++){
            TopicAssignment ta = new TopicAssignment(EntityId=post.id,NetworkId=Networkscope_list[0],TopicId=tt.id);
            //upsert ta;
            TopicAssignment ta1 = new TopicAssignment(EntityId=post1.id,NetworkId=Networkscope_list[0],TopicId=tt1.id);
            //upsert ta1;
        }
        //TopicAssigments 2
        for(Integer i=0;i<2;i++){
            TopicAssignment ta = new TopicAssignment(EntityId=post.id,NetworkId=Networkscope_list[0],TopicId=tt1.id);
            //upsert ta;
            TopicAssignment ta1 = new TopicAssignment(EntityId=post1.id,NetworkId=Networkscope_list[0],TopicId=tt.id);
            //upsert ta1;
        }     
        
    }
    //PostMessage -pass
    @isTest static void testMethod1() {
        //list of feed items
        list<Feeditem> fedsitem = new list<Feeditem>();
        Feeditem fe= [select id,Networkscope,Body,title,Type,parentid,relatedrecordid FROM Feeditem WHERE ParentID=:userinfo.getuserid() AND title =: 'Subject 1' LIMIT 1];
        //Check if the NetworkScope is not null and contains in Networkscope list
        fedsitem.add(fe);
        Test.startTest();
        try{ 
            Test.setMock(HttpCalloutMock.class, new TestSlackMockOut());//By Pass Callout
            SlackAPINew.postMessage(fedsitem);//test1
        }catch(Exception  err){
        }
        Test.stopTest();
    }
    //GetTopic -pass
    @isTest static void testMethod2(){
        list<FeedItem> fe = [select id,Networkscope,Body,title,Type,parentid,relatedrecordid FROM Feeditem WHERE title='Subject 1' limit 1];
        //Set of Feed ids
        Set<id> fedsids = new Set<id>();
        //INSERT Feed ids into the set
        for(FeedItem fedids:fe){
            fedsids.add(fedids.id);
        }
        SlackAPINew.GetTopics(fedsids);
    }
    //updatefeeditem -pass
    @isTest static void testMethod4() {
        //list of feed items
        list<Feeditem> fedsitem = new list<Feeditem>();
        Feeditem fe= [select id,Networkscope,Body,title,Type,parentid FROM Feeditem WHERE ParentID=:userinfo.getuserid() AND title =: 'Subject 1' LIMIT 1];
        System.debug(fe);
        //Check if the NetworkScope is not null and contains in Networkscope list
        fedsitem.add(fe);
        Test.startTest();
        try{ 
            Test.setMock(HttpCalloutMock.class, new TestSlackMockOut());//By Pass Callout
            SlackAPINew.updatefeeditem(fedsitem,'test','Update',false);//test1
            SlackAPINew.updatefeeditem(fedsitem,'test','Delete',false);//test2
        }catch(Exception  err){
        }
        Test.stopTest();
        
    }
    
    //Postcomment
    @isTest static void testMethod6() {
        User us = [select id,FirstName,LastName,Email,CompanyName,Title,accountid,account.name,contactid FROM User WHERE email=:'testk1@gmail.com'];
        //list of feed items
        list<Feeditem> feeds = new list<Feeditem>();
        //List of Networkscope ids
        List<String> Networkscope_list = System.Label.NetworkScopeID_List.split(',');
        Feeditem fe= [select id,Networkscope,Body,title,Type,parentid,relatedrecordid FROM Feeditem WHERE ParentID=:userinfo.getuserid() AND title =: 'Subject 2' LIMIT 1];
        //Feeditem fe= [select id,Networkscope,Body,title,Type,parentid FROM Feeditem WHERE ParentID=:userinfo.getuserid() LIMIT 1];
        //Check if the NetworkScope is not null and contains in Networkscope list
        if((fe.NetworkScope!=null || fe.NetworkScope!='') && (Networkscope_list.contains(fe.NetworkScope))){
            feeds.add(fe);
        }
        
        //Map chatter group
        Map<Id,String> mapchattergroup = new Map<ID,String>(); 
        for(TopicAssignment ls:[SELECT EntityId, Topic.Name,topic.managedtopictype FROM TopicAssignment WHERE Entityid IN: feeds and topic.managedtopictype ='Content, Navigational'] ){
            //Check if the Entityid is present in the map
            if(mapchattergroup.containsKey(ls.EntityId)){
                //Get the list of existing Topics names
                String tops = mapchattergroup.get(ls.EntityId);
                mapchattergroup.put(ls.EntityId,tops);
            }
            else{
                //Make a new list and the topic names
                mapchattergroup.put(ls.EntityId,ls.topic.name);
            }
        }
        Map<id,list<String>> maptopic = new map<id,list<String>>();
        for(TopicAssignment ls:[SELECT EntityId, Topic.Name FROM TopicAssignment WHERE Entityid IN: feeds] ){
            list<String> tops = new list<String>();
            tops.add(ls.Topic.name);
            maptopic.put(ls.EntityId,tops);
        }
        Map<id,list<feedcomment>> mapfeedcomments = new Map<id,list<feedcomment>>();
        for(FeedComment lsfeeds:[select id,commentbody,feeditemid FROM FeedComment WHERE feeditemid in: feeds] ){
            if(mapfeedcomments.containsKey(lsfeeds.FeedItemId)){
                //Get the list of existing Comment
                list<feedcomment> Comtops = mapfeedcomments.get(lsfeeds.FeedItemId);
                //Add the topic names
                Comtops.add(lsfeeds);
                mapfeedcomments.put(lsfeeds.FeedItemId,Comtops);
            }
            else{
                //Make a new list and the comments
                mapfeedcomments.put(lsfeeds.FeedItemId,new list<feedcomment> {lsfeeds});   
            }
        } 
        List<slackv2__Message_Destination__c> messagecol = [select id FROM slackv2__Message_Destination__c LIMIT  1];
        Test.startTest();
        try{ 
            Test.setMock(HttpCalloutMock.class, new TestSlackMockOut());//By Pass Callout
            SlackAPINew.postcomment(mapfeedcomments,'Insert','test');
        }catch(Exception  err){
        }
        Test.stopTest();
        
    }
    //ContentDelivery Links Checking
    @isTest static void testMethod3(){
        Map<Id,ContentDistribution> cd1 = new Map<Id,ContentDistribution>();
        Feeditem fe= [select id,Networkscope,Body,title,Type,parentid,relatedrecordid FROM Feeditem WHERE title='Subject 1' LIMIT 1];
        Set<String> Contentdocumentid1 = SlackAPINew.getContentDocumentID(fe.body);
        
        //Params--->Set<String> Contentdocumentid1, Map<Id,ContentDistribution> cd1
        SlackAPINew.ContentLinkURLCreater(Contentdocumentid1, cd1);
    }
    //Test main method 
    @isTest static void testMetthod5(){
        User us = [select id,FirstName,LastName,Email,CompanyName,Title,accountid,account.name,contactid FROM User WHERE email=:'testk1@gmail.com'];
        
        //list of feed items
        list<Feeditem> feeds = new list<Feeditem>();
        //List of Networkscope ids
        List<String> Networkscope_list = System.Label.NetworkScopeID_List.split(',');
        Feeditem fe= [select id,Networkscope,Body,title,Type,parentid,relatedrecordid FROM Feeditem WHERE title=:'Subject 1' LIMIT 1];
        //Check if the NetworkScope is not null and contains in Networkscope list
        if((fe.NetworkScope!=null || fe.NetworkScope!='') && (Networkscope_list.contains(fe.NetworkScope))){
            feeds.add(fe);
        }
        
        //Map chatter group
        Map<Id,String> mapchattergroup = new Map<ID,String>(); 
        for(TopicAssignment ls:[SELECT EntityId, Topic.Name,topic.managedtopictype FROM TopicAssignment WHERE Entityid IN: feeds and topic.managedtopictype ='Content, Navigational'] ){
            //Check if the Entityid is present in the map
            if(mapchattergroup.containsKey(ls.EntityId)){
                //Get the list of existing Topics names
                String tops = mapchattergroup.get(ls.EntityId);
                mapchattergroup.put(ls.EntityId,tops);
            }
            else{
                //Make a new list and the topic names
                mapchattergroup.put(ls.EntityId,ls.topic.name);
            }
        }
        Map<id,list<String>> maptopic = new map<id,list<String>>();
        for(TopicAssignment ls:[SELECT EntityId, Topic.Name FROM TopicAssignment WHERE Entityid IN: feeds] ){
            list<String> tops = new list<String>();
            tops.add(ls.Topic.name);
            maptopic.put(ls.EntityId,tops);
        }
        Map<id,list<feedcomment>> mapfeedcomments = new Map<id,list<feedcomment>>();
        for(FeedComment lsfeeds:[select id,commentbody,feeditemid FROM FeedComment WHERE feeditemid in: feeds] ){
            if(mapfeedcomments.containsKey(lsfeeds.FeedItemId)){
                //Get the list of existing Comment
                list<feedcomment> Comtops = mapfeedcomments.get(lsfeeds.FeedItemId);
                //Add the topic names
                Comtops.add(lsfeeds);
                mapfeedcomments.put(lsfeeds.FeedItemId,Comtops);
            }
            else{
                //Make a new list and the comments
                mapfeedcomments.put(lsfeeds.FeedItemId,new list<feedcomment> {lsfeeds});   
            }
         } 
        List<slackv2__Message_Destination__c> messagecol = [select id FROM slackv2__Message_Destination__c LIMIT  1];
        Test.startTest();
        try{ 
            Test.setMock(HttpCalloutMock.class, new TestSlackMockOut());//By Pass Callout
            SlackAPINew.SlackSendMain(feeds,us,mapchattergroup,maptopic, mapfeedcomments,'Insert','test','test','Update',false);
            SlackAPINew.SlackSendMain(feeds,us,mapchattergroup,maptopic, mapfeedcomments,'Update','test','test','Delete',false);
            SlackAPINew.SlackSendMain(feeds,us,mapchattergroup,maptopic, mapfeedcomments,'Update','test','test','',false);
            
        }
        catch(Exception  err){
        }
        Test.stopTest();
    }   
}