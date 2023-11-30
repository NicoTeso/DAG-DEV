({
	showSection : function(component, event, helper) {
		var showSection = component.get("v.show");
        if(showSection){
            component.set("v.show",false);
        }
        else {
            component.set("v.show",true);
        }
	},
    autoAsignar : function(component, event, helper) {
        helper.autoAsignar(component,event);
    },
    editar : function(component,event,helper){
        /*var registro = component.get("v.itemDetail");
        var editRecordEvent = $A.get("e.force:editRecord");
        				editRecordEvent.setParams({
            				"recordId": registro.RecordId
       				 	});
        				editRecordEvent.fire(); */
       	component.set("v.isOpen", true);
    },
    creaTarea : function(component,event,helper){
        component.set("v.isOpenCreateTask", true);
        
    },
    onRecordSuccess : function(component,event,helper){
        component.set("v.isOpen", false);
        helper.refreshtime(component,event);
    }, 
    onRecordSuccessTask : function(component,event,helper){
         component.set("v.isOpenCreateTask", false);
         
    },
    closeModel :  function(component,event,helper){
        component.set("v.isOpen", false);
    },
    closeModelTask : function(component,event,helper){
        component.set("v.isOpenCreateTask", false);
    },
    handleCreateTask : function(component,event,helper) {
   		var eventFields = event.getParam("fields"); //get the fields
        eventFields["WhatId"] = '';
        eventFields["WhoId"] = '';
        component.find('createForm').submit(eventFields);
    },
    
    
})