trigger SlackTopicAssign on TopicAssignment (before update,after insert) {
	//Handles the feeditem Insertion also
    if(Trigger.isAfter && (Trigger.isInsert)){
        SlackFeedHandler.FeedItemTopicsAssignsUpdate(trigger.new);
    }
}