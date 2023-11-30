public class DataValidations {
    /*
	* Checks if input and regular expression match
	*/
	public static Boolean checkRegex(String regex, String input) {
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(input);
        
        if (!matcher.matches()) {
            return false;
        }
        
        return true;
    }
    
    /*
    * Validates website
    */
    public static Boolean validateWebsite(String website) {
        String websiteRegex = '^(https?:\\/\\/)?(www\\.)?([a-zA-Z0-9]+(-?[a-zA-Z0-9])*\\.)+[\\w]{2,}(\\/\\S*)?$';
        Boolean isValid = checkRegex(websiteRegex, website);

		return isValid;
    }
    
    /*
	* Clear invalid characters from phone number to get a valid number
	*/
    public static String clearPhone(String input) {
        String replaced;
        
        if (!String.isBlank(input)) {
            String regex = '[a-zA-Z]{1,}|\\-|\\s';
			replaced = input.replaceAll(regex, '');
        }
        else {
            replaced = '';
        }
    	
		return replaced;
    }
    
    /*
	* Validates phone number
	*/
    public static Boolean validatePhone(String input) {
        Boolean isValid = false;
        
        if (!String.isBlank(input) && input.length() >= 9) {
            String phoneRegex = '[0-9]{9}|\\+?[0-9]*';
        	isValid = checkRegex(phoneRegex, input);
        }
        
       	return isValid;
    }
    
    /*
	* Checks if phone number is mobile
	*/
    public static Boolean isMobile(String input) {
        Boolean isMobile = false;
        
        if (!String.isBlank(input)) {
            String regex = '(\\+34|0034)?(6|7){1}[0-9]+';
			isMobile = checkRegex(regex, input);            
        }
        
        return isMobile;
    }
    
    /*
	* Mobile phones will start with +34
	*/
    public static String transformPhone(String input) {
        String phone = input;
        String checkFirst = phone.substring(0, 1);
        String check34 = phone.substring(0, 3);
        String check0034 = phone.substring(0, 5);
                            
        if (checkFirst.equals('6') || checkFirst.equals('7') || checkFirst.equals('8') || checkFirst.equals('9')) {
        	phone = '+34' + phone;
        }
        else if (check0034.equals('00346') || check0034.equals('00347') || check0034.equals('00348') || check0034.equals('00349')) {
        	phone = '+' + phone.substring(2, phone.length());
        }
        
        return phone;
    }
    
    /*
    * Validates email
    */
    public static Boolean validateEmail(String email) {
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
        Boolean isValid = checkRegex(emailRegex, email);

		return isValid;
    }
    
    /*
    * Checks if Email from Account is duplicated
    */
    public static Boolean isDupedAccountEmail(Account cli, String email) {
        List<Account> lstEmails = [SELECT Id
                                   FROM Account
                                   WHERE Email__c = :email
                                   		OR Other_Email__c = :email 
                                   		OR PersonEmail = :email
                                   		OR OtherEmail__pc = :email];
        
		if (!lstEmails.isEmpty()) {
			return true;
		}

		return false;
    }
    
    /*
    * Capitalize a string (word or sentence)
    */
    public static String capitalizeString(String input) {
        system.debug('inpput');
        if (!String.isBlank(input)) {
            String normalized = '';
            List<String> words = input.normalizeSpace().split(' ');
    		system.debug('words:'+ words);
            for(integer i =0;i<words.size();i++){
            	String w = words[i]; 
            	normalized += w.substring(0, 1).toUpperCase() + w.substring(1, w.length()).toLowerCase();
        		system.debug('i:'+ i);
                if (i!=words.size()-1) {
                    normalized += ' ';
                } 
                system.debug('normalized: '+normalized);
            }
            
            return normalized;
    	}
        
        return '';
    }
    
    /*
    * Validate Documento
    */
    public static void validateDocumento(Account cli, Pais__c country) {
        // Si el documento es vacío o un guión, se ponen ambos tipos de documento como vacíos
        if (String.isBlank(cli.Documento__c) || cli.Documento__c == '-') {
            cli.Documento__c = null;
            cli.Tipo_de_documento_empresa__c = null;
            cli.Tipo_de_documento_cuenta_personal__c = null;
        }
        else {
            // Si es una cuenta empresa, mirar el tipo de documento de la empresa
            if (!cli.isPersonAccount) {
                // Si el tipo de documento de la empresa no es VATId ni OtherCountryVATId, mirar el país
                if (!Label.docType_VATId.equalsIgnoreCase(cli.Tipo_de_documento_empresa__c)
                    && !Label.docType_OtherCountryVATId.equalsIgnoreCase(cli.Tipo_de_documento_empresa__c)) {
                    // Si el país es 'ES', poner el tipo de documento de la empresa como VATId, si no, OtherCountryVATId
                    if (country != null  && country.ISO_31661_alfa2__c == Label.codeES) {
                        cli.Tipo_de_documento_empresa__c = Label.docType_VATId;
                    }
                    else {
                        cli.Tipo_de_documento_empresa__c = Label.docType_OtherCountryVATId;
                    }
                }
                
                cli.Tipo_de_documento_cuenta_personal__c = null;
            }
            else {
                // Si es una cuenta personal, mirar si el tipo de documento es 'None' o vacío y, si lo es, mirar el país
                // Si el tipo de documento no es ninguno de los valores del Picklist, poner a nulo
                if (String.isBlank(cli.Tipo_de_documento_cuenta_personal__c) || Label.docType_None.equalsIgnoreCase(cli.Tipo_de_documento_cuenta_personal__c)) {
                    // Si el país es 'ES', poner el tipo de documento de la persona como 'VATId', si no, 'VATIdForForeigners'
                    if (country.ISO_31661_alfa2__c == Label.codeES) {
                        cli.Tipo_de_documento_cuenta_personal__c = Label.docType_VATId;
                    }
                    else {
                        cli.Tipo_de_documento_cuenta_personal__c = Label.docType_VATIdForForeigners;
                    }
                }
                else if (!Label.docType_VATId.equalsIgnoreCase(cli.Tipo_de_documento_cuenta_personal__c) && !Label.docType_VATIdForForeigners.equalsIgnoreCase(cli.Tipo_de_documento_cuenta_personal__c) && !Label.docType_Passport.equalsIgnoreCase(cli.Tipo_de_documento_cuenta_personal__c) && !Label.docType_OtherCountryVATId.equalsIgnoreCase(cli.Tipo_de_documento_cuenta_personal__c)) {
                    cli.Tipo_de_documento_cuenta_personal__c = null;
                }
                
                System.debug(cli.Tipo_de_documento_cuenta_personal__c);
                
                cli.Tipo_de_documento_empresa__c = null;
            }
        }
    }
    
    /*
    * Validate Picklist values
    */
    public static Boolean validatePicklistValues(String obj, String field, String input) {
        if (String.isBlank(obj) || String.isBlank(field) || String.isBlank(input)) {
            return false;
        }
        
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(obj);
        Map<String, SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        Schema.SobjectField objectField = fieldMap.get(field);
        Schema.DescribeFieldResult fieldResult = objectField.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : ple) {
            if (entry.getValue().equalsIgnoreCase(input)) {
                return true;
            }
        }
        
        return false;
    }
    
    /*
    * Validate Decimal number
    */
    public static Boolean isDecimal(String num) {
        if (!String.isBlank(num) && checkRegex('^[-+]?\\d+(\\.\\d+)?$', num)) {
            return true;
        }
        
        return false;
    }
}