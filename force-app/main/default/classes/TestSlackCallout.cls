/*
Description-Test Class of SlackFeedSupport
Date:13 July 2021
*/
@isTest 
private class TestSlackCallout {    
    static slackv2__Slack_Message__c getTestSlackMsg(){
        slackv2__Slack_Message__c s_messsage = new slackv2__Slack_Message__c(slackv2__Content__c = 'TestMessage',
                                                                             slackv2__User_Name__c='TestMessage',
                                                                             slackv2__Message_Url__c='thread_ts="1626339720.00340&cid=C024X2QF9MW',
                                                                             slackv2__Record_Id__c='0057F0000010DZOQA2'
                                                                            );
        insert s_messsage; 
        return s_messsage;
    }
    static slackv2__Slack_Message__c updateTestSlackMsg(){
        slackv2__Slack_Message__c sst = getTestSlackMsg();
        sst.slackv2__Content__c='TestMessage New';
        update sst;
        return sst;
    }
    
    static FeedItem getfeeds(){
        List<String> Networkscope_list = System.Label.NetworkScopeID_List.split(',');
        FeedItem f = new FeedItem();
        f.Body = 'legal test';
        f.parentID = UserInfo.getUserId();
        f.title='test123';
        f.NetworkScope = Networkscope_list[0];
        insert f;return f;
    }
    //Topic
    static Topic gettopics(){
        List<String> Networkscope_list = System.Label.NetworkScopeID_List.split(',');
        Topic tt = new Topic(Name='topictest',NetworkId=Networkscope_list[0]);
        INSERT tt;
        return tt;
    }
    //TopicAssignment Ops
    static TopicAssignment gettopicAssignment(){
        List<String> Networkscope_list = System.Label.NetworkScopeID_List.split(',');
        FeedItem feed = getfeeds();
        Topic topic = gettopics();
        TopicAssignment ta = new TopicAssignment(EntityId=feed.id,NetworkId=Networkscope_list[0],TopicId=topic.id);
        INSERT ta;
        return ta;
        
    } 
    //Update FeedItem
    static FeedItem getfeedsup(){
        FeedItem fs=  getfeeds();
        fs.Body='nos';
        update fs;
        return fs;
    }
    //Delete FeedItem
    static FeedItem getfeedsdel(){
        FeedItem fs=  getfeedsup();
        delete fs;
        return fs;
    }
    static FeedComment getfeedComm(){
        FeedComment fc = new FeedComment(Feeditemid=getfeeds().id,CommentBody='TestMessage');
        insert fc;return fc;
    }
    //Update Ops
    static FeedComment getfeedCommUpdate(){
        FeedComment fc = getfeedComm();
        fc.CommentBody='This is Updated Com';
        update fc;return fc;
    }
    static FeedComment getfeedCommRich(){
        FeedComment fc = new FeedComment(Feeditemid=getfeeds().id,CommentBody='TestMessage',isrichtext=true);
        insert fc;return fc;
    }
    //Delete Ops
    static FeedComment getfeedCommRichDel(){
        FeedComment fc = getfeedCommRich();
        delete fc;return fc;
    }
    static FeedComment getNestedfeedComm(){
        FeedComment fc = new FeedComment(Feeditemid=getfeeds().id,CommentBody='TestMessage',threadparentid=getfeedComm().id);
        insert fc;return fc;
    }
    
