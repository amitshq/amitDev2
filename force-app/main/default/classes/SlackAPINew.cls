//Date-12-July-2021
//Description - This class responsible for sending msg to slack by using slack api methods
global class SlackAPINew { 
    public static boolean isfeedcomm = false;//For Global feedcomment Operations
    public static void postMessage(list<FeedItem> feeds){
        String ts_child;
        String feedcommentcontext='';
        String feeditemcontext='Insert';
        String oldfeeds='';
        //Collection of Feeditem ids
        Set<ID> feedid = new Set<ID>();
        Map<id,list<feedcomment>> mapfeedscomm = new Map<id,list<feedcomment>>();//Not USED HERE
        //List of Networkscope ids
        List<String> Networkscope_list = System.Label.NetworkScopeID_List.split(',');
        //Add Feedids to the Set
        for(FeedItem f:feeds){
            //Check if the NetworkScope is not null and contains in Networkscope list
            if((f.NetworkScope!=null || f.NetworkScope!='') && (Networkscope_list.contains(f.NetworkScope))){
                feedid.add(f.id);
            }
        }
        //check the feeds is emty or not
        if(feedid!=null && (!feedid.isEmpty()))
        {
            //Get Topics Map of Feedid,List<Topics> regarding Feeditem
            Map<ID,list<String>> maptopic  =GetTopics(feedid);
            //User Detail Query with Accountid
            User us = [SELECT id,FirstName,LastName,Email,CompanyName,Title,Account.Name,Accountid FROM User WHERE id=:UserInfo.getUserId() LIMIT 1];
            //CollaborationGroup with Feeds
            Map<Id,String> mapchattergroup = new Map<ID,String>();        
            for(CollaborationGroupMember lscoll:[Select Member.Name,id,member.id, CollaborationGroup.name from CollaborationGroupMember WHERE member.id=:us.id]){
                mapchattergroup.put(lscoll.Id,lscoll.CollaborationGroup.name);
            }
            //call the send msg class
            SlackSendMain(feeds, us, mapchattergroup,maptopic,mapfeedscomm,feedcommentcontext,null,oldfeeds,feeditemcontext,false);  
        }
    }
    //Handle the feeditem update on slack side
    public static void updatefeeditem(list<FeedItem> feeds,string oldfeedtitle,String FeedContext,boolean istopicupdate){
        //feeds- Latest Updated Feeds
        //oldfeedtitle - Old Feed Title
        //feedcontext - Update/Delete FeedItem
        String ts_child;
        String context;
        //Collection of Feeditem ids
        Set<ID> feedid = new Set<ID>();
        Map<id,list<feedcomment>> mapfeedscomm = new Map<id,list<feedcomment>>();//Not USED HERE
        //List of Networkscope ids
        List<String> Networkscope_list = System.Label.NetworkScopeID_List.split(',');
        //Add Feedids to the Set
        for(FeedItem f:feeds){
            //Check if the NetworkScope is not null and contains in Networkscope list
            if((f.NetworkScope!=null || f.NetworkScope!='') && (Networkscope_list.contains(f.NetworkScope))){
                feedid.add(f.id);
            }
        }
        //check the feeds is emty or not
        if(feedid!=null && (!feedid.isEmpty()))
        {
            //Get Topics Map of Feedid,List<Topics> regarding Feeditem
            Map<ID,list<String>> maptopic  =GetTopics(feedid);
            //User Detail Query with Accountid
            User us = [SELECT id,FirstName,LastName,Email,CompanyName,Title,Account.Name,Accountid FROM User WHERE id=:UserInfo.getUserId() LIMIT 1];
            //CollaborationGroup with Feeds
            Map<Id,String> mapchattergroup = new Map<ID,String>();        
            for(CollaborationGroupMember lscoll:[Select Member.Name,id,member.id, CollaborationGroup.name from CollaborationGroupMember WHERE member.id=:us.id]){
                mapchattergroup.put(lscoll.Id,lscoll.CollaborationGroup.name);
            }
            //call the send msg class
            SlackSendMain(feeds, us, mapchattergroup,maptopic,mapfeedscomm,context,null,oldfeedtitle,FeedContext,istopicupdate);  
        }
    }
    //Topic Assignemnt Method return map of feedid and list of topics
    public static map<id,list<String>> GetTopics(Set<id> feedid){
        //Map of TopicAssignemnt with Feeds
        Map<ID,list<String>> maptopic = new map<id,list<String>>();
        for(TopicAssignment ls:[SELECT EntityId, Topic.Name FROM TopicAssignment WHERE Entityid IN: feedid] ){
            //Check if the Entityid is present in the map
            if(maptopic.containsKey(ls.EntityId)){
                //Get the list of existing Topics names
                list<String> tops = maptopic.get(ls.EntityId);
                //Add the topic names
                tops.add(ls.Topic.name);
                maptopic.put(ls.EntityId,tops);
            }
            else{
                //Make a new list and the topic names
                maptopic.put(ls.EntityId,new list<String> {ls.topic.name});
            }
        }
        System.debug('Topics >>>'+maptopic);
        //return map to main method
        return maptopic;
    }
    //Called by SlackAPIExt Trigger Handles the FeedComment corresponding to Feeditem
    public static void postcomment(Map<id,list<feedcomment>> mapfeedscomm,String context,String ts_child){
        isfeedcomm=true;
        //Collection of Feeditem ids
        Set<ID> feedid = new Set<ID>();
        for(ID f:mapfeedscomm.keySet()){
            feedid.add(f);
        }
        //List of Networkscope ids
        List<String> Networkscope_list = System.Label.NetworkScopeID_List.split(',');
        //FeedItem List from Map
        List<FeedItem> feeds = new List<Feeditem>();
        List<Feeditem> feedcopy= [SELECT id,title,Parentid,body,NetworkScope,type from feeditem WHERE id in:mapfeedscomm.keySet()];
        for(FeedItem ff:feedcopy){
            //Check if the NetworkScope is null or not for the comment and present in Networkscopeid list
            if((ff.NetworkScope!=null || ff.NetworkScope!='') && (Networkscope_list.contains(ff.NetworkScope)) && ff.Type=='QuestionPost'){
                feeds.add(ff);
            }
        }
        //Check if the feeditem is empty corresponding to Networkscope
        if(feeds!=null && !feeds.isempty())
        {
            //User Detail Query with Accountid
            User us = [SELECT id,FirstName,LastName,Email,CompanyName,Title,Account.Name,Accountid,contactid from User WHERE id=:UserInfo.getUserId() limit 1];
            //CollaborationGroup with Feeds
            Map<Id,String> mapchattergroup = new Map<ID,String>();        
            for(CollaborationGroupMember lscoll:[SELECT Member.Name,id,member.id, CollaborationGroup.name from CollaborationGroupMember WHERE member.id=:us.id]){
                mapchattergroup.put(lscoll.Id,lscoll.CollaborationGroup.name);
            }
            //Get Topics Map of Feedid,List<Topics> regarding Feeditem
            Map<ID,list<String>> maptopic  =GetTopics(feedid);
            
            //Call slack Comment Handler
            SlackSendMain(feeds,us,mapchattergroup,maptopic,mapfeedscomm,context,ts_child,null,null,false);
            
        }
    } 
    //Handles the Slack Post Message Call
    public static void SlackSendMain(List<feeditem> feeds, User us, Map<Id,String> mapchattergroup,Map<ID,list<String>> maptopic,Map<id,list<feedcomment>> mapfeedscomm,String context,String ts_child,String feeditemold,String FeedContext,boolean istopicupdate){
        String Finalsent='';
        list<feedcomment> fedcom = new list<feedcomment>();
        //Loop FeedItems
        for(FeedItem fed:feeds){
            Map<Id,ContentDistribution> cd1 = new Map<Id,ContentDistribution>();
            Map<Id,ContentDistribution> cd2 = new Map<Id,ContentDistribution>();
            //Set of ContentDocument Ids
            set<String> Contentdoc = new set<String>();
            SET<String> Contentdocumentid1=new SET<String>();
            SET<String> Contentdocumentid2=new SET<String>();
            //Loop through Message
            slackv2.invokePostMessage.PostMessageRequest rp = NEW slackv2.invokePostMessage.PostMessageRequest();
            //UserInfo id
            rp.recordId=us.id;
            //Check if its Question or Answer
            //If the Post is Comment
            if(!mapfeedscomm.isEmpty())
            {
                //check if the Title is not null   
                if(fed.Title!=''){
                    //Question Post Subject
                    rp.message= '*Re: * ' +'<'+Label.SlackCommunityLink + fed.id+'|'+fed.Title+'>'+ '\n'; 
                }
            }
            else{
                //Delimeter
                rp.message='';
            }
            //User Messages 
            if(us.FirstName!='' && us.LastName!=''){
                rp.message+= '*Name*: ' + us.FirstName+' '+us.LastName+ '\n';
            }
            if(us.Email!=''){
                rp.message+= '*Email*: ' +us.Email+ '\n'; 
            }
            String accname = '';
            if(us.AccountId!=null){
                //Display Account Name Corresponding to the User
                String accountURL = URL.getOrgDomainUrl().toExternalForm() + '/' + us.accountid;//Create Account URL
                //CompanyName is Null
                if(us.CompanyName==''|| us.CompanyName==null){  
                    accname = '*Company*: '+'<'+accountURL +'|'+us.Account.Name+'>'+ '\n';
                }
                //CompanyName is not Null
                if(us.CompanyName!='' && us.CompanyName!=null){
                    accname = '*Company*: '+'<'+accountURL +'|'+us.CompanyName+'>'+ '\n';
                }   
                rp.message+=accname;
            }else if(us.AccountId == null){
                if(us.CompanyName!='' && us.CompanyName!=null){
                    accname = '*Company*: '+us.CompanyName+ '\n';
                }   
                rp.message+=accname;
            }
            
            //Check the title
            if(us.Title!=null && us.Title!=''){
                rp.message+= '*Title*: ' +us.Title+ '\n';  
            } 
            //Chatter Group Name 
            if(!mapchattergroup.isEmpty()){
                String groupname='*Group Name*: ';
                for(ID fedid:mapchattergroup.keySet()){
                    String gname=mapchattergroup.get(fedid);
                    groupname+=gname + ',';  
                }
                rp.message += groupname.removeEnd(',');
                //Post Messages
                rp.message+='\n';
            }
            rp.message+='\n';
            //If the Post is Question
            if(mapfeedscomm.isEmpty()){
                //check if the Title is not null
                if(fed.Title!=''){
                    rp.message+= 'Subject: ' + fed.Title+ '\n';
                } 
            }
            
            //Check if the Message is Post or Comment
            //Post Message
            if(mapfeedscomm.isEmpty())
            { 
                //check for the Empty Description Body
                if(fed.Body == null || fed.body==''){
                    //Body is Totally Null
                }
                //Post Attachments
                else{
                    //Check if there is a null Description Image  
                    if(fed.Body != null && fed.Body.StripHtmlTags()!=''){
                        rp.message+= 'Description: ' +fed.Body.StripHtmlTags()+ '\n';
                    }
                    //Create list of Content Document URLS for Posts
                    if(fed.Body != null){
                        //Call the method
                        String fedbody=fed.Body;
                        //Get set of ids from getContentDocumentID method
                        //In Case of File Attachments
                        if(fed.relatedrecordid!=null){
                            //Files
                            Contentdocumentid2.add(fed.relatedrecordid);   
                        }
                        Contentdocumentid1 = getContentDocumentID(fedbody);
                        //Distribution URL Creation Ahead
                    }
                }
            }
            //Runs for FeedComment
            else{
                //Note-Blank Comment is not allowd
                String mes='';
                String urlbody='';
                //Create list of Content Document URLS for Posts
                for(Id ll:mapfeedscomm.keySet()){
                    for(Feedcomment top:mapfeedscomm.get(ll)){
                        fedcom.add(top);//Added feedcomment to pass to slackfeedsupport
                        mes+=top.commentbody;
                        //Check if the comment is not null
                        if(mes!=''){
                            rp.message+='Comment: '+mes.stripHtmlTags()+'\n';   
                        }
                        //In Case of File Attachments
                        if(top.relatedrecordid!=null || top.RelatedRecordId!=''){
                            //Files
                            Contentdocumentid2.add(top.relatedrecordid);   
                        }
                        //Images
                        Contentdocumentid1 = getContentDocumentID(top.commentbody);      
                        
                    }
                }              
            }
            //Show the Topic 
            if(!maptopic.isEmpty()){
                rp.message += ShowTopics(maptopic);
                rp.message+='\n';
            }
            //Images only single selection allowed
            if(!Contentdocumentid1.isEmpty())
            {   
                //Pass the Contentid strings to the method
                List<ContentDistribution> cdList=ContentLinkURLCreater(Contentdocumentid1,cd1);
                //Check the List 
                if(cdList!=null && !cdList.isEmpty())
                {
                    //Attach the titles of Attachments Images
                    rp.message+=ShowAttachments(cdList);
                }
            }
            
            //Files or multiple files
            if(!Contentdocumentid2.isEmpty())
            {   
                //Pass the Contentid strings to the method
                List<ContentDistribution> cdList1=ContentNewOne(Contentdocumentid2,cd2); 
                //Check the List 
                if(cdList1!=null && !cdList1.isEmpty())
                {
                    //Attach the titles of Attachments Files
                    rp.message+=ShowAttachments(cdList1);
                }
                
            }
            Finalsent=rp.message;
            //If there is Commmnet
            if(isfeedcomm){
                SlackFeedSupport.commentOriginal(feeds,Finalsent,context,fedcom,ts_child); 
            }
            //else there is Post
            
            else{
                SlackFeedSupport.PostOriginal(Finalsent,feeditemold,FeedContext,istopicupdate);
            }
            
        }
    }
    
    //Content Delivery Ids Extract from FeedBody
    public static Set<String> getContentDocumentID(String FedBody){
        //Common for both Post and Comment Section
        Set<String> Contentdocumentid1 = new set<String>();
        String sp1=''; String sp2='';
        String body1 = FedBody;
        body1=body1.replace('<p>','');
        List<String> ssp = body1.split('<img src="sfdc:/');
        for(String top1:ssp){
            sp1=top1.substringAfter('/');
            sp2=sp1.substringBefore('"');
            
            if(sp2!=''){
                Contentdocumentid1.add(sp2);
            }
        }
        //Return the list of ContentDocumentids to main method
        return Contentdocumentid1;
    }
    //Content Delivery Links Method return List of URL
    public static List<ContentDistribution> ContentLinkURLCreater(Set<String> ContentDocID, Map<Id,ContentDistribution> cds1){
        List<ContentVersion> cid = [select id,title,Contentdocumentid,PathOnClient from ContentVersion where Contentdocumentid in : ContentDocID];
        for(ContentVersion cs:cid){
            ContentDistribution each = new ContentDistribution();
            each.ContentVersionId = cs.id;
            each.Name = cs.title;
            each.PreferencesNotifyOnVisit = false;
            each.PreferencesAllowViewInBrowser = true;
            each.PreferencesAllowOriginalDownload=true;
            if(!cds1.containsKey(cs.Id))
                cds1.put(cs.Id,each);
        }
        if(!cds1.isEmpty()){
            CRUDSafteyCheck.doUpsert(cds1.values());
            //upsert cds1.values();
        }
        List<ContentDistribution> cdList = [SELECT Name,DistributionPublicUrl,ContentDownloadUrl  FROM ContentDistribution WHERE id in:cds1.values()];
        return cdList;
    }
    //Content Delivery Links Method return List of URL
    public static List<ContentDistribution> ContentNewOne(Set<String> Contentdocumentid2, Map<Id,ContentDistribution> cd1){
        List<ContentVersion> cid = [select id,title,Contentdocumentid,PathOnClient from ContentVersion where id in : Contentdocumentid2];
        for(ContentVersion cs:cid){
            ContentDistribution each = new ContentDistribution();
            each.ContentVersionId = cs.id;
            each.Name = cs.title;
            each.PreferencesNotifyOnVisit = false;
            each.PreferencesAllowViewInBrowser = true;
            each.PreferencesAllowOriginalDownload=true;
            if(!cd1.containsKey(cs.Id))
                cd1.put(cs.Id,each);
        }
            if(!cd1.isEmpty()){
                CRUDSafteyCheck.doUpsert(cd1.values());
            	//upsert cd1.values();
        }
        
        List<ContentDistribution> cdList = [SELECT Name,DistributionPublicUrl,ContentDownloadUrl  FROM ContentDistribution WHERE id in :cd1.values()];
        return cdList;
    }
    public static String ShowTopics(Map<ID,list<String>> maptopic){
        String topics_lineup = '';
        topics_lineup += 'Topic: ';
        String mestop = '';
        //Iterate Map of list to get Topic Names
        for(Id ll:maptopic.keySet()){
            for(String top:maptopic.get(ll)){
                mestop+=top+', ';  
            }
        }  
        topics_lineup += mestop.removeEnd(', ');
        topics_lineup+='\n';
        return topics_lineup;
    }
    public static String ShowAttachments(List<ContentDistribution> cdList){
        String attachmentsfiles='';
        if(cdList!=null){
            System.debug('cdlist method>>'+cdList);
            //Image Attachment Rese
            attachmentsfiles+='Attachments: ';
            String AttachmentLinks='';
            for(ContentDistribution c1:cdList){
                AttachmentLinks+='<'+c1.DistributionPublicUrl+'|'+c1.Name+'>'+', ';
            }
            attachmentsfiles+=AttachmentLinks.removeEnd(', ');
            attachmentsfiles+='\n';   
        }
        
        
        return attachmentsfiles;
    }
}