public class PlanificacionServicioGateway {
    public static Map<String,Planificacion_Servicio__c> getMapCodSerToPlanServiceActByVehicleId(String vehiculoId){
        Map<String,Planificacion_Servicio__c> mapCodSerToPlanService = new Map<String,Planificacion_Servicio__c>();
        if(!String.isBlank(vehiculoId)){
            Map<String,Map<String,Planificacion_Servicio__c>> mapCodSerToPlanServiceActByVehicleId = PlanificacionServicioGateway.getMapCodSerToPlanServiceActByVehicleId(new Set<String>{vehiculoId});
            if(!mapCodSerToPlanServiceActByVehicleId.isEmpty() && mapCodSerToPlanServiceActByVehicleId.containsKey(vehiculoId)){
                mapCodSerToPlanService = mapCodSerToPlanServiceActByVehicleId.get(vehiculoId);
            }
        }
        return mapCodSerToPlanService;
    }
    
    public static Map<String,Map<String,Planificacion_Servicio__c>> getMapCodSerToPlanServiceActByVehicleId(Set<String> vehiculoIds){
        Map<String,Map<String,Planificacion_Servicio__c>> mapCodSerToPlanServiceByVehicle = new Map<String,Map<String,Planificacion_Servicio__c>>();
        if(!vehiculoIds.isEmpty()){
        	for(Planificacion_Servicio__c pServicio :[Select Id, Name, Codigo_Servicio__c, Vehiculo__c, Fecha_Mantenimiento__c, Fecha_Aviso_Email_SMS__c, Fecha_Aviso_Llamada__c, Estado__c, 
                                                      Tipo_mantenimiento__c, Fecha_ultima_realizacion__c, Ultimos_kilometros__c   
                                                      From Planificacion_Servicio__c Where Vehiculo__c in :vehiculoIds AND Estado__c !='Cerrado' AND Estado__c != 'No aplica' ]){
            
				Map<String,Planificacion_Servicio__c> mapCodSerToPlanService = mapCodSerToPlanServiceByVehicle.containsKey(pServicio.Vehiculo__c)?mapCodSerToPlanServiceByVehicle.get(pServicio.Vehiculo__c):new Map<String,Planificacion_Servicio__c>();
                mapCodSerToPlanService.put(pServicio.Codigo_Servicio__c, pServicio);
                mapCodSerToPlanServiceByVehicle.put(pServicio.Vehiculo__c,mapCodSerToPlanService);
            }
        }
        return mapCodSerToPlanServiceByVehicle;
    }

    public static Map<String,Planificacion_Servicio__c> getMapCodSerToLastPlanServiceByVehicleId(String vehiculoId){
        Map<String,Planificacion_Servicio__c> mapCodSerToLastPlanService = new Map<String,Planificacion_Servicio__c>();
        if(!String.isBlank(vehiculoId)){
            Map<String,Map<String,Planificacion_Servicio__c>> mapCodSerToPlanServiceLastByVehicleId = PlanificacionServicioGateway.getMapCodSerToLastPlanServiceByVehicleId(new Set<String>{vehiculoId});
            if(!mapCodSerToPlanServiceLastByVehicleId.isEmpty() && mapCodSerToPlanServiceLastByVehicleId.containsKey(vehiculoId)){
                mapCodSerToLastPlanService = mapCodSerToPlanServiceLastByVehicleId.get(vehiculoId);
            }
        }
        return mapCodSerToLastPlanService;
    }
    
    public static Map<String,Map<String,Planificacion_Servicio__c>> getMapCodSerToLastPlanServiceByVehicleId(Set<String> vehiculoIds){
        Map<String,Map<String,Planificacion_Servicio__c>> mapCodSerToLastPlanServiceByVehicle = new Map<String,Map<String,Planificacion_Servicio__c>>();
 
        if(!vehiculoIds.isEmpty()){
        	for(Planificacion_Servicio__c pServicio :[Select Id, Name, Codigo_Servicio__c, Vehiculo__c, Fecha_Mantenimiento__c, Fecha_Aviso_Email_SMS__c, Fecha_Aviso_Llamada__c, Estado__c, 
                                                             Tipo_mantenimiento__c, Fecha_ultima_realizacion__c, Ultimos_kilometros__c, CreatedDate  
                                                      From Planificacion_Servicio__c Where Vehiculo__c in :vehiculoIds]){

//recuperamos todo lo del vehículo y nos quedamos con la última fecha de creación                                                          
				Map<String,Planificacion_Servicio__c> mapCodSerToLastPlanService = mapCodSerToLastPlanServiceByVehicle.containsKey(pServicio.Vehiculo__c)?mapCodSerToLastPlanServiceByVehicle.get(pServicio.Vehiculo__c):new Map<String,Planificacion_Servicio__c>();
                if(mapCodSerToLastPlanService.containsKey(pServicio.Codigo_Servicio__c)){
                    Planificacion_Servicio__c pServicioAux = mapCodSerToLastPlanService.get(pServicio.Codigo_Servicio__c);
                    if(pServicioAux.CreatedDate < pServicio.CreatedDate ){
                        mapCodSerToLastPlanService.put(pServicio.Codigo_Servicio__c, pServicio);
                    }
                    //else se queda con el pServicio que tiene
                }
                else {
                     mapCodSerToLastPlanService.put(pServicio.Codigo_Servicio__c, pServicio);
                }
                                                          
                mapCodSerToLastPlanServiceByVehicle.put(pServicio.Vehiculo__c,mapCodSerToLastPlanService);
            }
        }
        return mapCodSerToLastPlanServiceByVehicle;
    }

}