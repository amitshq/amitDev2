/**
* Date-21-Aug-2021
* Author- Amit Kumar
* @description [Slack Cache]Class wraps DML Calls in FLS / Crud checks and slack cache. All calls are constructed, then chained with the methods.
*
* This Class have chainable methods include:
* - allOrNothing() - this enforces the AllOrNothing DML flag. All DML is eventually executed via Database.* methods which accept an allOrNothing
*      parameter requiring all of the records to succeed or fail.
* - throwIfRemovedFields() - this method, if called, will result in an exception being thrown if any record being modified has fields removed
*     by the security decision.
* -Store(message) - stores the message conversation to reduce minimum callouts for slack
*/
public class CRUDSafteyCheck {
    
    public enum CrudType {
        CREATE,
            READ,
            EDIT,
            DEL,
            UPS
            }
    
    public enum FLSType {
        ACCESSIBLE,
            UPDATABLE
            }
    
    private static Map < String, Set < String >> accessibleFieldsByObject = new Map < String, Set < String >> ();
    
    private static Map < String, Set < String >> updatableFieldsByObject = new Map < String, Set < String >> ();
    
    private static Boolean allOrNothing = false;
    
    private static Boolean throwIfRemovedFields = false;
    /*** @description Internal custom exception class*/
    public class CRUDSafteyException extends Exception {
        
    }
    /*** @description Internal custom exception class*/
    public class RemovedFieldsException extends Exception {
        
    }
    
    public static boolean allOrNothing() {
        allOrNothing = true;
        return allOrNothing;
    }
    
    public static boolean throwIfRemovedFields() {
        throwIfRemovedFields = true;
        return throwIfRemovedFields;
    }
    /**@description this cachebuilder interface allows the CRUDSaftey class to cache per-object results for each object requested. This prevents the
* need to repeatedly calculate permission usage by calling Schema.Describe* calls*/
    public class PermissionCache implements Cache.CacheBuilder {
        /**
* @description  Actalluy its required method for the CacheBuilder interface. Here we are Using here to either calculate an objects per-user FLS, OR to return it
* from Cache.
* The return datastructure for this is
* Map<String, Map<FLSType,Boolean>> and represents:
* FieldName -> FLStype -> True/False
* @param objType String object name used as the cache key
* @return       `Object`
*/
        public Object doLoad(String objType) {
            return calculateFLS(objType);
        }
        
        /**@description   Calculates the FLS for a given object type
* @param objType String name of the object type
* @return        `Map<String, Map<FLSType, Boolean>>`
*/
        public Map < String, Map < FLSType, Boolean >> calculateFLS(string objType) {
            Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(new List < String > {objType});
            
            Map < String, Map < FLSType, Boolean >> results = new Map < String, Map < FLSType, Boolean >> ();
            for (SObjectField field: descResult[0].fields.getMap().values()) {
                DescribeFieldResult fieldDetails = field.getDescribe();
                String fieldKey = String.valueOf(field).toLowerCase();
                results.put(fieldKey, new Map < FLSType, Boolean > ());
                results.get(fieldKey).put(FLSType.ACCESSIBLE, fieldDetails.isAccessible());
                results.get(fieldKey).put(FLSType.UPDATABLE, fieldDetails.isUpdateable());
            }
            return results;
        }
    }
    /// Insert (C)
    public static List<Database.SaveResult> doInsert(List<SObject> records) {
        if (records.isEmpty()) {
            return new List<Database.SaveResult>();
        }
        if (create(records)) {
            return doDML(System.AccessType.CREATABLE, records);
        }
        return new List<Database.SaveResult>();
    }
    
    /// Update (U)
    public static List<Database.SaveResult> doUpdate(List<SObject> records) {
        if (records.isEmpty()) {
            return new List<Database.SaveResult>();
        }
        if (edit(records)) {
            return doDML(System.AccessType.UPDATABLE, records);
        }
        return new List<Database.SaveResult>();
    }
    
    /// Upsert
    public static List<Database.UpsertResult> doUpsert(List<SObject> records) {
        if (records.isEmpty()) {
            return new List<Database.UpsertResult>();
        }
        if (edit(records) && create(records)) {
            return Database.upsert(records,allOrNothing);
        }
        return new List<Database.UpsertResult>();
    }
    
    /// Main Driver Methods
    public static List<Database.SaveResult> doDML(System.AccessType accessType,List<SObject> records) {
        
        switch on accessType {
            when CREATABLE {
                return Database.insert(records,allOrNothing);
            }
            when UPDATABLE {
                return Database.update(records,allOrNothing);
            }
            when else {
                return new List<Database.SaveResult>();
            }
        }
    }
    
    /**
* @description
* @param obj the object type to check
* @param permission create, read, update or delete
* @return Boolean
* @example
* System.debug(crud(new Account(), CrudType.READ));
**/
    
