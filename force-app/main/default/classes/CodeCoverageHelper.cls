public class CodeCoverageHelper {
    
    //This method will return a Map of Classes Names and the respective Code Coverage
    public static Map<String, Decimal> getCodeCoverage() {
        Map<String, Decimal> resultMap = new Map<String, Decimal>();
        
        string queryStr = 'SELECT+NumLinesCovered,ApexClassOrTriggerId,ApexClassOrTrigger.Name,NumLinesUncovered,Coverage+FROM+ApexCodeCoverageAggregate+ORDER+BY+ApexClassOrTrigger.Name';
        
        String ENDPOINT = 'https://' + System.URL.getSalesforceBaseUrl().getHost() + '/services/data/v40.0/tooling/';
        
        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(ENDPOINT + 'query/?q=' + queryStr);
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('GET');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            CodeCoverageWrapper codeCoverageWrapper = CodeCoverageWrapper.parse(res.getBody());
            
            for(CodeCoverageWrapper.Records records : codeCoverageWrapper.records) {
                
                String classOrTriggerName  = records.ApexClassOrTrigger.Name;
                Decimal numLinesCovered    = records.NumLinesCovered;
                Decimal numLinesUncovered  = records.NumLinesUncovered;
                Decimal totalNumberOfLines = numLinesCovered + numLinesUncovered;
                
                if(totalNumberOfLines == 0) continue;
                
                Decimal coveragePercentage = (numLinesCovered / totalNumberOfLines) * 100;
                
                resultMap.put(classOrTriggerName, coveragePercentage);
            }
        }
        System.debug(resultMap);
        return resultMap;
    }
    @AuraEnabled
    public static String getOrgCode(){
        String getorgpercent='10';
        string queryStr = 'SELECT+PercentCovered+FROM+ApexOrgWideCoverage';
        String ENDPOINT = 'https://' + System.URL.getSalesforceBaseUrl().getHost() + '/services/data/v40.0/tooling/';
        //String ENDPOINT =  callout:RenonceCall+'/services/data/v40.0/tooling/';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT + 'query/?q=' + queryStr);
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req); 
        System.debug(res.getBody());
        //PercentCovered
        String cc = (res.getBody().split('PercentCovered')[1]);
        //getorgpercent=res;
        return cc ;
    }
    
    public static void runChunkedTests(Integer totalChunks, Integer chunkNumber){
        
        List<ApexTestQueueItem> testQueueItems = new List<ApexTestQueueItem>();
        String countQuery = 'SELECT count() FROM ApexClass WHERE NamespacePrefix = null AND Name like \'%Test%\'';
        Integer totalClasses = Database.countQuery(countQuery);
        Decimal chunkSizeDec = (totalClasses / Decimal.valueOf(totalChunks));
        Integer chunkSize = Integer.valueOf(chunkSizeDec.round(System.RoundingMode.CEILING));
        Integer offset = chunkSize * (chunkNumber - 1);
        
        List<ApexClass> unitTestClasses = [
            SELECT Id, Name 
            FROM ApexClass
            WHERE NamespacePrefix = null
            AND Name like '%Test%'
            ORDER BY NAME
            LIMIT : chunkSize
            OFFSET : offset
        ];
        
        for(ApexClass unitTestClass : unitTestClasses){
            
            testQueueItems.add(new ApexTestQueueItem(ApexClassId = unitTestClass.Id));
        }
        
        insert testQueueItems;
    }
    
    
    // Method created to sort the Map of Coverage values in Descending Order
    public static Map<String, Decimal> sortCodeCoverageMapByCoverage(Map<String, Decimal> coverageMap) {
        CoverageWrapper[] coverageList = new CoverageWrapper[]{};
            
            for(String key : coverageMap.keySet()) {
                coverageList.add(new CoverageWrapper(key, coverageMap.get(key)));
            }
        
        coverageList.sort();
        
        CoverageWrapper[] finalList = new CoverageWrapper[]{};
            
            for(Integer i = coverageList.size() -1; i >= 0; i = i-1 ) {
                finalList.add(coverageList.get(i));
            }
        
        Map<String,Decimal> coverageToNameMap = new Map<String,Decimal>();
        
        for(CoverageWrapper coverage : finalList) {
            coverageToNameMap.put(coverage.getObjectName(), coverage.getValue());
        }
        
        return coverageToNameMap;
    }
    
    public static String buildCodeCoverageMessage(Decimal coverage, String objectName) {
        String coverageMessage = ''; 
        
        if(coverage < 10) {
            coverageMessage += ICON_ERROR + ' ' + MESSAGE_UNDER_10 +  ' threshold';
        }
        
        if(coverage >= 10 && coverage < 75) {
            coverageMessage += ICON_WARNING + ' ' + MESSAGE_UNDER_75 + ' threshold';
        }
        
        if(coverage >= 75) {
            coverageMessage += ICON_OK + ' ' + MESSAGE_ABOVE_75 + ' threshold';
        }
        
        coverageMessage += ' | Code Coverage for [ ' + objectName + ' ]: ' + coverage + '%'; 
        
        return coverageMessage;
    }
    
    public static String buildTableCovergae(Decimal coverage, String objectName){
        String coverageMessage = ''; 
        
        if(coverage < 10) {
            coverageMessage = coverageMessage + ICON_ERROR + ' ' + MESSAGE_UNDER_10 ;
        }
        
        if(coverage >= 10 && coverage < 75) {
            coverageMessage = coverageMessage + ICON_WARNING + ' ' + MESSAGE_UNDER_75;
        }
        
        if(coverage >= 75) {
            coverageMessage = coverageMessage + ICON_OK + ' ' + MESSAGE_ABOVE_75;
        }
        
        coverageMessage = coverageMessage + ' | Code Coverage for [ ' + objectName + ' ]: ' + coverage + '%'; 
        
        return coverageMessage;
    }
    public static ID enqueueTests() {
        ApexClass[] testClasses = 
            [SELECT Id FROM ApexClass 
             WHERE Name LIKE '%Test'];
        if (testClasses.size() > 0) {
            ApexTestQueueItem[] queueItems = new List<ApexTestQueueItem>();
            for (ApexClass cls : testClasses) {
                queueItems.add(new ApexTestQueueItem(ApexClassId=cls.Id));
            }
            
            insert queueItems;
            
            // Get the job ID of the first queue item returned.
            ApexTestQueueItem item = 
                [SELECT ParentJobId FROM ApexTestQueueItem 
                 WHERE Id=:queueItems[0].Id LIMIT 1];
            return item.parentjobid;
        }
        return null;
    }
    public static final String ICON_ERROR   = '⛔';
    public static final String ICON_WARNING = '️⚠️';
    public static final String ICON_OK      = '✅';
    
    public static final String MESSAGE_UNDER_10 = 'Under the 10%';
    public static final String MESSAGE_UNDER_75 = 'Under the 75%';
    public static final String MESSAGE_ABOVE_75 = 'Above the 75%';
    
    public class CoverageWrapper implements Comparable {
        private Decimal coverageValue{get; set;}
        private String objectName    {get; set;}
        private Integer intValue     {get; set;}
        
        CoverageWrapper(String objectName, Decimal coverageValue) {
            this.objectName = objectName;
            this.coverageValue = coverageValue;
            this.intValue = coverageValue.intValue();
        }
        
        public Decimal getValue() {
            return this.coverageValue;
        }
        
        public String getObjectName() {
            return this.objectName;
        }
        
        public Integer compareTo(Object other) {
            return intValue-((CoverageWrapper)other).intValue;
        }
    }
}