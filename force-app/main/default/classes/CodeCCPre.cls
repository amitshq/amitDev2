public class CodeCCPre {
    //This method will return a Map of Classes Names and the respective Code Coverage
    @AuraEnabled
    public static Map<String, Decimal> getCodeCoverage() {
        Map<String, Decimal> resultMap = new Map<String, Decimal>();
        string queryStr = 'SELECT+NumLinesCovered,ApexClassOrTriggerId,ApexClassOrTrigger.Name,NumLinesUncovered,Coverage+FROM+ApexCodeCoverageAggregate+ORDER+BY+ApexClassOrTrigger.Name';
        String ENDPOINT = 'https://grazittidev3-dev-ed.my.salesforce.com' +   '/services/data/v40.0/tooling/';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT + 'query/?q=' + queryStr);
        //req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
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
        String getorgpercent='';
        string queryStr = 'SELECT PercentCovered FROM ApexOrgWideCoverage';
        String ENDPOINT = 'https://grazittidev3-dev-ed.my.salesforce.com' +   '/services/data/v40.0/tooling/';
        //String ENDPOINT =  callout:RenonceCall+'/services/data/v40.0/tooling/';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT + 'query/?q=' + queryStr);
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req); 
        System.debug(res);
        //getorgpercent=res;
        return getorgpercent;
    }
    
    @AuraEnabled
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
    @AuraEnabled
    public static String buildCodeCoverageMessage(Decimal coverage, String objectName) {
        String coverageMessage = ''; 
        
        if(coverage < 10) {coverageMessage = coverageMessage + ICON_ERROR + ' ' + MESSAGE_UNDER_10 +  ' threshold';}
        if(coverage >= 10 && coverage < 75) {coverageMessage = coverageMessage + ICON_WARNING + ' ' + MESSAGE_UNDER_75 + ' threshold';}
        if(coverage >= 75) {coverageMessage = coverageMessage + ICON_OK + ' ' + MESSAGE_ABOVE_75 + ' threshold';}
        
        coverageMessage = coverageMessage + ' | Code Coverage for [ ' + objectName + ' ]: ' + coverage + '%'; 
        return coverageMessage;
    }
    public static final String ICON_ERROR   = '⛔';
    public static final String ICON_WARNING = '️⚠️';
    public static final String ICON_OK      = '✅';
    
    public static final String MESSAGE_UNDER_10 = 'Under the 10%';
    public static final String MESSAGE_UNDER_75 = 'Under the 75%';
    public static final String MESSAGE_ABOVE_75 = 'Above the 75%';
    // Enqueue all classes ending in "Test". 
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
    // Get the status and pass rate for each class
    // whose tests were run by the job.
    // that correspond to the specified job ID.
    public static void checkClassStatus(ID jobId) {
        ApexTestQueueItem[] items = 
            [SELECT ApexClass.Name, Status, ExtendedStatus 
             FROM ApexTestQueueItem 
             WHERE ParentJobId=:jobId];
        for (ApexTestQueueItem item : items) {
            String extStatus = item.extendedstatus == null ? '' : item.extendedStatus;
            System.debug(item.ApexClass.Name + ': ' + item.Status + extStatus);
        }
    }
    // Get the result for each test method that was executed.
    public static void checkMethodStatus(ID jobId) {
        ApexTestResult[] results = 
            [SELECT Outcome, ApexClass.Name, MethodName, Message, StackTrace 
             FROM ApexTestResult 
             WHERE AsyncApexJobId=:jobId];
        for (ApexTestResult atr : results) {
            System.debug(atr.ApexClass.Name + '.' + atr.MethodName + ': ' + atr.Outcome);
            if (atr.message != null) {
                System.debug(atr.Message + '\n at ' + atr.StackTrace);
            }
        }
    }
    //Comparable Helper for Code Covergae Paramters
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