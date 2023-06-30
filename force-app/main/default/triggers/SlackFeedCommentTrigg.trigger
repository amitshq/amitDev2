/*
Description-Trigger CRUD on Feedcomment from Salesforce for Slackforce Chain System
Date-27-July-2021
*/
trigger SlackFeedCommentTrigg on FeedComment (before insert,before update,after update,before delete,after delete) {
    //Insert Feedcommment
    if(Trigger.isBefore && (Trigger.isInsert)){
        SlackFeedHandler.FeedCommentCreator(trigger.new,'Insert',null);
    }
    //Update FeedComment
    if(Trigger.isAfter && (Trigger.isUpdate)){
        SlackFeedHandler.FeedCommentUpdateHandler(trigger.new,trigger.old);
    }
    //Delete FeedComment
    if(Trigger.isBefore && (Trigger.isDelete)){
        SlackFeedHandler.FeedCommentDeleteHandler(trigger.old);
    }
}