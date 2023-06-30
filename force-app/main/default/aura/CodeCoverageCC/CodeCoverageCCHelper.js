({
    /* doInitHelper funcation to fetch all records, and set attributes value on component load */
    doInitHelper : function(component,event){ 
        var newaction = component.get("c.getCodeCoverage");
        newaction.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                var oRes = response.getReturnValue();
                var ow = JSON.stringify(oRes);
                console.log(ow);
                console.log('Get resposne from APEX>>>'+oRes);
                for (const key in oRes) {

   					 console.log(`${key}: ${oRes[key]}`);
			}
                if(oRes.length > 0){
                     console.log('length os grater than 1');
                    component.set('v.listOfAllClass', oRes);
                    var pageSize = component.get("v.pageSize");
                    var totalRecordsList = oRes;
                    var totalLength = totalRecordsList.length ;
                    component.set("v.totalRecordsCount", totalLength);
                    component.set("v.startPage",0);
                    component.set("v.endPage",pageSize-1);
                    
                    var PaginationListCode = [];
                    for(var i=0; i < pageSize; i++){
                        if(component.get("v.listOfAllClass").length > i){
                            PaginationListCode.push(oRes[i]);    
                        } 
                    }
                    component.set('v.PaginationListCode', PaginationListCode);
                    component.set("v.selectedCount" , 0);
                    //use Math.ceil() to Round a number upward to its nearest integer
                    component.set("v.totalPagesCountCode", Math.ceil(totalLength / pageSize));    
                }else{
                    // if there is no records then display message
                    component.set("v.bNoRecordsFound" , true);
                } 
            }
            else{
                alert('Error...');
            }    
        });
        $A.enqueueAction(newaction);  
    }, 
})