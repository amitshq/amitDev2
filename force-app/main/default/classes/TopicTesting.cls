public class TopicTesting {
    
    public static ConnectAPI.ManagedTopicCollection getNavigationTopics(){
        Community  csid = [select id from Community];
        ID Community = '0DB2w0000004GelGAE';
        return ConnectAPI.ManagedTopics.getManagedTopics(Community, 
                                                         ConnectApi.ManagedTopicType.Navigational);
    } 
}