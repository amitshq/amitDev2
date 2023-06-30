public class CodeStore {
@AuraEnabled
    public static Map<String, Decimal>  call1(){
        Map<String, Decimal> resultMap = CodeCoverageHelper.getCodeCoverage();
        System.debug(resultMap);
        return resultMap;
    }
}