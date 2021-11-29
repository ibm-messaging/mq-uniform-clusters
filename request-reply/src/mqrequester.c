/*
* (c) Copyright IBM Corporation 2018
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

/********************************************************************/
/* Example 'request response' application for Uniform Cluster       */
/* rebalancing demonstration.                                       */
/*                                                                  */
/* This application repeatedly sends 'request' messages and listens */
/* on a dynamic reply queue for responses.                          */
/*                                                                  */
/*    Required options:                                             */
/*    1) Queue manager name                                         */
/*    2) target queue                                               */
/*    3) source queue                                               */
/*                                                                  */
/*	  Option descriptions:                                           */
/*                                                                  */
/*       -m  : Queue Manager name                                   */
/*       -t  : target queue for put                                 */
/*       -s  : Model queue for get (replies)                        */
/*       -E  : MQPUT message expiry                                 */
/*               N.B. - if not 'unlimited', corresponding GET       */
/*               with wait will use same timeout.                   */
/*                                                                  */
/********************************************************************/

/********************************************************************/
/* Includes                                                         */
/********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <cmqc.h>
#include "utils.h"

/********************************************************************/
/* Structures and constants                                         */
/********************************************************************/
typedef int BOOL;
#define TRUE  1
#define FALSE 0

/* Global Options */
BOOL bVerbose;
MQLONG messageExpiry;

/* Helper prototypes */
void dumpOpts();
int setBnoTimeout(PMQCHAR optarg);

