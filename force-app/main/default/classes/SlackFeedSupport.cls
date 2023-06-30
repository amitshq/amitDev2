/*
* Description-Handles the Feeditem and FeedComment CURD Operations
* Date-12-July-2021
*/

public class SlackFeedSupport {
    private static final String ConversationHistory = 'https://slack.com/api/conversations.history';
    private static final String ConversationReply = 'https://slack.com/api/conversations.replies';
    private static final String PostMessage = 'https://slack.com/api/chat.postMessage';
    private static final String PostUpdate = 'https://slack.com/api/chat.update';
    private static final String PostDelete = 'https://slack.com/api/chat.delete';
    private static string usertoken;//User Token key
    private static string bottoken;//Bot Token Key
    private static string channels;//Channels ID
    /*Custom Metadata Config*/
    public static List<SlackCh__mdt> slackconf = SlackCh__mdt.getAll().values();
    /** @description Internal custom exception used by this class for errors*/
    public class ApiException extends Exception {}
    /*HttpRequest Builder*/
    public static HttpRequest BuildRequest(String Endpoint,String Method,String token,String Body){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Endpoint);
        request.setMethod(Method);
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setBody(Body); 
        return request;
    }
    /*Message from Slack Handling Insertion and Updation from Slack Side*/
    public static void comment_Create(list<slackv2__Slack_Message__c> slack_msg){
        String ts_child='';
        String recordid='';
        list<slackv2__Slack_Message__c> slackmsglist;
        for(slackv2__Slack_Message__c ss:slack_msg){
            //Check if the User has FLSAccessible Permissons, if yes then access it
            if(CRUDSafteyCheck.flsAccessible('slackv2__Slack_Message__c','slackv2__Message_Url__c' )&&(CRUDSafteyCheck.flsAccessible('slackv2__Slack_Message__c','slackv2__Content__c' )))
            {
                //Check if the same Message_Url found in SF 
                slackmsglist = [select id,slackv2__Message_Url__c,slackv2__Content__c from slackv2__Slack_Message__c where slackv2__Message_Url__c=:ss.slackv2__Message_Url__c];
            }
           
            //If there is already previous Message, Update the feedcomment
            if(slackmsglist.size()>0){
                System.debug('Update the slack message');
                feedCommentUpdateSlack(slackmsglist,ss.slackv2__Content__c);
            }
            //else create new feedcomment
            else{
                //Get the thread_ts value from Slack Message URL
                ts_child = ss.slackv2__Message_Url__c.split('thread_ts=',2)[1].split('&',2)[0];
                //Insert the New Feedcomment Process
                if(!String.isEmpty(ts_child)){
                    Callout(ts_child,ss.slackv2__Content__c,ss.slackv2__User_Name__c,ss.slackv2__Record_Id__c);
                }     
            } 
        } 
    }
    /*Handle Slack Message Updation*/
    public static void feedCommentUpdateSlack(list<slackv2__Slack_Message__c> slackmsglist,String slackcontent){
        String strippedcontent = slackcontent.stripHtmlTags();
        String getcontent='';
        for(slackv2__Slack_Message__c ss_old:slackmsglist){
            getcontent=ss_old.slackv2__Content__c;//get the old content;
        }
        System.debug('old slack messsage>>'+getcontent);
        list<feedcomment> flps = [select id,commentbody from feedcomment where commentbody=:getcontent];
        System.debug('new slack messsage>>'+flps);
        if(flps.size()>0){
            //Create a list
            list<feedcomment> flpsnew = new list<feedcomment>();
            for(FeedComment fs:flps){ 
                fs.CommentBody=strippedcontent;
                flpsnew.add(fs);
            }
            System.debug('feedcomment update slack>>'+flpsnew);
            //Update the feedcomment and Check CRUDSafety
            CRUDSafteyCheck.doUpdate(flpsnew);
        }
    }
    @future(callout = true)
    public static void Callout(String ts_child,String commentmsg,String username,String recordid) {
        String usertoken;
        String channels;
        for(Integer i = 0; i < slackconf.size(); i++){
            if(slackconf[i].label=='KubsAdminBot'){
                //Slack Info for User API Calls 
                bottoken = slackconf[i].token__c;
                channels = slackconf[i].Channel__c;
            }
        }
        String fileadd;
        String subject='';//holds the feeditem subject
        Http http = new Http();
        ConvoHist responsejson = new ConvoHist();
        String Body ='channel='+channels+'&ts='+ts_child;//Set the Body
        //Build the Request
        HttpRequest getconversation = BuildRequest(ConversationReply,'GET',usertoken,Body);
        //Send the Request
        HttpResponse response = http.send(getconversation); 
        // Since we're doing a GET request, we don't need to handle for 201, other 'created' responses.
        switch on response.getStatusCode() {
            when 200 {
                try {
                    //Parse the Response
                    responsejson = parse(response.getBody());
                    //SlackLogger.add('Success ',SlackLogger.LogSeverity.INFO);
                } catch (System.JSONException jse) {
                    System.debug(LoggingLevel.INFO,'Failed to deserialize the body. Error is: ' + jse.getMessage());
                    throw new SlackFeedSupport.ApiException(jse.getMessage());
                }
            }
            when 404 {
                throw new SlackFeedSupport.ApiException('404 error!');
            }
            when else {
                throw new SlackFeedSupport.ApiException('Unexpected Response code: ' + response.getStatusCode());
            }
        }
        Integer len = responsejson.messages.size()-1;//Size of Response List
        //Compare the Post thread ID with child ID and If Subject Word found,Filter it
        if(responsejson.messages[0].thread_ts==ts_child && responsejson.messages[0].text.contains('Subject:')){
            //Post Title 
            subject =(responsejson.messages[0].text.split('Subject:',2)[1].split('\n',2)[0]).trim();
        }
        for(Integer i=len;i>0;i--){
            //Check if there is any Attachment's in the Comment
            if(responsejson.messages[i].files!=null){
                fileadd+= responsejson.messages[len].files[0].url_private;
            }  
        }
        //Send Subject to match from feeditem and ,linked Attachment for Comment
        feedCommentHandle(subject,ts_child,commentmsg,username,recordid,fileadd);
    }
    public static void feedCommentHandle(String subject,String ts_child,String cmtmsg,String user_name,String recordid,String fileadd){
        String CommentMsg=cmtmsg.stripHtmlTags();
        String search_user= user_name;//Slack Message Username
        ID agentName;
        if(fileadd!=null){
            CommentMsg+='\n'+fileadd;
        }
        //Check similar username whose contactid is not null
        List<User> User_list =[SELECT id,username,contactid,CommunityNickname  FROM User WHERE (username LIKE :search_user OR firstname LIKE : search_user OR lastname LIKE : search_user OR CommunityNickname  LIKE : search_user) AND contactid!=NULL LIMIT 1];
        //Checking user using Username from Slackv2_Message, if the user Matched
        if(User_list.size()>0){
            //set the parentid of username to the searched User from User_list
            agentName = User_list[0].id;
        }
        //If Not Matched,Get the Default SLack User From Custom Label
        else{
            agentName = Label.DefaultSlackUser;    
        }
        List<feedComment> feedCommentList = new list<feedComment>();
        //Match the Subject with the feeditems title
        for(FeedItem ff:[SELECT id,title FROM FeedItem WHERE title =: SUBJECT LIMIT 1]){
            if(ff.id!=null){
                //Creates parent FeedComment with threadParentid=null
                feedCommentCreate(feedCommentList,CommentMsg,ff.id,null,agentName);
            }
        } 
    }
    public static void feedCommentCreate(List<FeedComment> fc,String CommentBody,String feedid,String tparentid,id parentids){
        //Check FLS
        if(Schema.sObjectType.FeedComment.fields.CommentBody.isAccessible() && Schema.sObjectType.FeedComment.fields.threadparentid.isAccessible()){
            FeedComment fedcom = new FeedComment(FeedItemId = feedid, CommentBody = CommentBody,threadparentid = tparentid,CreatedById=parentids);  
            fc.add(fedcom);
        }
        //Check if the list is Null
        if(fc !=null && fc.size()>0){
            //Check CURD Saftey Check
            CRUDSafteyCheck.doInsert(fc);
            
        }   
    }
    /*Handling FeedComment Creation,Updation,Deletion as the Slack Comment Message from Salesforce Community Side*/
    public static void commentOriginal(List<feeditem> feeds, String FinalSent,String context,list<FeedComment> fls,String oldcommentbody){
        //Get the corresponding Feed title of feedcomment
        String feedtitle='';
        for(Feeditem ff:feeds){
            feedtitle=ff.title;
        }         
        //Finally send to callout
        CalloutNew(Finalsent,feedtitle,context,oldcommentbody);
    }
    /*Handling FeedItem Creation,Updation,Deletion as the Slack Post from Salesforce Community Side*/
    public static void PostOriginal(String Finalsent,String feeditemtitlehistory,String FeedContext,boolean istopicupdate){      
        //Finally send to callout
        CalloutNew(Finalsent,feeditemtitlehistory,FeedContext,null);
    }
    public static String CacheStore(String feedtitle){
        String retval='';
        if (Cache.Org.contains('local.SlackCache.feedtitle')) {
            String cachedval = (String)Cache.Org.get('local.SlackCache.feedtitle');
            System.debug('cached val>>'+cachedval);
            if(feedtitle==cachedval.split('>')[0]){
                System.debug('cached val checked>>'+cachedval);
                retval=cachedval.split('>')[1];
            }
            
        }
        return retval;
    }
    @future(callout = true)    
    public static void CalloutNew(String Finalsent,String feedtitle,String context,String oldcommentbody) {
        String usertoken;
        String channels;
        String bottoken;
        for(Integer i = 0; i < slackconf.size(); i++){
            if(slackconf[i].label=='KubsAdminBot'){
                //Slack Info for User API Calls 
                bottoken = slackconf[i].token__c;
                channels = slackconf[i].Channel__c;
            }
            //For comment from Salesforce > Slack, User Token 
            if(slackconf[i].label=='KubsAdminUser'){
                //Slack Info for User API Calls 
                usertoken = slackconf[i].token__c;
            }
           
        }
        //usertoken=bottoken;
        String comment;
        String subject;
        String ts_value_post='';//Feeditem Slackid
        String ts_value_comment='';//FeedComment Slackid
        //check if the feeditem already in the slack side
        //Get the Feedpost ID from slack Conversation.History common for Feeditem and FeedComment
        if(feedtitle!=''){
            /*HttpRequest Builder*/
            Http http = new Http();
            //Build the Request
            String Body = 'channel='+channels;
            //Check in the Cache
            if (Cache.Org.contains('local.SlackCache.feedtitle')) {
                String cachedval = (String)Cache.Org.get('local.SlackCache.feedtitle');
                System.debug('cached val>>'+cachedval);
                if(feedtitle==cachedval.split('>')[0]){
                    System.debug('cached val checked>>'+cachedval);
                    ts_value_post=cachedval.split('>')[1];
                }
            }
            else{
                HttpRequest getconversation = BuildRequest(ConversationHistory,'GET',usertoken,Body);
                //Send the Request
                HttpResponse response = http.send(getconversation); 
                //Traverse the Response
                ConvoHist tt = (ConvoHist)System.JSON.deserialize(response.getBody(), ConvoHist.class);
                System.debug('response convio'+tt);
                for(Integer i=0;i<tt.messages.size();i++){
                    //Case of Nested Comment with the Feeditem Title
                    if(tt.messages[i].text.contains('Subject:')){
                        subject =(tt.messages[i].text.split('Subject:',2)[1].split('\n',2)[0]).trim();
                        if(subject==feedtitle){
                            ts_value_post=tt.messages[i].ts;
                            //Store the feedtitle-ts_value_post , Add cache value to the partition
                            String cont = feedtitle + '>'+ts_value_post;
                            Cache.Org.put('local.SlackCache.feedtitle',cont);//put ts_value 
                        } 
                    }  
                }
            }
        }
        //IF found the FeedPost ID, then find the Feedcomment id IN Conversation.Replies for Update or Delete Operation
        if(ts_value_post!='' && oldcommentbody!=''){
            /*HttpRequest Builder*/
            Http http = new Http();
            String Body ='channel='+channels+'&ts='+ts_value_post;
            //Build the Request
            HttpRequest getconversation = BuildRequest(ConversationReply,'GET',usertoken,Body);
            //Send the Request
            HttpResponse response = http.send(getconversation); 
            System.debug('res>>'+response);
            //Traverse the Response
            ConvoHist tt = (ConvoHist)System.JSON.deserialize(response.getBody(), ConvoHist.class);
            Integer len = tt.messages.size()-1;
            //Compare the Parent thread value to child thread
            for(Integer i=0;i<=len;i++){
                //Case of Comment
                if(tt.messages[i].text.contains('Comment:')){
                    comment =(tt.messages[i].text.split('Comment:',2)[1].split('\n',2)[0]).trim();
                    //System.debug('comment old>>'+comment);
                    if(comment==oldcommentbody){
                        ts_value_comment=tt.messages[i].ts;
                        //System.debug('ts_value_comment>>'+ts_value_comment);
                    }
                }
            }
        }
        //check if the message is Null
        //*Send the comment msg to the post*/
        String Body;
        if(Finalsent != null){
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            String finalInputJSON = '';
            if(Finalsent != null && Finalsent != ''){
                Finalsent = Finalsent.replaceAll('& ', 'And ');
            }
            //Handling CRUD Operations on FeedComment(All takes Bot Token)
            //Delete the Comment/Post takes Bot Token
            if(context=='Delete'){
                //FeedComment Delete
                if(ts_value_comment!=''){
                    Body = 'channel='+channels+'&ts='+ts_value_comment; 
                }
                //FeedItem Delete
                else{
                    Body = 'channel='+channels+'&ts='+ts_value_post;
                }
                req = BuildRequest(PostDelete,'POST',usertoken,Body);
            }
            //Update the Comment/Post takes Bot Token
            if(context=='Update'){
                //FeedComment Update
                if(ts_value_comment!=''){
                    Body = 'channel='+channels+'&text='+Finalsent+'&ts='+ts_value_comment; 
                    req = BuildRequest(PostUpdate,'POST',usertoken,Body);
                }
                //FeedItem Update
                else{
                    Body = 'channel='+channels+'&text='+Finalsent+'&ts='+ts_value_post; 
                    req = BuildRequest(PostUpdate,'POST',bottoken,Body);
                }
                //req = BuildRequest(PostUpdate,'POST',usertoken,Body);
            }
            //Insert the Comment takes Bot Token
            if(context=='Insert'){
                System.debug('Inside Insert');
                //Feedcomment Insert
                if(ts_value_post!=''){
                    Body = 'channel='+channels+'&text='+Finalsent+'&thread_ts='+ts_value_post; 
                    //SlackLogger.publish('FeedCommment Insert');
                    req = BuildRequest(PostMessage,'POST',usertoken,Body);
                    
                }
                //Feeditem Insert
                else{
                    System.debug('Post Insert');
                    Body = 'channel='+channels+'&text='+Finalsent;
                    req = BuildRequest(PostMessage,'POST',bottoken,Body);
                }
                //req = BuildRequest(PostMessage,'POST',usertoken,Body);
                //redirect();
            }
            
            HttpResponse response = http.send(req);
            if (response.getStatusCode() != 200) { 
                System.debug(response.getStatusCode());
            }
        }
    }  
    //Wrapper Class for Deserlization
    public class ConvoHist{
        public cls_messages[] messages;
    }
    public class cls_messages {
        public String text; 
        public String ts; 
        public String thread_ts; 
        public cls_files[] files;
    }
    public class cls_files{
        public String id;
        public string title;
        public string permalink_public;
        public string permalink;
        public string url_private;
    }
    /**
* @description Parses the provided JSON string into instance ofConvoHist Wrapper
* @param json  Incoming JSON string. Often from an api call's results.
* @return     `ConvoList`
* @example
* System.debug(parse(ConvoHist.testJSON));
*/
    public static ConvoHist parse(String json) {
        return (ConvoHist) System.JSON.deserialize(json,ConvoHist.class);
    }
    private String currTime;
    public String getCurrTime()
    {
        return currTime;
    }
    public void setCurrTime()
    {
        currTime = System.now().format('EEEE, MMMM d, yyyy - hh:mm:ss');
    }
    
}