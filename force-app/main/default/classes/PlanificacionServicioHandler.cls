public class PlanificacionServicioHandler implements ITriggerHandler {
    private TriggerExecutionHelper infoTrigger = new TriggerExecutionHelper();
    public Group colaGestion = new Group();
    
     public PlanificacionServicioHandler(Schema.sObjectType soType) {
        InfoTrigger.setTipoHandler(soType);
    }
    
    public TriggerExecutionHelper getInfo() {
        return infoTrigger;
    }
    public void bulkBefore() {
        colaGestion = GroupGateway.getGroupByDeveloperName('Gestion_de_Servicio');
        
    }
    public void bulkAfter() {}
    public void beforeInsert(sObject so) {}
    public void beforeUpdate(sObject old, sObject so){
        Planificacion_Servicio__c pServicio = (Planificacion_Servicio__c) so;
        Planificacion_Servicio__c pServicioOld = (Planificacion_Servicio__c) old;
        if(pServicio.Estado__c.equalsIgnoreCase('Cerrado')){
            if(pServicio.OwnerId == colaGestion.Id){
                pServicio.addError('No se puede cerrar, si no esta asignado');
            }
            
        }
        
    }
    public void beforeDelete(sObject so) {}
    public void afterInsert(sObject so) {}
    public void afterUpdate(sObject old, sObject so) {}
    public void afterDelete(sObject so) {}
    public void andFinally() {}

}