/********************************************************************/
/* FUNCTION: main                                                   */
/* PURPOSE : Main program entry point                               */
/********************************************************************/
int main(int argc, PPMQCHAR argv)
{
   MQCNO    cno         = {MQCNO_DEFAULT};
   MQBNO    bno         = {MQBNO_DEFAULT};
   MQHCONN  hcon        = MQHC_UNUSABLE_HCONN;
   MQMD     put_md      = {MQMD_DEFAULT};
   MQOD     objDesc     = {MQOD_DEFAULT};

   /* Queue Handles */
   MQHOBJ   trgQ_hobj   = MQHO_UNUSABLE_HOBJ;
   MQHOBJ   srcHobj     = MQHO_UNUSABLE_HOBJ;

   MQLONG   cc = 0, rc = 0;

   char qmgrName[50]    = "";
   char srcQ[50]        = "";
   char trgQ[50]        = "";
   char ts[20]          = "";

   /* Default options */
   bVerbose             = FALSE;
   messageExpiry        = 300;                        /* 30 seconds */

   /*---------------------------------------------------------------*/
   /* Parse and validate parameter arguments                        */
   /*---------------------------------------------------------------*/
   int argIndex;

   for (argIndex = 0; argIndex < argc; argIndex++)
   {
      if (argv[argIndex][0] == '-' && !isdigit(argv[argIndex][1]))
      {
         PMQCHAR opt    = &argv[argIndex][1];
         PMQCHAR optarg = &argv[argIndex][3];

         switch (*opt)
         {
            case 'm': strncpy(qmgrName, optarg, MQ_Q_MGR_NAME_LENGTH);
                      break;
            case 's': strncpy(srcQ, optarg, MQ_Q_NAME_LENGTH);
                      break;
            case 't': strncpy(trgQ, optarg, MQ_Q_NAME_LENGTH);
                      break;
            case 'T': bno.Timeout = setBnoTimeout(optarg);
                      break;
            case 'E': messageExpiry = atoi(optarg);
                      if(messageExpiry == 0) messageExpiry = MQEI_UNLIMITED;
                      break;
            default:
               fprintf(stderr, "Unrecognised option %s.\n", opt);
               exit(1);
         }
      }
   }

   if (!qmgrName[0])
   {
      fprintf(stderr, "Please enter a queue manager name\n");
      exit(1);
   }

   if (!srcQ[0] || !trgQ[0])
   {
      fprintf(
         stderr, "Please enter source and target queue names\n"
      );
      exit(1);
   }

   /*---------------------------------------------------------------*/
   /* Connect to QM                                                 */
   /*---------------------------------------------------------------*/

   /* Build our Balancing options structure (BNO)                   */
   /* This tells the queue manager which application pattern we     */
   /* are using (request reply) and could contain other information */
   /* such as the timeout.  We leave that as default to allow the   */
   /* deploying adminstrator to configure (see mqclient.ini)        */
   bno.ApplType = MQBNO_BALTYPE_REQREP;
   
   /* Point to our Balancing Options structure for the connect      */
   cno.Version = MQCNO_VERSION_8;
   cno.Options |= MQCNO_RECONNECT;
   cno.BalanceParmsPtr = &bno;
   /* We don't modify our app name here so will inherit default     */
   /* (the name of the built executable, 'requester')               */

   /* Output key structures before connect if requested             */
   if(bVerbose)
   { 
     dumpOpts();
     dumpCNO(cno);
     if (cno.BalanceParmsPtr)
     {
       dumpBNO(cno.BalanceParmsPtr);
     }
   }
   
   MQCONNX(qmgrName, &cno, &hcon, &cc, &rc);
   printResults("MQCONNX", &cc, &rc);
   if(cc == MQCC_FAILED) exit(1);

   /*---------------------------------------------------------------*/
   /* Register an Event Handler to report reconnect events          */
   /*---------------------------------------------------------------*/
   MQCBD  ev_cbd             = {MQCBD_DEFAULT};
   ev_cbd.Options            = MQCBDO_EVENT_CALL;
   ev_cbd.CallbackType       = MQCBT_EVENT_HANDLER;
   ev_cbd.CallbackFunction   = &EventHandler;

   MQCB(hcon, MQOP_REGISTER, &ev_cbd, MQHO_UNUSABLE_HOBJ, NULL, NULL,
        &cc, &rc);
   printResults("MQCB:Register event handler", &cc, &rc);

   if(cc == MQCC_FAILED) exit(1);

   /*---------------------------------------------------------------*/
   /* Open our input and output queues (deliberately do this outside*/
   /* main loop, we expect handles to survive if we are rebalanced) */
   /*---------------------------------------------------------------*/
   /* Open queue for put */
   memcpy(objDesc.ObjectName, trgQ, sizeof(objDesc.ObjectName));
   MQLONG   openTrgOpts = MQOO_OUTPUT + MQOO_FAIL_IF_QUIESCING;
   MQOPEN(hcon, &objDesc, openTrgOpts, &trgQ_hobj, &cc, &rc);
   printResults("MQOPEN (target)", &cc, &rc);
   if(cc == MQCC_FAILED) exit(1);

   /* Open queue for get  */
   memcpy(objDesc.ObjectName, srcQ, sizeof(objDesc.ObjectName));
   MQLONG openSrcOpts = MQOO_INPUT_SHARED + MQOO_FAIL_IF_QUIESCING;
   MQOPEN(hcon, &objDesc, openSrcOpts, &srcHobj, &cc, &rc);
   printResults("MQOPEN (src)", &cc, &rc);
   if(cc == MQCC_FAILED) exit(1);
   printf("Using dynamic queue %.48s for replies\n", objDesc.ObjectName);

   /*---------------------------------------------------------------*/
   /* Prepare PUT and GET structures                                */
   /*---------------------------------------------------------------*/
   MQPMO  pmo = {MQPMO_DEFAULT};
   put_md.Expiry = messageExpiry;
   put_md.Persistence = MQPER_NOT_PERSISTENT;

   /* Set PUT message body */
   memcpy(put_md.Format, MQFMT_STRING, (size_t)MQ_FORMAT_LENGTH);
   PMQCHAR putMsgBuf = "Request message body";
   MQLONG putMsgLen = (MQLONG)strlen(putMsgBuf);

   /* Set PUT options  */
   pmo.Options = MQPMO_FAIL_IF_QUIESCING
               | MQPMO_NEW_CORREL_ID
               | MQPMO_NEW_MSG_ID
               | MQPMO_NO_SYNCPOINT;

   MQMD  get_md   = {MQMD_DEFAULT};
   MQGMO gmo      = {MQGMO_DEFAULT};
   MQBYTE msgBuf[65536];
   MQLONG bufLen = sizeof(msgBuf) - 1;
   MQLONG msgLen = 0;

   /* Set GET options */
   gmo.Options = MQGMO_CONVERT
               | MQGMO_FAIL_IF_QUIESCING
               | MQGMO_WAIT
               | MQGMO_NO_SYNCPOINT;

   /* We'll wait for responses until the request expires, plus a    */
   /* couple of seconds to avoid 'racing' the responder app         */
   if(messageExpiry == MQEI_UNLIMITED)
     gmo.WaitInterval = MQWI_UNLIMITED;
   else
     gmo.WaitInterval = (messageExpiry * 100) + 2000;

   /*---------------------------------------------------------------*/
   /* MAIN LOOP                                                     */
   /* - put message to trgQ                                         */
   /* - get (with wait) message from srcQ                           */
   /*---------------------------------------------------------------*/
   while(TRUE)
   {
     /* clear both MQMDs 'just in case' */
     get_md.Version = MQMD_CURRENT_VERSION;
     memcpy(get_md.MsgId, MQMI_NONE, sizeof(get_md.MsgId));
     memcpy(get_md.CorrelId, MQCI_NONE, sizeof(get_md.CorrelId));
     get_md.Encoding       = MQENC_NATIVE;
     get_md.CodedCharSetId = MQCCSI_Q_MGR;

     put_md.Version = MQMD_CURRENT_VERSION;
     memcpy(put_md.MsgId, MQMI_NONE, sizeof(put_md.MsgId));
     memcpy(put_md.CorrelId, MQCI_NONE, sizeof(put_md.CorrelId));
     memcpy(put_md.ReplyToQ, objDesc.ObjectName, sizeof(put_md.ReplyToQ));

     /* Put message */
     MQPUT(hcon, trgQ_hobj, &put_md, &pmo, putMsgLen, putMsgBuf, &cc, &rc);
     printResults("MQPUT", &cc, &rc);
     if(cc == MQCC_FAILED) exit(1);

     getTimeStamp(ts);
     printf("%s MQPUT put message: <%s>\n", ts, putMsgBuf);
     fflush(stdout);

     /*-----------------------------------------------------------*/
     /* Get message                                               */
     /*-----------------------------------------------------------*/
     printf("Entering get....\n");
     fflush(stdout);

         MQGET(hcon, srcHobj, &get_md,
               &gmo, bufLen, msgBuf, &msgLen,
               &cc, &rc);
         printResults("MQGET", &cc, &rc);
         if(cc == MQCC_FAILED)
         {
           switch(rc)
           {
             case MQRC_NO_MSG_AVAILABLE:
               /* May be expected depending on scenario */
               printf("No response message received within expiry\n");
               break;
             default:
               /* No other errors expected */
               exit(1);
           }
         }
         else
         {
           printf("Message Body: <%s>\n", msgBuf);
           fflush(stdout);
         }

     /* Simulate some 'processing' time - presumably we are doing      */
     /* something with the response and/or preparing next request.     */
     /* Why does this sample do this?                                  */
     /* This is the most likely point for a rebalance to be processed  */
     /* and ensuring this occurs before a new request has been sent    */
     /* helps make the demonstration scenario clearer (as well as      */
     /* being the most likely 'real world' behaviour.)  If in reality  */
     /* a new request had started before rebalancing could take effect */
     /* then the application instance might be forced to back out or   */
     /* a single request might be lost, depending on use of syncpoint  */
     /* and message persistence.                                       */
     msSleep(1000);
   }
   /*-----------------------------------------------------------*/
   /* END OF MAIN LOOP                                          */
   /*-----------------------------------------------------------*/

   /* Close target queue */
   MQLONG closeOpts = MQCO_NONE;
   MQCLOSE(hcon, &trgQ_hobj, closeOpts, &cc, &rc);
   printResults("MQCLOSE (trg)", &cc, &rc);

   /* Close source queue */
   MQCLOSE(hcon, &srcHobj, closeOpts, &cc, &rc);
   printResults("MQCLOSE (src)", &cc, &rc);

   /* Disconnect from QM */
   if(hcon != MQHC_UNUSABLE_HCONN)
   {
     MQLONG cc, rc;
     MQDISC(&hcon, &cc, &rc);
     printResults("MQDISC", &cc, &rc);

     if(cc == MQCC_FAILED)
        exit(1);
    }

   exit(0);
 }


/* Convert constant names to values for BNO timeout */
int setBnoTimeout(PMQCHAR optarg)
{
   if ( strcmp(optarg,"MQBNO_TIMEOUT_AS_DEFAULT"  ) == 0 )
      return MQBNO_TIMEOUT_AS_DEFAULT;
   else if ( strcmp(optarg,"MQBNO_TIMEOUT_IMMEDIATE") == 0 )
      return MQBNO_TIMEOUT_IMMEDIATE;
   else if ( strcmp(optarg,"MQBNO_TIMEOUT_NEVER" ) == 0 )
      return MQBNO_TIMEOUT_NEVER;
   else
      return atoi(optarg);
}


/* Print additional options supplied to stdout */
void dumpOpts()
{
    printf("\nControl options:\n");
    printf("  Messages PUT with expiry %d (10ths of second)\n", messageExpiry);
    printf("\n");
    fflush(stdout);
}



