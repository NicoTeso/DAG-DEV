public class ManagerService {

    @future
    public static void manageService(String VehiculoId){
        Vehiculo__c vehiculo = vehiculoGateway.getVehicleById(VehiculoId);
        try {  
        if (vehiculo.Fecha_primera_matriculacion__c != null) {

        Map<String,Planificacion_Servicio__c> mapCodSerToPlanService = PlanificacionServicioGateway.getMapCodSerToPlanServiceActByVehicleId(vehiculo.Id); 
        Map<String,Planificacion_Servicio__c> mapCodSerToLastPlanService = PlanificacionServicioGateway.getMapCodSerToLastPlanServiceByVehicleId(vehiculo.Id);
        system.debug('mapCodSerToPlanService: '+mapCodSerToPlanService);
        system.debug('mapCodSerToLastPlanService: '+mapCodSerToLastPlanService);
        Pase_de_taller__c lastPaseTaller = PaseTallerGateway.getLastPaseTallerByVehiculoId(vehiculo.Id);
        system.debug('lastPaseTaller:'+ lastPaseTaller);
        Group cola = GroupGateway.getGroupByDeveloperName(Label.ColaGestionServicioDN);
        List<Servicio__c> serviciosPaseTaller = new List<Servicio__c>();
        List<string> gruposH = new List<string>();
        if (lastPaseTaller != null) {
            serviciosPaseTaller = ServicioGateway.getServiciosByPaseTallerId(lastPaseTaller.Id);
            // si tenemos servicios, hacemos una lista con los grupos homogeneos que hay en cada servicio
            if (!serviciosPaseTaller.isEmpty()) {
                for(Servicio__c servicioPT : serviciosPaseTaller){
                    if (servicioPT.PartGroupCode__c != null) {
                        gruposH.addAll(servicioPT.PartGroupCode__c.split(','));
                    }
                }    
            }
            if (!gruposH.isEmpty()) {
                // recorremos la lista de grupos homogeneos
                // preguntar a Inma ¿?¿?
                for(string grupoH : gruposH){
                    //Si tengo en el mapa de servicios anteriores el grupo homogeneo como clave, 
                    // actualizamos en el mapa la fecha y los kms de este ultimo pase de taller 
                    if (mapCodSerToLastPlanService.containsKey(grupoH)){
                        Planificacion_Servicio__c PlanService = mapCodSerToLastPlanService.get(grupoH);
                        PlanService.Fecha_ultima_realizacion__c = lastPaseTaller.deliveryDate__c.date();
                        PlanService.Ultimos_kilometros__c = lastPaseTaller.kms__c;
                        mapCodSerToLastPlanService.put(grupoH,PlanService);
                    } else {
                        //Si tengo en el mapa de servicios anteriores el grupo homogeneo como parte de alguna clave, 
                        // actualizamos en el mapa la fecha y los kms de este ultimo pase de taller 
                        Boolean EncontradoGH = false;
                        for (Planificacion_Servicio__c PlanService : mapCodSerToLastPlanService.values()) {
                            if (PlanService.Codigo_Servicio__c.contains(grupoH)){
                                PlanService.Fecha_ultima_realizacion__c = lastPaseTaller.deliveryDate__c.date();
                                PlanService.Ultimos_kilometros__c = lastPaseTaller.kms__c;
                                mapCodSerToLastPlanService.put(PlanService.Codigo_Servicio__c,PlanService);
                                EncontradoGH = true;
                                break;
                            }
                        }   
                        //Si no tengo en el mapa de servicios anteriores el grupo homogeneo como parte de alguna clave, 
                        // añadimos al mapa de servicios anteriores una ocurrencia para este grupo homogeneo 
                        if (!EncontradoGH) {
                            Planificacion_Servicio__c PlanService = new Planificacion_Servicio__c();
                            PlanService.Codigo_Servicio__c = grupoH;
                            PlanService.Fecha_ultima_realizacion__c = lastPaseTaller.deliveryDate__c.date();
                            PlanService.Ultimos_kilometros__c = lastPaseTaller.kms__c;
                            mapCodSerToLastPlanService.put(grupoH,PlanService);
                        }
                    }
                }    
            }    
        }
        
        List<Planificacion_Servicio__c> upsertPlanServicios = new List<Planificacion_Servicio__c>();
        Map<String,Planificacion_Servicio__c> updatePlanNoAplica = new Map<String,Planificacion_Servicio__c>();
        List<String> deletePlanServicios = new List<String>();
        
        String marca = vehiculo.MarcaString__c;
        if (vehiculo.MarcaString__c.equalsIgnoreCase('CITROËN')){
            marca = 'CITROEN';    
        } else if (vehiculo.MarcaString__c.equalsIgnoreCase('VW COMERCIALES')){
            marca = 'VW_COMERCIALES';    
        }
            
        List<Regla_Target__c> listaMotorToReglas = ReglaTargetGateway.getMotorToReglaTargetByDeveloperName(marca);
        Map<String,Regla_Target__c> reglas = new Map<String,Regla_Target__c>();
        Regla_Target__c MotorToReglaSel = new Regla_Target__c();
        Regla_Target__c MotorToReglaAnt = new Regla_Target__c();
        Map<String,Regla_Target__c> reglaByClaveRegla = new Map<String,Regla_Target__c>();

        for(Regla_Target__c MotorToRegla : listaMotorToReglas){
            MotorToReglaSel = null;
            MotorToReglaAnt = null;

            if (vehiculo.MarcaString__c.equalsIgnoreCase('DUCATI') &&
                MotorToRegla.Modelo__c != null && MotorToRegla.Ano_modelo__c != null &&
                vehiculo.modelDescription__c != null &&
                vehiculo.modelDescription__c.contains(MotorToRegla.Modelo__c) &&
               (vehiculo.Ano_Modelo__c == MotorToRegla.Ano_modelo__c)){
                MotorToReglaSel = MotorToRegla;
            } else if (vehiculo.MarcaString__c.equalsIgnoreCase('HYUNDAI') &&
                       MotorToRegla.Modelo__c != null &&
                       vehiculo.ModeloString__c != null &&
                       vehiculo.ModeloString__c.contains(MotorToRegla.Modelo__c)){
                MotorToReglaSel = MotorToRegla;
                system.debug('MotorToReglaSel 1: '+MotorToReglaSel);
            } else if (MotorToRegla.Motor__c != null &&
                       vehiculo.Letra_Motor__c != null &&
                       MotorToRegla.Motor__c.contains(vehiculo.Letra_Motor__c)){
                MotorToReglaSel = MotorToRegla;
            } else if (MotorToRegla.Motor__c.contains('Defecto') &&
                      (MotorToRegla.Modelo__c == null || String.isBlank(MotorToRegla.Modelo__c))){
                MotorToReglaSel = MotorToRegla;
                system.debug('MotorToReglaSel 2: '+MotorToReglaSel);
            }

            if (MotorToReglaSel != null){
                if (!reglas.isEmpty() && reglas.containsKey(MotorToReglaSel.ClaveRegla__c)){
                    MotorToReglaAnt = reglas.get(MotorToReglaSel.ClaveRegla__c);
                    system.debug('MotorToReglaAnt 1: '+MotorToReglaAnt);
                    if (MotorToReglaAnt.Motor__c.contains('Defecto') &&
                       (MotorToReglaAnt.Modelo__c == null || String.isBlank(MotorToReglaAnt.Modelo__c))){
                        reglas.put(MotorToReglaSel.ClaveRegla__c, MotorToReglaSel);
                        system.debug('MotorToReglaAnt 2: '+MotorToReglaAnt);
                    }
                } else{
                    reglas.put(MotorToReglaSel.ClaveRegla__c, MotorToReglaSel);
                    system.debug('MotorToReglaAnt 0: '+MotorToReglaAnt);
                }
            }
            
        }

        Integer i = 1;    
        for(String reglaClave1 : reglas.keyset()){
            
            Regla_Target__c reglaTarget1 = reglas.get(reglaClave1);
            
            if (!reglaTarget1.Aplica__c){
                system.debug('Eliminada['+i+']: '+reglaTarget1);
                reglas.remove(reglaClave1);
            }

            system.debug('reglas['+i+']: '+reglaTarget1);
            i++;
        }
        
        if (!mapCodSerToPlanService.isEmpty()){
            //Modificar, Eliminar y crear planificacion de Servicio
            // nos falta solo elimnar si estado 'Sin asignar' o modificar a No aplica si asignado'
            for (Planificacion_Servicio__c PlanService : mapCodSerToPlanService.values()) {
                if(planService.Estado__c.equalsIgnoreCase(Label.EstadoSinAsignar)){
                    deletePlanServicios.add(PlanService.Id); 
                }
                else if(planService.Estado__c.equalsIgnoreCase(Label.EstadoAsignado)){
                    planService.Estado__c =Label.EstadoNoAplica;
                    updatePlanNoAplica.put(planService.Id, planService);
                    
                }
                 
            }
            system.debug('deletePlanServicios: '+deletePlanServicios);
            upsertPlanServicios = creaNuevasPlanificaciones(vehiculo,lastPaseTaller,serviciosPaseTaller,reglas,mapCodSerToLastPlanService, cola);
        } else {
            //Crear nuevas planificacion de Servicio
            upsertPlanServicios = creaNuevasPlanificaciones(vehiculo,lastPaseTaller,serviciosPaseTaller,reglas,mapCodSerToLastPlanService, cola);
        }

        if (!deletePlanServicios.isEmpty()){
            system.debug('entra a borrar');
            Database.delete(deletePlanServicios);
        }
        if(!updatePlanNoAplica.isEmpty()){
            Database.upsert(updatePlanNoAplica.values());
        }
        
        if (!upsertPlanServicios.isEmpty()){
            Database.upsert(upsertPlanServicios);
        }
            
        }

        }catch(Exception e){
 
            Exception__c exc = new Exception__c ();
            exc.idObjetos__c = vehiculo.Id;
            exc.Exception__c = e.getCause() + '// '+ e.getMessage();
            exc.Linea__c = e.getLineNumber();
//            exc.JSON_Entrada__c = JSON.serialize(req);
            exc.Clase_Metodo__c = 'ManagerService';
            
            insert exc;
        }
            
    }
    
    private static List<Planificacion_Servicio__c> creaNuevasPlanificaciones(Vehiculo__c vehiculo, Pase_de_taller__c paseTaller, List<Servicio__c> serviciosPT,Map<String,Regla_Target__c> reglas, Map<String,Planificacion_Servicio__c> mapCodSerToLastPlanService, Group cola){
        List<Planificacion_Servicio__c> planServiciosUpsert = new List<Planificacion_Servicio__c>();
        Date fechaFin = Date.today();
        if (vehiculo.Fecha_actualizacion_kms__c != null) {
            fechaFin = vehiculo.Fecha_actualizacion_kms__c.date();
        }
        integer antiVehiculoMeses = vehiculo.Fecha_primera_matriculacion__c.date().monthsBetween(fechaFin);
        system.debug('vehiculo.Fecha_primera_matriculacion__c: '+vehiculo.Fecha_primera_matriculacion__c.date());
        system.debug('fechaFin: '+fechaFin);
        system.debug('antiVehiculoMeses: '+antiVehiculoMeses);
        
        for(String reglaClave : reglas.keyset()){

            Regla_Target__c reglaTarget = reglas.get(reglaClave);
            
            Planificacion_Servicio__c planServicioAntes = mapCodSerToLastPlanService.containsKey(reglaTarget.Grupo_homogeneo__c)?mapCodSerToLastPlanService.get(reglaTarget.Grupo_homogeneo__c):null;
            system.debug('planServicioAntes: '+planServicioAntes);

            if (planServicioAntes == null) {
                List<string> gruposH1 = new List<string>();
                gruposH1.addAll(reglaTarget.Grupo_homogeneo__c.split(';'));
                if (!gruposH1.isEmpty()) {
                    // recorremos la lista de grupos homogeneos
                    for (string grupoH1 : gruposH1){
                        for (Planificacion_Servicio__c PlanService1 : mapCodSerToLastPlanService.values()) {
                            if (PlanService1.Codigo_Servicio__c.contains(grupoH1)){
                                PlanService1.Codigo_Servicio__c = reglaTarget.Grupo_homogeneo__c; 
                                planServicioAntes = PlanService1; 
                                break;
                            }
                        }   
                    }            
                }            
            }            
            
            Planificacion_Servicio__c planServicio;
            
            system.debug('reglaTarget.Grupo_homogeneo__c: '+reglaTarget.Grupo_homogeneo__c);
            
            if (vehiculo.MarcaString__c.equalsIgnoreCase('AUDI') ||
                vehiculo.MarcaString__c.equalsIgnoreCase('DUCATI') ||
                vehiculo.MarcaString__c.equalsIgnoreCase('SKODA') ||
                vehiculo.MarcaString__c.equalsIgnoreCase('VOLKSWAGEN') ||
                vehiculo.MarcaString__c.equalsIgnoreCase('VW COMERCIALES') || 
                vehiculo.MarcaString__c.equalsIgnoreCase('HYUNDAI')){
                //Inspección (primera y sucesivas)
            	if (reglaTarget.Grupo_homogeneo__c.contains('282') ||
                    reglaTarget.Grupo_homogeneo__c.contains('25B') ||
             	    reglaTarget.Grupo_homogeneo__c.contains('RCO')){
                    // 1) Si no tengo planificación anterior y es primera inspeccion y el vehiculo no alcanzo la antiguedad en meses de 
                    //    finalizar el target
                    // 2) Si tengo planificación anterior y los kms de realización del servicio son nulos y es primera inspeccion y el 
                    // vehiculo no alcanzo la antiguedad en meses de finalizar el target
                    // 3) Si tengo planificación anterior y los kms de realización del servicio no son nulos y es inspeccion 
                    // 
                    // En los casos 1 y 2 sigo en la primera inspección en el caso 3 una vez que tengo kms de realización ya estoy en 
                    // inspecciones consecutivas
                    // 
                    if (((planServicioAntes == null) &&
                         (reglaTarget.Tipo_mantenimiento__c.equalsIgnoreCase('Primera inspección')) && 
                         (antiVehiculoMeses <= reglaTarget.Finaliza_en__c.intValue())) || 
                        ((planServicioAntes != null) &&
                         (planServicioAntes.Ultimos_kilometros__c == null) &&
                         (reglaTarget.Tipo_mantenimiento__c.equalsIgnoreCase('Primera inspección')) && 
                         (antiVehiculoMeses <= reglaTarget.Finaliza_en__c.intValue())) ||
                        ((planServicioAntes != null) &&
                         (planServicioAntes.Ultimos_kilometros__c != null) &&
                         (reglaTarget.Tipo_mantenimiento__c.equalsIgnoreCase('Inspección')))) {
                		  planServicio = new Planificacion_Servicio__c();
                		  planServicio.Name = reglaTarget.Tipo_mantenimiento__c;
                          if (vehiculo.Concesionario_Taller__c != null) {
                              planServicio.Concesionario__c = vehiculo.Concesionario_Taller__c;
                              planServicio.Centro__c = vehiculo.Centro_Taller__c;    
                          } else {
                              planServicio.Concesionario__c = vehiculo.Concesionario__c;
                              planServicio.Centro__c = vehiculo.Centro__c; 
                          }
                          planServicio.Marca__c = vehiculo.MarcaString__c;
                          planServicio.OwnerId = cola.Id;   
                		  planServicio.Vehiculo__c = vehiculo.Id;
                          planServicio.Tipo_de_venta__c = vehiculo.Tipo_de_venta__c;   
                		  planServicio.Estado__c= 'Sin asignar';
                	      planServicio.Tipo_mantenimiento__c = reglaTarget.Tipo_mantenimiento__c;
                		  planServicio.Codigo_Servicio__c = reglaTarget.Grupo_homogeneo__c;
                		  calcularFechasTarget(planServicio, vehiculo, reglaTarget , planServicioAntes);
                    }
                }
                //Líquido de frenos (primer cambio y sucesivos)
             	else if (reglaTarget.Grupo_homogeneo__c.contains('CCA')){
                    // 1) Si no tengo planificación anterior y es primera inspeccion y el vehiculo no alcanzo la antiguedad en meses de 
                    //    finalizar el target
                    // 2) Si tengo planificación anterior y los kms de realización del servicio son nulos y es primera inspeccion y el 
                    // vehiculo no alcanzo la antiguedad en meses de finalizar el target
                    // 3) Si tengo planificación anterior y los kms de realización del servicio no son nulos y es inspeccion 
                    // 
                    // En los casos 1 y 2 sigo en la primera inspección en el caso 3 una vez que tengo kms de realización ya estoy en 
                    // inspecciones consecutivas
                    // 
                    if ((((planServicioAntes == null) &&
                         (reglaTarget.Empieza_en__c == 0) && 
                         (reglaTarget.Finaliza_en__c != null) &&
                         (antiVehiculoMeses <= reglaTarget.Finaliza_en__c.intValue())) || 
                        ((planServicioAntes != null) &&
                         (planServicioAntes.Ultimos_kilometros__c == null) &&
                         (reglaTarget.Empieza_en__c == 0) && 
                         (reglaTarget.Finaliza_en__c != null) &&
                         (antiVehiculoMeses <= reglaTarget.Finaliza_en__c.intValue())) ||
                        ((planServicioAntes != null) &&
                         (planServicioAntes.Ultimos_kilometros__c != null) &&
                         (reglaTarget.Empieza_en__c != 0))) || 
                         (vehiculo.MarcaString__c.equalsIgnoreCase('DUCATI'))) {
                		  planServicio = new Planificacion_Servicio__c();
                		  planServicio.Name = reglaTarget.Tipo_mantenimiento__c;
                          if (vehiculo.Concesionario_Taller__c != null) {
                              planServicio.Concesionario__c = vehiculo.Concesionario_Taller__c;
                              planServicio.Centro__c = vehiculo.Centro_Taller__c;    
                          } else {
                              planServicio.Concesionario__c = vehiculo.Concesionario__c;
                              planServicio.Centro__c = vehiculo.Centro__c; 
                          }
                          planServicio.Marca__c = vehiculo.MarcaString__c;    
                          planServicio.OwnerId = cola.Id;
                		  planServicio.Vehiculo__c = vehiculo.Id;
                          planServicio.Tipo_de_venta__c = vehiculo.Tipo_de_venta__c;   
                		  planServicio.Estado__c= 'Sin asignar';
                		  planServicio.Tipo_mantenimiento__c = reglaTarget.Tipo_mantenimiento__c;
                		  planServicio.Codigo_Servicio__c = reglaTarget.Grupo_homogeneo__c;
                		  calcularFechasTarget(planServicio, vehiculo, reglaTarget , planServicioAntes);
                    }
                }
                //ITV (primera y sucesivas)
             	else if (reglaTarget.Grupo_homogeneo__c.contains('FICT05')){
                    // 1) Si no tengo planificación anterior y es primera inspeccion y el vehiculo no alcanzo la antiguedad en meses de 
                    //    finalizar el target
                    // 2) Si tengo planificación anterior y los kms de realización del servicio son nulos y es primera inspeccion y el 
                    // vehiculo no alcanzo la antiguedad en meses de finalizar el target
                    // 3) Si tengo planificación anterior y los kms de realización del servicio no son nulos y es inspeccion 
                    // 
                    // En los casos 1 y 2 sigo en la primera inspección en el caso 3 una vez que tengo kms de realización ya estoy en 
                    // inspecciones consecutivas
                    // 
                    if  ((reglaTarget.Tipo_mantenimiento__c.equalsIgnoreCase('ITV turismo') &&
                          vehiculo.Homologacion__c != null &&
                          vehiculo.Homologacion__c.equalsIgnoreCase('Turismo') &&
                       (((planServicioAntes == null) &&
                         (reglaTarget.Empieza_en__c == 0) && 
                         (antiVehiculoMeses <= reglaTarget.Finaliza_en__c.intValue())) || 
                        ((planServicioAntes != null) &&
                         (planServicioAntes.Ultimos_kilometros__c == null) &&
                         (reglaTarget.Empieza_en__c == 0) && 
                         (antiVehiculoMeses <= reglaTarget.Finaliza_en__c.intValue())) ||
                        ((planServicioAntes != null) &&
                         (planServicioAntes.Ultimos_kilometros__c != null) &&
                         (reglaTarget.Empieza_en__c != 0)))) ||
                         (reglaTarget.Tipo_mantenimiento__c.equalsIgnoreCase('ITV comercial') &&
                          vehiculo.Homologacion__c != null &&
                          vehiculo.Homologacion__c.equalsIgnoreCase('Comercial') &&
                       (((planServicioAntes == null) &&
                         (reglaTarget.Empieza_en__c == 0) && 
                         (antiVehiculoMeses <= reglaTarget.Finaliza_en__c.intValue())) || 
                        ((planServicioAntes != null) &&
                         (planServicioAntes.Ultimos_kilometros__c == null) &&
                         (reglaTarget.Empieza_en__c == 0) && 
                         (antiVehiculoMeses <= reglaTarget.Finaliza_en__c.intValue())) ||
                        ((planServicioAntes != null) &&
                         (planServicioAntes.Ultimos_kilometros__c != null) &&
                         (reglaTarget.Empieza_en__c != 0))))) {
                		  planServicio = new Planificacion_Servicio__c();
                		  planServicio.Name = reglaTarget.Tipo_mantenimiento__c;
                          if (vehiculo.Concesionario_Taller__c != null) {
                              planServicio.Concesionario__c = vehiculo.Concesionario_Taller__c;
                              planServicio.Centro__c = vehiculo.Centro_Taller__c;    
                          } else {
                              planServicio.Concesionario__c = vehiculo.Concesionario__c;
                              planServicio.Centro__c = vehiculo.Centro__c; 
                          }
                          planServicio.Marca__c = vehiculo.MarcaString__c;    
                          planServicio.OwnerId = cola.Id;
                		  planServicio.Vehiculo__c = vehiculo.Id;
                          planServicio.Tipo_de_venta__c = vehiculo.Tipo_de_venta__c;   
                		  planServicio.Estado__c= 'Sin asignar';
                		  planServicio.Tipo_mantenimiento__c = reglaTarget.Tipo_mantenimiento__c;
                		  planServicio.Codigo_Servicio__c = reglaTarget.Grupo_homogeneo__c;
                		  calcularFechasTarget(planServicio, vehiculo, reglaTarget , planServicioAntes);
                    }
                }
                //Cambio de bujías
            	else if (reglaTarget.Grupo_homogeneo__c.contains('NEZ')  ||
                         reglaTarget.Grupo_homogeneo__c.contains('NZZ')) {
                    if (((vehiculo.Combustible__c != null) &&
                        (reglaTarget.Tipo_combustible__c != null) &&
                        (reglaTarget.Tipo_combustible__c.contains(vehiculo.Combustible__c))) || 
                        (vehiculo.MarcaString__c.equalsIgnoreCase('DUCATI'))) {                              
                		  planServicio = new Planificacion_Servicio__c();
                		  planServicio.Name = reglaTarget.Tipo_mantenimiento__c;
                          if (vehiculo.Concesionario_Taller__c != null) {
                              planServicio.Concesionario__c = vehiculo.Concesionario_Taller__c;
                              planServicio.Centro__c = vehiculo.Centro_Taller__c;    
                          } else {
                              planServicio.Concesionario__c = vehiculo.Concesionario__c;
                              planServicio.Centro__c = vehiculo.Centro__c; 
                          }
                          planServicio.Marca__c = vehiculo.MarcaString__c;    
                          planServicio.OwnerId = cola.Id;
                		  planServicio.Vehiculo__c = vehiculo.Id;
                          planServicio.Tipo_de_venta__c = vehiculo.Tipo_de_venta__c;   
                		  planServicio.Estado__c= 'Sin asignar';
                		  planServicio.Tipo_mantenimiento__c = reglaTarget.Tipo_mantenimiento__c;
                		  planServicio.Codigo_Servicio__c = reglaTarget.Grupo_homogeneo__c;
                		  calcularFechasTarget(planServicio, vehiculo, reglaTarget,planServicioAntes );
               	    }
            	}
                //Embrague Haldex
                else if (reglaTarget.Grupo_homogeneo__c.contains('COD')) {
                    if ((vehiculo.Transmision__c != null) &&
                        (vehiculo.Cilindrada__c != null) &&
                        (vehiculo.Cilindrada__c != 0) &&
                        (reglaTarget.Transmision__c.contains(vehiculo.Transmision__c)) &&                             
                        (vehiculo.Cilindrada__c < reglaTarget.Cilindrada__c)) {                              
                		  planServicio = new Planificacion_Servicio__c();
                		  planServicio.Name = reglaTarget.Tipo_mantenimiento__c;
                          if (vehiculo.Concesionario_Taller__c != null) {
                              planServicio.Concesionario__c = vehiculo.Concesionario_Taller__c;
                              planServicio.Centro__c = vehiculo.Centro_Taller__c;    
                          } else {
                              planServicio.Concesionario__c = vehiculo.Concesionario__c;
                              planServicio.Centro__c = vehiculo.Centro__c; 
                          }
                          planServicio.Marca__c = vehiculo.MarcaString__c;    
                          planServicio.OwnerId = cola.Id;
                		  planServicio.Vehiculo__c = vehiculo.Id;
                          planServicio.Tipo_de_venta__c = vehiculo.Tipo_de_venta__c;   
                		  planServicio.Estado__c= 'Sin asignar';
                		  planServicio.Tipo_mantenimiento__c = reglaTarget.Tipo_mantenimiento__c;
                		  planServicio.Codigo_Servicio__c = reglaTarget.Grupo_homogeneo__c;
                		  calcularFechasTarget(planServicio, vehiculo, reglaTarget,planServicioAntes );
               		}
            	}
                //Aceite cajas DSG
                else if (reglaTarget.Grupo_homogeneo__c.contains('COB')) {
                    if ((vehiculo.Caja_de_cambios__c != null) &&
                         reglaTarget.Caja_Cambios__c.contains(vehiculo.Caja_de_cambios__c)) {                              
                		  planServicio = new Planificacion_Servicio__c();
                		  planServicio.Name = reglaTarget.Tipo_mantenimiento__c;
                          if (vehiculo.Concesionario_Taller__c != null) {
                              planServicio.Concesionario__c = vehiculo.Concesionario_Taller__c;
                              planServicio.Centro__c = vehiculo.Centro_Taller__c;    
                          } else {
                              planServicio.Concesionario__c = vehiculo.Concesionario__c;
                              planServicio.Centro__c = vehiculo.Centro__c; 
                          }
                          planServicio.Marca__c = vehiculo.MarcaString__c;    
                          planServicio.OwnerId = cola.Id;
                		  planServicio.Vehiculo__c = vehiculo.Id;
                          planServicio.Tipo_de_venta__c = vehiculo.Tipo_de_venta__c;   
                		  planServicio.Estado__c= 'Sin asignar';
                		  planServicio.Tipo_mantenimiento__c = reglaTarget.Tipo_mantenimiento__c;
                		  planServicio.Codigo_Servicio__c = reglaTarget.Grupo_homogeneo__c;
                		  calcularFechasTarget(planServicio, vehiculo, reglaTarget,planServicioAntes );
               		}
            	}
                //Vencimiento Garantía
                else if (reglaTarget.Tipo_mantenimiento__c.equalsIgnoreCase('Vencimiento de garantía')) {
                    Date finGarantia; 
                    if (vehiculo.Fecha_fin_garantia__c != null) {
                          finGarantia = vehiculo.Fecha_fin_garantia__c.date();
                    }
                    if ((vehiculo.Fecha_fin_extension_garantia__c != null) && ((finGarantia == null) || 
                        (finGarantia < vehiculo.Fecha_fin_extension_garantia__c.date()))) {
                          finGarantia = vehiculo.Fecha_fin_extension_garantia__c.date();
                    } 
                    if ((vehiculo.Fecha_fin_garantia_VO__c != null) && ((finGarantia == null) || 
                        (finGarantia < vehiculo.Fecha_fin_garantia_VO__c.date()))) {
                          finGarantia = vehiculo.Fecha_fin_garantia_VO__c.date();
                    } 
                    if ((finGarantia != null) &&
                        (finGarantia > Date.today())) { 
                          planServicio = new Planificacion_Servicio__c();
                		  planServicio.Name = reglaTarget.Tipo_mantenimiento__c;
                          if (vehiculo.Concesionario_Taller__c != null) {
                              planServicio.Concesionario__c = vehiculo.Concesionario_Taller__c;
                              planServicio.Centro__c = vehiculo.Centro_Taller__c;    
                          } else {
                              planServicio.Concesionario__c = vehiculo.Concesionario__c;
                              planServicio.Centro__c = vehiculo.Centro__c; 
                          }
                          planServicio.Marca__c = vehiculo.MarcaString__c;    
                          planServicio.OwnerId = cola.Id;
                		  planServicio.Vehiculo__c = vehiculo.Id;
                          planServicio.Tipo_de_venta__c = vehiculo.Tipo_de_venta__c;   
                		  planServicio.Estado__c= 'Sin asignar';
                		  planServicio.Tipo_mantenimiento__c = reglaTarget.Tipo_mantenimiento__c;
                		  planServicio.Codigo_Servicio__c = reglaTarget.Grupo_homogeneo__c;
                          planServicio.Fecha_Mantenimiento__c = finGarantia;
                          if (reglaTarget.Dias_antes_email_sms__c != null) {
                              Decimal diasAntesEmail = reglaTarget.Dias_antes_email_sms__c * -1;
                              planServicio.Fecha_Aviso_Email_SMS__c = planServicio.Fecha_Mantenimiento__c.addDays(diasAntesEmail.intValue());
                              planServicio.Fecha_Aviso_Email__c = planServicio.Fecha_Mantenimiento__c.addDays(diasAntesEmail.intValue());
                              planServicio.Fecha_Aviso_SMS__c = planServicio.Fecha_Mantenimiento__c.addDays(diasAntesEmail.intValue());
                              
                              
                          }
                          if (reglaTarget.Dias_antes_llamada__c != null) {
                              Decimal diasAntesCall = reglaTarget.Dias_antes_llamada__c * -1;
                              planServicio.Fecha_Aviso_Llamada__c = planServicio.Fecha_Mantenimiento__c.addDays(diasAntesCall.intValue());
                          }
               		}
            	}
            	else{
            	    planServicio = new Planificacion_Servicio__c();
                	planServicio.Name = reglaTarget.Tipo_mantenimiento__c;
                    if (vehiculo.Concesionario_Taller__c != null) {
                        planServicio.Concesionario__c = vehiculo.Concesionario_Taller__c;
                        planServicio.Centro__c = vehiculo.Centro_Taller__c;    
                    } else {
                        planServicio.Concesionario__c = vehiculo.Concesionario__c;
                        planServicio.Centro__c = vehiculo.Centro__c; 
                    }
                    planServicio.Marca__c = vehiculo.MarcaString__c;    
                    planServicio.OwnerId = cola.Id;
            	    planServicio.Vehiculo__c = vehiculo.Id;
                    planServicio.Tipo_de_venta__c = vehiculo.Tipo_de_venta__c;   
            	    planServicio.Estado__c= 'Sin asignar';
            	    planServicio.Tipo_mantenimiento__c = reglaTarget.Tipo_mantenimiento__c;
            	    planServicio.Codigo_Servicio__c = reglaTarget.Grupo_homogeneo__c;
            	    calcularFechasTarget(planServicio, vehiculo, reglaTarget,planServicioAntes );
            	}
            }
            if(planServicio != null){
                planServiciosUpsert.add(planServicio);
            }
        }
        return planServiciosUpsert;
    }
    
    private static void calcularFechasTarget(Planificacion_Servicio__c planServicio, Vehiculo__c vehiculo, Regla_Target__c reglaTarget, Planificacion_Servicio__c ultimaPlanServicio){
        system.debug('planServicio: '+planServicio); 
        system.debug('vehiculo: '+vehiculo); 
        system.debug('reglaTarget: '+reglaTarget); 
        system.debug('ultimaPlanServicio: '+ultimaPlanServicio); 
        // si ya se realizo el mantenimiento, se calcula desde esos Kms y fecha de realización 
        if (ultimaPlanServicio != null && ultimaPlanServicio.Fecha_ultima_realizacion__c != null &&
            vehiculo.kms_diarios__c != null && vehiculo.kms_diarios__c != 0){
            system.debug('reglaTarget.Kilometros__c: '+reglaTarget.Kilometros__c); 
            system.debug('vehiculo.kms__c: '+vehiculo.kms__c); 
            system.debug('ultimaPlanServicio.Ultimos_kilometros__c: '+ultimaPlanServicio.Ultimos_kilometros__c);
            Decimal kmsEstimar = reglaTarget.Kilometros__c - (vehiculo.kms__c - ultimaPlanServicio.Ultimos_kilometros__c);
            system.debug('kmsEstimar: '+kmsEstimar);
            system.debug('vehiculo.kms_diarios__c: '+vehiculo.kms_diarios__c);
            Decimal diasKmsEstimar = kmsEstimar.divide(vehiculo.kms_diarios__c,0,System.RoundingMode.UP);     
            Date fechaEstimadaKms = vehiculo.Fecha_actualizacion_kms__c.date().addDays(diasKmsEstimar.intValue());
            Date fechaEstimadatiempo = ultimaPlanServicio.Fecha_ultima_realizacion__c.addMonths(reglaTarget.Meses__c.intValue());
            if (fechaEstimadaKms > fechaEstimadatiempo) {
                planServicio.Fecha_Mantenimiento__c = fechaEstimadatiempo;
            } else {
                planServicio.Fecha_Mantenimiento__c = fechaEstimadaKms;
            }
            system.debug('1 kmsEstimar: '+kmsEstimar);
            system.debug('1 diasKmsEstimar: '+diasKmsEstimar);
            system.debug('1 fechaEstimadaKms: '+fechaEstimadaKms);
            system.debug('1 fechaEstimadatiempo: '+fechaEstimadatiempo);
        } else {
            // si aun no se realizo el mantenimiento, pero ya tenemos kms en el vehículo, se puede estima por tiempo y kms 
            // desde la fecha de matriculación del vehículo  
            if (vehiculo.kms_diarios__c != null && vehiculo.kms_diarios__c != 0 ){
                Decimal kmsEstimar = reglaTarget.Kilometros__c - vehiculo.kms__c;
                Decimal diasKmsEstimar = kmsEstimar.divide(vehiculo.kms_diarios__c,0,System.RoundingMode.UP);     
                Date fechaEstimadaKms = vehiculo.Fecha_actualizacion_kms__c.date().addDays(diasKmsEstimar.intValue());
                Date fechaEstimadatiempo = vehiculo.Fecha_primera_matriculacion__c.date().addMonths(reglaTarget.Meses__c.intValue());
                if (fechaEstimadaKms > fechaEstimadatiempo) {
                    planServicio.Fecha_Mantenimiento__c = fechaEstimadatiempo;
                } else {
                    planServicio.Fecha_Mantenimiento__c = fechaEstimadaKms;
                }
                system.debug('2 kmsEstimar: '+kmsEstimar);
                system.debug('2 diasKmsEstimar: '+diasKmsEstimar);
                system.debug('2 fechaEstimadaKms: '+fechaEstimadaKms);
                system.debug('2 fechaEstimadatiempo: '+fechaEstimadatiempo);
            } else {
                // si aun no se realizo el mantenimiento y no tengo kms en el vehículo, solo se puede estimar 
                // por tiempo desde la fecha de matriculación del vehículo  
                Date fechaEstimadatiempo = vehiculo.Fecha_primera_matriculacion__c.date().addMonths(reglaTarget.Meses__c.intValue());
                planServicio.Fecha_Mantenimiento__c = fechaEstimadatiempo;
                system.debug('3 fechaEstimadatiempo: '+fechaEstimadatiempo);
            }
        } 
            
        if (reglaTarget.Dias_antes_email_sms__c != null) {
            Decimal diasAntesEmail = reglaTarget.Dias_antes_email_sms__c * -1;
            planServicio.Fecha_Aviso_Email_SMS__c = planServicio.Fecha_Mantenimiento__c.addDays(diasAntesEmail.intValue());
            planServicio.Fecha_Aviso_Email__c = planServicio.Fecha_Mantenimiento__c.addDays(diasAntesEmail.intValue());
            planServicio.Fecha_Aviso_SMS__c = planServicio.Fecha_Mantenimiento__c.addDays(diasAntesEmail.intValue());
            
        }
        if (reglaTarget.Dias_antes_llamada__c != null) {
            Decimal diasAntesCall = reglaTarget.Dias_antes_llamada__c * -1;
            planServicio.Fecha_Aviso_Llamada__c = planServicio.Fecha_Mantenimiento__c.addDays(diasAntesCall.intValue());
        }
        if (ultimaPlanServicio != null) {        
            planServicio.Fecha_ultima_realizacion__c = ultimaPlanServicio.Fecha_ultima_realizacion__c != null?ultimaPlanServicio.Fecha_ultima_realizacion__c:null;
            planServicio.Ultimos_kilometros__c = ultimaPlanServicio.Ultimos_kilometros__c != null?ultimaPlanServicio.Ultimos_kilometros__c:null;
        }
    } 
}