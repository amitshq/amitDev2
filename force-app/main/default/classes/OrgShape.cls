/**
 * Date-15-Aug-2021
 * Author- Amit Kumar
 * @description Class contains static methods for determining if specific platform features are enabled. For example, do we have platform cache enabled.
 * Shared Code
 */
public with sharing class OrgShape {
    private Cache.OrgPartition safeDefaultCachePartition;
    private Organization orgShape = getOrgShape();
    /**
     * @description property reports whether this transaction took place
     * in a sandbox.
     */
    public Boolean isSandbox {
        get {return getOrgShape().isSandbox;}
    }

    /**
     * @description returns the instance name.
     * In practice not null.
     */
    public String instanceName {
        get {
            return getOrgShape().instanceName;
        }
    }

    /**
     * @description convenience method. Alias for instanceName
     */
    public String podName {
        get {
            return instanceName;
        }
    }

    /**
     * @description reports the org's ID.
     * in practice, this is a constant
     */
    public Id id {
        get {
            return getOrgShape().id;
        }
    }

    /**
     * @description reports the org's locale
     */
    public String locale {
        get {
            return getOrgShape().languageLocaleKey;
        }
    }

    /**
     * @description reports the org's name
     */
    public String name {
        get {
            return getOrgShape().name;
        }
    }

    /**
     * @description Method determines if platform cache is enabled for this org
     * Note: fail-safes to false.
     * Note: Allows override by setting OrgShape.disablePlatformCache
     * equal to true. Use this in test contexts where cache is not available like
     * when you have to use seeAllData=true
     * @return      `Boolean`
     */
    public Boolean isPlatformCacheEnabled() {
        Cache.OrgPartition defaultCachePartition = getAvailableOrgCachePartition();
        if (isSeeAllDataTrue() || defaultCachePartition == null) {
            return false;
        }

        Boolean cacheAvailable = false;
        try {
            getAvailableOrgCachePartition().getCapacity();
            cacheAvailable = true;
        } catch (Exception ex) {
            system.debug(LoggingLevel.WARN, 'Failed to get orgCache');
        }
        return cacheAvailable;
    }

    /**
     * @description Certain features of the platform are incompatible with
     * data-siloed tests. These features require testing with the annotation
     * @test(seeAllData=true). Other platform features are incompatible with
     * seeAllData=true. When used in a test context, this method determines if
     * the currently running test is executing with, or without seeAllData=true.
     *
     * This method is therefore used to automatically disable platform features
     * that require are incompatible with seeAllData=true. For example: platform
     * cache is incompatible with seeAllData=true. However, our security
     * library, CanTheUser utilizes platform cache to accelerate Crud and FLS
     * checks. CanTheUser uses this method, in part, to determine, transparently
     * if it should utilize platformCache during test execution
     *
     * Note: It is not a good idea, and against best practices to use
     * seeAllData=true when not absolutely necessary.
     * @return      `Boolean`
     */
    public Boolean isSeeAllDataTrue() {
        Boolean seeAllData = false;
        if (!Test.isRunningTest()) {
            return seeAllData; // This line is not testable :(
        }

        try {
            // this will throw an exception in a data-siloed test.
            ConnectApi.ChatterUsers.getFollowings(
                null,
                String.valueOf(UserInfo.getUserId())
            );
            seeAllData = true;
        } catch (UnsupportedOperationException UE) {
            // this means seeAllData != true
            System.debug(
                LoggingLevel.INFO,
                'Caught UnsupportedOperationException'
            );
        }
        return seeAllData;
    }

    /**
     * @description This method is responsible for discovering a cache partition
     * that can be used for determining if platformCache is enabled and
     * configured.
     *
     * Note: This method memoizes the result of the query, ensuring that the
     * underlying soql query is only ever run once per transaction.
     *
     * @return      `String`
     */
    private Cache.OrgPartition getAvailableOrgCachePartition() {
        if (this.safeDefaultCachePartition != null) {
            return this.safeDefaultCachePartition;
        }
        try {
            PlatformCachePartition partition = [
                SELECT developerName
                FROM PlatformCachePartition
                WHERE NamespacePrefix = ''
                LIMIT 1
            ];
            String partitionName = 'local.' + partition.DeveloperName;
            this.safeDefaultCachePartition = Cache.Org.getPartition(
                partitionName
            );
        } catch (System.QueryException qe) {
            String msg = qe.getMessage();
            System.debug(
                LoggingLevel.WARN,
                'Caught QueryException looking for cache partition'
            );
        }
        return this.safeDefaultCachePartition;
    }

    /**
     * @description Uses a dynamic soql query to determine if Advanced
     * MultiCurrency Management is enabled. Note, this must be a dynamic soql
     * query because referencing DatedConversionRate will not compile in orgs
     * without Advanced MultiCurrency Management enabled.
     *
     * @return      `Boolean`
     */
    public Boolean isAdvancedMultiCurrencyManagementEnabled() {
        Boolean isACMEnabled = false;
        if (UserInfo.isMultiCurrencyOrganization()) {
            try {
                Integer datedConversionRateCount = Database.query(
                        'SELECT Id FROM DatedConversionRate LIMIT 1'
                    )
                    .size();
                if (datedConversionRateCount == 1) {
                    isACMEnabled = true;
                }
            } catch (Exception e) {
                // Nothing to do, ACM = false
            }
        }
        return isACMEnabled;
    }

    /// HELPER METHODS
    private Organization getOrgShape() {
        if (isPlatformCacheEnabled()) {
            return (Organization) getAvailableOrgCachePartition()
                .get(CachedOrgShape.class, 'requiredButNotUsed');
        } else {
            if (this.OrgShape != null) {
                return this.orgShape;
            } else {
                this.orgShape = getOrgRecord();
            }
            return this.orgShape;
        }
    }
    private Organization getOrgRecord() {
        return [SELECT FIELDS(STANDARD) FROM Organization LIMIT 1];
    }

    public with sharing class CachedOrgShape implements Cache.CacheBuilder {
        public Organization doLoad(String requiredButNotUsed) {
            // Note: You should normally limit all your queries with
            // WITH SECURITY_ENFORCED
            // but you cannot do that for Organization.
            Organization org = [
                SELECT FIELDS(STANDARD)
                FROM Organization
                LIMIT 1
            ];
            return org;
        }
    }
}