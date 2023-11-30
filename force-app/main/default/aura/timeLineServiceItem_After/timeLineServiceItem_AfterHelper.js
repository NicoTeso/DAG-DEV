({
	autoAsignar : function(component,event) {
		var item = component.get("v.itemDetail");
        var action = component.get("c.autoAsignarService");
            action.setParams({
           	 	"recordId": item.RecordId
         	});
			action.setCallback(this, function (resp) {
            	console.log(resp.getState());
            	if (resp.getState() == 'SUCCESS') {
             		var response = resp.getReturnValue();
                   if(response){
                       this.refreshtime(component,event);
                    }
                    else{
                        console.log('ERROR Al asignar'); 
                    }
                 }
            	 else {
                        console.log('ERROR'); 
            	        console.log(resp.getError());
            	 }
           	});
            $A.enqueueAction(action);
	},
    refreshtime : function(component,event){
        	var cmpEvent = component.getEvent("cmpRefresh");
        	cmpEvent.setParams({"refrescar" : "true"});
        	cmpEvent.fire();
    }
})