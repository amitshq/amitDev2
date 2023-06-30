/*
  Description-Trigger to add feedcomment from Slack
  Date-27-July-2021
*/
trigger SlackMessageTrigg on slackv2__Slack_Message__c (before insert) {
  //Check if the comment is a thread or not 
    if(Trigger.isAfter && (Trigger.isInsert)){
        SlackFeedSupport.comment_Create(Trigger.new);
    }
}