    public static Boolean crud(SObject obj, CrudType permission) {
        switch on permission {
            when CREATE {
                return obj.getSObjectType().getDescribe().isCreateable();
            }
            when READ {
                return obj.getSObjectType().getDescribe().isAccessible();
            }
            when EDIT {
                return obj.getSObjectType().getDescribe().isUpdateable();
            }
            when DEL {
                return obj.getSObjectType().getDescribe().isDeletable();
            }
        }
        return false;
    }
    public static Boolean crud(List < SObject > objs, CrudType permission) {
        return crud(objs?.get(0), permission);
    }
    public static Boolean crud(String objectName, CrudType permission) {
        Type t = Type.forName(objectName);
        SObject p = (SObject) JSON.deserialize('{}', t);
        return crud(p, permission);
    }
    
    /**@description convenience api for determining if the running user can create the specified object
* @param  objs list of objects. Only the first will be checked.
* @return Boolean
*/
    
    public static Boolean create(List < SObject > objs) {return crud(objs?.get(0), CrudType.CREATE);}
    /**@description convenience api for determining if the running user can read / access the specified object
* @param obj object type to check read permissions on
* @return Boolean
**/
    
    public static Boolean read(SObject obj) {return crud(obj, CrudType.READ);}
    /**
* @description convenience api for determining if the running user can read / access the specified objects
* @param obj object type to check read permissions on
* @return Boolean
**/
    
    public static Boolean read(List < SObject > objs) {return crud(objs?.get(0), CrudType.READ);}
    
    /**
* @description convenience api for determining if the running user can read the specified object
* @param String Object type to check read permissions on
* @return Boolean
**/
    
    public static Boolean read(String objName) { return crud(objName, CrudType.READ);}
    
    
    /**
* @description convenience api for determining if the running user can edit / update the specified objects
* @param obj object type to check edit permissions on
* @return Boolean
**/
    
    public static Boolean edit(List < SObject > objs) {return crud(objs?.get(0), CrudType.EDIT);}
    
    
    /**
* @description convenience api for determining if the running user can edit / update the specified objects
* @param obj object type to check upsert permissions on
* @return Boolean
**/
    
    public static Boolean ups(List < SObject > objs) {return crud(objs?.get(0), CrudType.UPS);}
    
    /**
* @description public method to determine if a given field on a givenobject is Accessible (readable)
* @param obj the object in question, in string form
* @param field the field in question in SObjectField form
**/
    
    public static Boolean flsAccessible(String obj, String field) {return getFLSForFieldOnObject(obj, field, FLSType.ACCESSIBLE);}
    
    /**
* @description public method to determine if a given field on a given object is Updatable.
* @param obj the string version of an object name
* @param field the field to check
* @return Boolean
**/
    
    public static Boolean flsUpdatable(String obj, String field) {return getFLSForFieldOnObject(obj, field, FLSType.UPDATABLE);}
    
    
    /**
* @description   Utilizes the Metadata catalog to determine FLS
* Normally, we'd want to check for FLS/CRUD here, but for metadata catalog
* objects that admins cannot remove permissions to we're ok.
*
* Additionally, even the minimum access profile user has read access
* to the FieldPermissions object.
*
* @param objType String version of the object type to check
* @param action  Enum of the FLS action to check permissions for
* @return       `set<String>`
*/
    
    public static Set < String > memoizeFLSMDC(String objType, FLSType action) {
        List < FieldPermissions > fields = [
            SELECT Id, Field, PermissionsEdit, PermissionsRead, SobjectType FROM FieldPermissions WHERE SobjectType =: objType];
        
        if (!accessibleFieldsByObject.containsKey(objType)) {
            Set < String > accessibleFields = new Set < String > ();
            Set < String > updatableFields = new Set < String > ();
            for (FieldPermissions field: fields) {
                String[] parts = field.Field.split('\\.');
                if (field.PermissionsRead) {
                    accessibleFields.add(parts[1].toLowerCase());
                }
                if (field.PermissionsEdit) {
                    updatableFields.add(parts[1].toLowerCase());
                }
            }
            accessibleFieldsByObject.put(objType, accessibleFields);
            updatableFieldsByObject.put(objType, updatableFields);
        }
        
        if (action == FLSType.ACCESSIBLE) {
            return accessibleFieldsByObject.get(objType);
        } else {
            return updatableFieldsByObject.get(objType);
        }
    }
    
    /**@description     Here is Abstracted method fro retrieving or calculating (memoization) of the FLS for a given field on a given object.
* @param obj       String version of object name to check
* @param field     String version of the field to check
* @param checkType Enum of Accessible or Updatable.
* @return         `Boolean`
*/
    
    public static Boolean getFLSForFieldOnObject(String obj, String field, FLSType checkType) {
        try{
            Cache.Partition defaultSession = Cache.Org.getPartition('local.SlackCache'); //Fetch the partitions
            Map < String, Map < FLSType, Boolean >> objResults;
            if(new OrgShape().isPlatformCacheEnabled()) {
                objResults = (Map < String, Map < FLSType, Boolean >> ) defaultSession.get(PermissionCache.class, obj);
            } else {
                objResults = new PermissionCache().calculateFLS(obj);
            }
            
            Boolean results = objResults.get(field.toLowerCase())?.get(checkType);
            return (results != null && results) ? true : false;
        }
        catch(Cache.Org.OrgCacheException ex){
            System.debug('Cache Orh Exception'+ex);
        }
        
        return null;
    }
}