    @isTest
    private static void  slackfeedsupporttest(){
        slackv2__Slack_Message__c a_msg = getTestSlackMsg();
        slackv2__Slack_Message__c a_msg_update = updateTestSlackMsg();
        List<slackv2__Slack_Message__c> listmsg = new list<slackv2__Slack_Message__c>();
        listmsg.add(a_msg);listmsg.add(a_msg_update);
        FeedItem ff = getfeeds();
        List<Feeditem> fs = new List<Feeditem>();
        List<Feedcomment> fst = new List<feedcomment>();
        FeedComment fsa = getfeedComm();
        fst.add(fsa);
        fs.add(ff);
        String token='xoxb-1382250871607-1717661033399-98HgWE7mXbPxp1t3lUzcMaFQ' ;
        String channels='C024X2QF9MW' ;
        Test.startTest();
        try{ 
            Test.setMock(HttpCalloutMock.class, new TestSlackMockOut());//By Pass Callout
            SlackFeedSupport.comment_Create(listmsg); 
            SlackFeedSupport.commentOriginal(fs,'Sent Message','Insert',fst,'legal test');
            SlackFeedSupport.commentOriginal(fs,'Sent Message','Update',fst,'legal test');
            SlackFeedSupport.commentOriginal(fs,'Sent Message','Delete',fst,'legal test');
        }catch(Exception  err){
        }
        Test.stopTest();
    }
    @isTest 
    private static void  slackfeedhandler() {
        list<feeditem> feeditemold = new list<feeditem>();
        list<feeditem> feeditemup = new list<feeditem>();
        list<feeditem> feeditemdel = new list<feeditem>();
        FeedItem oldfeed = getfeeds();
        feeditemold.add(oldfeed);//Old FeedItem List
        FeedItem upfeed = getfeedsup();
        feeditemup.add(upfeed);//Updated FeedItem List
        FeedItem delfeed = getfeedsdel();
        feeditemdel.add(delfeed);//Updated FeedItem List
        try{ 
            Test.setMock(HttpCalloutMock.class, new TestSlackMockOut());//By Pass Callout
            SlackFeedHandler.FeedItemUpdateHandler(feeditemold,feeditemup);
            SlackFeedHandler.FeedItemDeleteHandler(feeditemdel);
        }catch(Exception ex){
            
        }
        
    }
    @isTest 
    private static void  service_call3() {
        list<feedComment> feedCommentList = new list<feedComment>();
        FeedItem ff = getfeeds();
        //FeedComment Update Operation Testing
        FeedComment ffc = getfeedComm();
        FeedComment ffcupdate = getfeedCommUpdate();
        list<feedComment> feedneedupdate = new list<feedComment>();
        feedneedupdate.add(ffc);
        list<feedComment> feedneedupdateother = new list<feedComment>();
        feedneedupdateother.add(ffcupdate);
        //FeedComment Delete Operation Testing
        FeedComment ffcdelone = getfeedCommRich();
        FeedComment ffcdelteo = getfeedCommRichDel();
        list<feedComment> feedneeddelete = new list<feedComment>();
        feedneeddelete.add(ffcdelone);
        list<feedComment> feedneeddeleteother = new list<feedComment>();
        feedneeddeleteother.add(ffcdelteo);
        TopicAssignment tsassign = gettopicAssignment();
        list<TopicAssignment> topicassign = new list<TopicAssignment>();
        topicassign.add(tsassign);
        FeedComment ffc1 = getfeedCommRich();
        feedCommentList.add(ffc1);feedCommentList.add(ffc1);
        
        id userid = '0057F0000010DZOQA2'; 
        Test.startTest();
        try{ 
            Test.setMock(HttpCalloutMock.class, new TestSlackMockOut());//By Pass Callout
            SlackFeedSupport.feedCommentHandle('test123','ts_child','cmtmsg','test107',userid,'testimage1');
            SlackFeedSupport.feedCommentHandle('test123','ts_child','test123','test107',userid,'testimage2');
            SlackFeedHandler.FeedCommentCreator(feedCommentList,'Insert','test');
            SlackFeedHandler.FeedCommentCreator(feedCommentList,'Update','test');
            SlackFeedHandler.FeedCommentCreator(feedCommentList,'Delete','test'); 
            SlackFeedHandler.FeedCommentUpdateHandler(feedneedupdate,feedneedupdateother);
            SlackFeedHandler.FeedCommentDeleteHandler(feedneeddelete);
            SlackFeedHandler.FeedItemTopicsAssignsUpdate(topicassign);
        }
        catch(Exception  err){
        }
        Test.stopTest();
    }
}