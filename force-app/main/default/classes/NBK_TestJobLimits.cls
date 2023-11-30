/*-----------------------------------------------------------------------------------------
     Apex Class:        NBK_TestJobLimits
     Created Date:      13/05/2021
     Author:            davidmartinez
------------------------------------------------------------------------------------------*/

global class NBK_TestJobLimits implements Schedulable {


    global void execute(SchedulableContext sc) {
        System.debug('### NBK_TestJobLimits - execute() - start');

        System.debug('### NBK_TestJobLimits - execute() - end');
    }

}