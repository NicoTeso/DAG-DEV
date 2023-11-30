({
	doInit : function(component, event) {
        var recordId = component.get("v.recordId");
        var objeto = component.get("v.objeto");
        var action= component.get("c.getData");
        action.setParams({
           	"recordId": recordId,
            "objeto": objeto
        });
        action.setCallback(this, function (resp) {
        	console.log(resp.getState());
            if (resp.getState() == 'SUCCESS') {
            	var responseJSON = resp.getReturnValue();
             	var response =JSON.parse(responseJSON);
                console.log(responseJSON);
                if(response['Respuesta'] =='OK'){
                    var marca = response['marca'];
                    if(marca){
                        component.set("v.showMarca", true);
                        component.set("v.marcaIcon", marca );
                    }
                    component.set("v.show", true);
                	component.set("v.title", response['titulo']);
                    component.set("v.icono", response['icono']);
                    var items = JSON.parse(response['items']);
                    component.set("v.items", items);
                }
            }
		});
        $A.enqueueAction(action);
   }
})