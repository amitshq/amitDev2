/*
* Description-Handles the comment from Salesforce to FeedComment
* Date-13-July-2021
*/
public class SlackFeedHandler {
    public static void FeedCommentCreator(list<feedComment> feedcom,String context,String oldfeedcomment){
        /*FeedComment from Salesforce Side
mapfeedcomments-Stores Feeditemid,List of FeedComment of that id*/
        Map<id,list<feedcomment>> mapfeedcomments = new Map<id,list<feedcomment>>();
        for(FeedComment lsfeeds:feedcom){
            //Check if the Rich text CommentBody(isRichText) is true
            if(lsfeeds.IsRichText==true ){
                if(mapfeedcomments.containsKey(lsfeeds.FeedItemId)){
                    //Get the list of existing Comment
                    list<feedcomment> Comtops = mapfeedcomments.get(lsfeeds.FeedItemId);
                    mapfeedcomments.put(lsfeeds.FeedItemId,Comtops);
                }
                else{
                    //Make a new list and the comments
                    mapfeedcomments.put(lsfeeds.FeedItemId,new list<feedcomment> {lsfeeds});   
                }
            }
        }
        //context variable check
        if(!String.isBlank(context)){
            //mapfeedcomment check
            if(!mapfeedcomments.isEmpty()){
                //Calling the SlackAPINew class and pass the map object
                SlackAPINew.postcomment(mapfeedcomments,context,oldfeedcomment);
                
            }     
        }
        
    }
    //FeedComment Update
    public static void FeedCommentUpdateHandler(list<feedComment> newfc,list<feedComment> oldfc){
        String OldComment;
        for(feedcomment fsp:oldfc){
            OldComment=fsp.commentbody.stripHtmlTags();//Remove HTML Tags
        }
        //Check oldcomment is Blank
        if(!String.isBlank(OldComment)){
            FeedCommentCreator(newfc,'Update',OldComment);
        }
    }
    //FeedComment Delete
    public static void FeedCommentDeleteHandler(list<feedComment> oldfc){
        String OldComment='';
        for(feedcomment fsp:oldfc){
            OldComment=fsp.commentbody.stripHtmlTags();
        }
        //Check oldcomment is Blank
        if(!String.isBlank(OldComment)){
            FeedCommentCreator(oldfc,'Delete',OldComment);
        }
    }
    
    //FeedItem Update
    public static void FeedItemUpdateHandler(list<FeedItem> newf,list<FeedItem> oldf){
        String OldTitle='';
        for(feeditem fsp:oldf){
            OldTitle=fsp.title;//feeditem title
        }
        //Check oldtitle is Blank
        if(!String.isBlank(OldTitle)){
            SlackAPINew.updatefeeditem(newf,OldTitle,'Update',false);
        }
    }
    //Feeditem Delete
    public static void FeedItemDeleteHandler(list<FeedItem> old){
        String OldTitle='';
        for(feeditem fsp:old){
            OldTitle=fsp.title;//feeditem title
        }
        //Check oldtitle is Blank
        if(!String.isBlank(OldTitle)){
            SlackAPINew.updatefeeditem(old,OldTitle,'Delete',false);
        }
    }
    
    //TopicAssignment Update
    public static void FeedItemTopicsAssignsUpdate(list<TopicAssignment> newtopic){
        String OldTitle='';
        Integer Revisioncount;
        boolean isfeedinsert=false;
        boolean istopicupdated=false;
        list<Feeditem> newfeedslist = new list<FeedItem>();
        Set<Id> feedslist = new Set<Id>();
        //Get the topic assignemnt details
        for(TopicAssignment ts:newtopic){
            feedslist.add(ts.entityid);//feeditem id
        }
        list<TopicAssignment> rectopicassign = [SELECT id,topicid,entityid FROM TopicAssignment WHERE entityid in:feedslist];//3
        if(rectopicassign.size()>1){
            istopicupdated=true;
        }
        //Check if the Entityid/Feeditem id already present in the topicassignemnt
        for(Feeditem fls:[SELECT id,Networkscope,Body,title,Type,parentid,relatedrecordid,Revision FROM Feeditem WHERE id in: feedslist]){
            newfeedslist.add(fls);
            Revisioncount=fls.Revision;
            OldTitle=fls.Title;
        }
        if(Revisioncount==1){
            isfeedinsert=true;
        }
        //If Revison is 1,and also there is no topic added then its first post
        if(isfeedinsert && !istopicupdated){
            SlackAPINew.postMessage(newfeedslist); 
        }
        //Else its Updated post
        else{
            SlackAPINew.updatefeeditem(newfeedslist,OldTitle,'Update',true);   
        }         
    }
}