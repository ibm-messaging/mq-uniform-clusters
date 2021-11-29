/*
* (c) Copyright IBM Corporation 2021
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

/**********************************************************************/
/* Utility functions and macros for request reply rebalancing samples */
/**********************************************************************/

#include <stdio.h>
#include <cmqc.h>
#include "utils.h"

/********************************************************************/
/* EventHandler - handle/record reconnect events                    */
/********************************************************************/
void EventHandler (
   MQHCONN hcon, PMQMD md, PMQGMO gmo, PMQBYTE buf, PMQCBC cbc)
{
   MQSTS sts = {MQSTS_DEFAULT};
   MQLONG cc, rc;
   PMQCHAR  msg;
   char ts[20];
   getTimeStamp(ts);

   switch(cbc->Reason)
   {
      case MQRC_CONNECTION_BROKEN:
         printf("%s EventHandler: Connection Broken\n",ts);
         break;

      case MQRC_RECONNECTING:
         MQSTAT(hcon, MQSTAT_TYPE_RECONNECTION, &sts, &cc, &rc);

         if(cc == MQCC_FAILED)
         {
           printf("%s EventHandler: MQSTAT(1) failed rc=%d\n",ts, rc);
         }
         else if ((sts.ObjectQMgrName[0] != '\0')
              && (sts.ObjectQMgrName[0] != ' '))
         {
            msg = "%s EventHandler: MQRC_RECONNECTING, Reason(%d), Qmgr(%s), Delay(%dms)\n";
            stripWhiteSpace(sts.ObjectQMgrName);
            printf(msg, ts, sts.Reason, sts.ObjectQMgrName,
               cbc->ReconnectDelay
            );
         }
         else
         {
            msg = "%s EventHandler: MQRC_RECONNECTING Reason(%d), Delay(%dms)\n";
            printf(msg, ts, sts.Reason, cbc->ReconnectDelay);
         }
         break;

      case MQRC_RECONNECTED:
         MQSTAT(hcon, MQSTAT_TYPE_RECONNECTION, &sts, &cc, &rc);

         if(cc == MQCC_FAILED)
         {
           printf("%s EventHandler: MQSTAT(2) failed rc=%d\n",ts, rc);
         }
         else if ((sts.ObjectName[0] != '\0')
              && (sts.ObjectName[0] != ' '))
         {
            stripWhiteSpace(sts.ObjectName);
            printf("%s EventHandler: MQRC_RECONNECTED %s\n",ts, sts.ObjectName);
         }
         else
         {
            printf("%s EventHandler: MQRC_RECONNECTED Reason(%d)\n",ts, sts.Reason);
         }
         break;

      case MQRC_RECONNECT_FAILED:
         printf("%s EventHandler : Reconnection failed\n",ts);
         break;

      default:
         printf("%s EventHandler : Reason(%d)\n",ts,cbc->Reason);
         break;
  }

   fflush(stdout);
}

/* Print MQI call results to stdout for log/diags */
void printResults(PMQCHAR mqi, PMQLONG cc, PMQLONG rc)
{
   char   ts[20];
   getTimeStamp(ts);
   PMQCHAR s = "%s %s completed with compCode(%d) reasonCode(%d)\n";

   printf(s, ts, mqi, *cc, *rc);
   fflush(stdout);
}

/* Get time stamp string for logging purposes      */
PMQCHAR  getTimeStamp(PMQCHAR buf)
{
   time_t Now;
   PMQCHAR  pTime;
   time(&Now);
   pTime = ctime(&Now);
   sprintf(buf,"%8.8s:",pTime+11);
   return buf;
}

/* Strip white space from string */
PMQCHAR  stripWhiteSpace(PMQCHAR buf)
{
   int i;

   for(i = 0 ; i < MQ_Q_MGR_NAME_LENGTH ; i ++)
   {
      if( 0 == buf[i] )
         break;
      if( ' ' == buf[i] )
         buf[i] = 0 ;
   }

   return buf;
}
/* Print generated BNO structure to stdout */
void dumpBNO(PMQBNO pBNO)
{
    printf("MQBNO Struct\n{\n");
    printf("  BVersion: %d\n", pBNO->Version);
    printf("  BStrucId: %s\n", pBNO->StrucId);
    printf("  Timeout:  %d\n", pBNO->Timeout);
    printf("  BOptions: %d\n", pBNO->Options);
    printf("  Appltype: %d\n", pBNO->ApplType);
    printf("}\n\n");
    fflush(stdout);
}

/* Print generated CNO structure to stdout */
void dumpCNO(MQCNO cno)
{
    printf("\nMQCNO Struct\n{\n");
    printf("  StrucId: %s\n", cno.StrucId);
    printf("  Version: %d\n", cno.Version);
    printf("  CCDTUrlLength: %d\n", cno.CCDTUrlLength);
    printf("  CCDTUrlOffset: %d\n", cno.CCDTUrlOffset);
    printf("  CCDTUrlPtr: %p\n", cno.CCDTUrlPtr);
    printf("  ClientConnOffset: %d\n", cno.ClientConnOffset);
    printf("  ClientConnPtr: %p\n", cno.ClientConnPtr);
    printf("  ConnectionId: %p\n", cno.ConnectionId);
    printf("  ConnTag: %p\n", cno.ConnTag);
    printf("  Options: %d\n", cno.Options);
    printf("  Reserved: %p\n", cno.Reserved);
    printf("  Reserved2: %p\n", cno.Reserved2);
    printf("  SecurityParmsOffset: %d\n", cno.SecurityParmsOffset);
    printf("  SecurityParmsPtr: %p\n", cno.SecurityParmsPtr);
    printf("  SSLConfigOffset: %d\n", cno.SSLConfigOffset);
    printf("  SSLConfigPtr: %p\n", cno.SSLConfigPtr);
    printf("  BalanceParmsPtr: %p\n", cno.BalanceParmsPtr);
    printf("  BalanceParmsOffset: %d\n", cno.BalanceParmsOffset);
    printf("}\n\n");
    fflush(stdout);
}

