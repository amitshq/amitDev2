public class chatterSync {
    public static void sync1(){
        list<Id> feedids = new list<id>();
        list<feeditem> lp = [SELECT id,body,commentcount from feeditem where NetworkScope='0DB2w0000004GelGAE'];
        for(feeditem fs:lp){
            feedids.add(fs.id);
        }
        List<ConnectApi.BatchResult> results = ConnectApi.ChatterFeeds.getFeedElementBatch(null, feedids);
        for (ConnectApi.BatchResult result : results) {
          
            ConnectApi.FeedItem item = (ConnectApi.FeedItem) result.getResult();
            System.debug('item logged>>>'+item);
        }        
    }
}