trigger SlackFeedItemTrigg on FeedItem (after update,before delete,before insert) {
    //Update FeedItem
    if(Trigger.isAfter && (Trigger.isUpdate)){
        SlackFeedHandler.FeedItemUpdateHandler(trigger.new,trigger.old);
    }
    //Delete FeedItem
    if(Trigger.isBefore && (Trigger.isDelete)){
        SlackFeedHandler.FeedItemDeleteHandler(trigger.old);
    }
     //Insert FeedItem
    if(Trigger.isAfter && (Trigger.isInsert)){
        SlackFeedHandler.FeedItemUpdateHandler(null,trigger.new);
    }
}