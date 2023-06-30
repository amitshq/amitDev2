//Manipulation on the FeedItem and FeedComment
trigger CSOD_chat_bridge_trigger on CSOD_Chat_Bridge__c (after insert,after update, after delete) {
    //Insert
    if(Trigger.isAfter && Trigger.isInsert){
        //Insertion
        for(CSOD_Chat_Bridge__c ch:Trigger.new){
            if(ch.slackUser__c !=null){
                //Check the Slack Username with Salesforce UserId
                User us=[select id,name,username from user where name=:ch.slackUser__c or username=:ch.slackUser__c limit 1];
                //FeedItem Insert
                if(us!=null && ch.slack_Feedpost__c !=null){
                    //Insert FeedPost
                    FeedItem f = new FeedItem();
                    f.ParentId = us.id;//UserId
                    f.body = ch.slack_Feedpost__c;
                    try{
                        insert f; 
                        //Store the FeeditemId back to the CSOD_Chat_Bridge__c[feeditemId_CSOD] 
                        if(f!=null){
                            CSOD_Chat_Bridge__c cs = [select id,feeditemId_CSOD__c from CSOD_Chat_Bridge__c where id=:ch.id limit 1];
                            cs.feeditemId_CSOD__c =f.id;
                            update cs;
                        }
                        
                    }
                    catch(Exception ex){
                        System.debug(ex.getCause());
                    }                        
                }
                //FeedComment Insert
                if(us!=null && ch.slack_FeedComment__c  !=null && ch.parentTS__c !=null){
                    //Get CSOD FeedItem
                    CSOD_Chat_Bridge__c cs = [select id,ts__c ,slack_Feedpost__c,parentTS__c,feeditemId_CSOD__c from CSOD_Chat_Bridge__c where ts__c=: ch.parentTS__c limit 1 ];
                    if(cs!=null){
                        //Insert FeedComment
                        FeedComment f = new FeedComment();
                        f.feeditemid = cs.feeditemId_CSOD__c;//feedpost id
                        f.commentBody = ch.slack_FeedComment__c ;
                        try{
                            insert f;  
                            //Store the FeedCommentId back to the CSOD_Chat_Bridge__c[feedCommentId_CSOD] 
                            if(f!=null){
                                CSOD_Chat_Bridge__c csd = [select id,feedCommentId_CSOD__c  from CSOD_Chat_Bridge__c where id=:ch.id limit 1];
                                csd.feedCommentId_CSOD__c  =f.id;
                                update csd;
                            }
                        }
                        catch(Exception ex){
                            System.debug(ex.getCause());
                        }     
                        
                    }
                    
                    
                }
                
                
                
            }
        }
    }
    //Update or Delete
    if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isDelete)){
        list<CSOD_Chat_Bridge__c> csod_list =new list<CSOD_Chat_Bridge__c>();
        if(Trigger.isUpdate){
             csod_list = Trigger.new;
        }
        else{
             csod_list = Trigger.old;
        }
        
        for(CSOD_Chat_Bridge__c cu:csod_list){
            System.debug(cu);
            //For feedcomments
            if(cu.slack_FeedComment__c!=null){
                //find feedcomment
                Feedcomment fd = [select id,commentbody from feedcomment where id=:cu.feedCommentId_CSOD__c  limit 1];
                if(fd!=null){
                    fd.commentbody=cu.slack_FeedComment__c;
                    update fd;
                }
            }
            //For feedpost
            if(cu.slack_Feedpost__c !=null){
                //find feedcomment
                Feeditem fi = [select id,body from Feeditem where id=:cu.feeditemId_CSOD__c  limit 1];
                if(fi!=null){
                    fi.body=cu.slack_Feedpost__c;
                    update fi;
                }
            }
        }
    }
}