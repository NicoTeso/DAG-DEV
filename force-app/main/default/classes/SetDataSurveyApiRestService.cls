@RestResource(urlMapping='/setDataSurvey/*')
global with sharing class SetDataSurveyApiRestService {
    @HttpPost
    global static ResponseApi setDataSurvey() {
        ResponseApi response = new ResponseApi();
        SetDataSurveyApiRestModel req = (SetDataSurveyApiRestModel) JSON.deserialize(RestContext.request.requestBody.toString(), SetDataSurveyApiRestModel.class);
        
        if (req.encuesta != null) {
            Encuesta__c survey = EncuestaGateway.getEncuestaBySid(req.encuesta.identificador);
            
            if (survey != null) {
                if (survey.Respondido__c == true) {
                    response.Status = Label.errorStatus_Error;
                    response.ErrorCode = '@CRM103';
                    response.Message = Label.errorMessageSurvey_Answered;
                }
                else {
                    if (survey.Fecha_fin_respuesta__c >= Datetime.valueOf(req.encuesta.fechaRespuesta.replace('T',' '))) {
                        survey.Fecha_respuesta_encuesta__c = Datetime.valueOf(req.encuesta.fechaRespuesta.replace('T',' '));
                        List<Respuesta_encuesta__c> lstQuestions = new List<Respuesta_encuesta__c>();
                        
                        for (SetDataSurveyApiRestModel.Pregunta q : req.encuesta.preguntas) {
                            Respuesta_encuesta__c question = new Respuesta_encuesta__c();
                            question.Encuesta__c = survey.Id;
                            question.Name = '';
                            question.Codigo_de_pregunta__c = q.codigoPregunta;
                            question.Pregunta__c = q.pregunta;
                            question.Respuesta__c = q.respuesta;
                            question.Codigo_de_la_respuesta__c = q.CodigoRespuesta;
                            question.Titulo__c = q.titulo;
                            
                            if (question.Titulo__c.equalsIgnoreCase('NonAnonymous') || question.Name.equalsIgnoreCase('e1')) {
                                survey.Anonymous__c = question.Codigo_de_la_respuesta__c;
                            }
                            
                            lstQuestions.add(question);
                        }
                        
                        survey.Respondido__c = true;
                        insert lstQuestions;
                        update survey;
                    
                        response.Status = Label.errorStatus_Success;
                        response.Message = Label.responseMessage_SuccessSurvey;
//                        response.ErrorCode = '@CRM100';
                    }
                    else {
                        response.Status = Label.errorStatus_Error;
                        response.ErrorCode = '@CRM102';
                        response.Message = Label.errorMessage_exceededDate;
                    }
                }
            }
            else {
                response.Status = Label.errorStatus_Error;
                response.ErrorCode = '@CRM104';
                response.Message = Label.errorMessage_SidNotFound;
            }
        }
        else {
            response.Status = Label.errorStatus_Error;
            response.ErrorCode = '@CRM101';
            response.Message = Label.errorMessage_SurveyEmpty;
        }
        system.debug('response:'+ response);
        return response;
   }
}