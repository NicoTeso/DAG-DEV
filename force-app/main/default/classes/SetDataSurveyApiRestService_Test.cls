@isTest
public class SetDataSurveyApiRestService_Test {
    @testSetup
    static void setup() {
        TriggersTest.activaTriggers();
        
        Concesionario__c concess = CreaObjetos.creaConcesionario('999');
        insert concess;
        
        Account accP = CreaObjetos.creaCuentaPersonal('test', 'prueba');
        Account accE = CreaObjetos.creaCuentaEmpresa('test1');
        List<Account> cuentas = new List<Account>{accP,accE};
        insert cuentas;
        
        
        Detalle_venta__c dv = new Detalle_venta__c();
        dv.Concesionario__c = concess.Id;
        dv.Fecha_de_entrega__c = Datetime.now();
        dv.Comprador__c = accP.Id;
        dv.Propietario__c = accP.Id;
       
        Gestion_encuesta__c surveyManag = new Gestion_encuesta__c();
        surveyManag.Brand__c = 'Volkswagen';
        surveyManag.Code__c = 'TestCode';
        surveyMAnag.Concesionario_encuesta__c = concess.Id;
        insert surveyManag;
        
        Encuesta__c survey = new Encuesta__c();
        survey.Cliente__c = accP.Id;
        survey.Gestion_encuesta__c = surveyManag.Id;
        survey.vin__c = 'VIN02';
        survey.Fecha_fin_respuesta__c= System.now().addDays(20);
        survey.Detalle_venta__c = dv.Id;
        insert survey;
    }
    
    @isTest
    static void InvalidJSONTest() {
        Test.startTest();
        ResponseApi res = testDoPost('{}');
        Test.stopTest();
    }
    
    @isTest
    static void InvalidSidTest() {
        Test.startTest();
        ResponseApi res = testDoPost(getStaticResourceData('JSONSetDataSurveyApiInvalidSid'));
        Test.stopTest();
    }
    
    @isTest
    static void PostTest() {
        Encuesta__c survey = [SELECT Id FROM Encuesta__c LIMIT 1];
        SetDataSurveyApiRestModel req = new SetDataSurveyApiRestModel();
        req.encuesta = new SetDataSurveyApiRestModel.Encuesta();
        req.encuesta.identificador = survey.Id;
        req.encuesta.fechaRespuesta = '2020-01-01T09:00:00Z';
        req.encuesta.preguntas = new List<SetDataSurveyApiRestModel.Pregunta>();
        SetDataSurveyApiRestModel.Pregunta q1 = new SetDataSurveyApiRestModel.Pregunta();
        q1.codigoPregunta = 'Q1';
        q1.pregunta = 'Wut?';
        q1.respuesta = 'Tuw';
        q1.codigoRespuesta = 'A1';
        q1.titulo = 'Test Q1';
        req.encuesta.preguntas.add(q1);
        SetDataSurveyApiRestModel.Pregunta q2 = new SetDataSurveyApiRestModel.Pregunta();
        q2.codigoPregunta = 'Q1';
        q2.pregunta = 'Wut?';
        q2.respuesta = 'Tuw';
        q2.codigoRespuesta = '1';
        q2.titulo = 'NonAnonymous';
        req.encuesta.preguntas.add(q2);
        
        Test.startTest();
        ResponseApi res = testDoPost(JSON.serialize(req));
        ResponseApi res2 = testDoPost(JSON.serialize(req));
        Test.stopTest();
    }
    
    private static ResponseApi testDoPost(String json) {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/setDataSurvey';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(json);
        System.debug('requestBody: ' + req.requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        return SetDataSurveyApiRestService.setDataSurvey();
    }
    
    private static String getStaticResourceData(String staticresource) {
        List<StaticResource> docs = [SELECT Id, Name, Body FROM StaticResource WHERE Name = :staticresource];
        StaticResource sr = docs.get(0);
        
        return sr.Body.toString();  
    }

    @isTest
    static void PostTest1() {
        //encuesta ya vencida
        Account cliente = CreaObjetos.creaCuentaPersonal('pruebaAudi', 'pruebaAudi');
        insert cliente;
        Concesionario__c conce = CreaObjetos.creaConcesionario('169-test');
        insert conce;
        Centro__c centro = CreaObjetos.creaCentro(conce.Id);
        Gestion_encuesta__c gEncuesta = CreaObjetos.creaGestionEncuesta('AUDI', centro.Id, conce.Id);
        insert gEncuesta;
        Encuesta__c survey1  = CreaObjetos.creaEncuesta('1', 'AUDI', cliente.Id, conce.Id, null, gEncuesta.id, 'CEM');
        survey1.Respondido__c = false;
        survey1.Fecha_fin_respuesta__c = datetime.now().addDays(-7);
        insert survey1;
        SetDataSurveyApiRestModel req = new SetDataSurveyApiRestModel();
        req.encuesta = new SetDataSurveyApiRestModel.Encuesta();
        req.encuesta.identificador = survey1.Id;
        req.encuesta.fechaRespuesta = String.valueOf(datetime.now());
        req.encuesta.preguntas = new List<SetDataSurveyApiRestModel.Pregunta>();
        SetDataSurveyApiRestModel.Pregunta q1 = new SetDataSurveyApiRestModel.Pregunta();
        q1.codigoPregunta = 'Q1';
        q1.pregunta = 'Wut?';
        q1.respuesta = 'Tuw';
        q1.codigoRespuesta = 'A1';
        q1.titulo = 'Test Q1';
        req.encuesta.preguntas.add(q1);
        SetDataSurveyApiRestModel.Pregunta q2 = new SetDataSurveyApiRestModel.Pregunta();
        q2.codigoPregunta = 'Q1';
        q2.pregunta = 'Wut?';
        q2.respuesta = 'Tuw';
        q2.codigoRespuesta = '1';
        q2.titulo = 'NonAnonymous';
        req.encuesta.preguntas.add(q2);
        
        Test.startTest();
        ResponseApi res = testDoPost(JSON.serialize(req));
        ResponseApi res2 = testDoPost(JSON.serialize(req));
        Test.stopTest();
    }
}