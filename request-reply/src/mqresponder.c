/*
* (c) Copyright IBM Corporation 2020
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
/* This application listens for  'request' messages on a specified  */
/* queue and sends responses to replyToQueue after short delay      */
/*                                                                  */
/*    Required options:                                             */
/*    1) Queue manager name                                         */
/*    2) source queue                                               */
/*                                                                  */
/*	  Option descriptions:                                           */
/*                                                                  */
/*       -m  : Queue Manager name                                   */
/*       -s  : Model queue for get (replies)                        */
/*       -d  : Delay                                                */
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
MQLONG delay;

/* Helper prototypes */
void dumpOpts();

/********************************************************************/
/* FUNCTION: main                                                   */
/* PURPOSE : Main program entry point                               */
/********************************************************************/
int main(int argc, PPMQCHAR argv)
{
   MQMD     md          = {MQMD_DEFAULT};
   MQOD     objDesc     = {MQOD_DEFAULT};
   MQHCONN  hcon        = MQHC_UNUSABLE_HCONN;

   /* Queue Handles */
   MQHOBJ   srcHobj     = MQHO_UNUSABLE_HOBJ;

   MQLONG   cc = 0, rc = 0;

   char qmgrName[50]    = "";
   char srcQ[50]        = "";
   char ts[20]          = "";

   /* Default options */
   bVerbose             = FALSE;
   delay                = 15;                        /* 15 seconds */

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
            case 'd': delay = atoi(optarg);
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

   if (!srcQ[0])
   {
      fprintf(
         stderr, "Please enter source queue name\n"
      );
      exit(1);
   }

   /*---------------------------------------------------------------*/
   /* Connect to QM                                                 */
   /*---------------------------------------------------------------*/
   /* This application does not configure any specific BNO so       */
   /* uses all default values - as a simple responder app we are    */
   /* happy to be 'interrupted' by a rebalance at any time          */

   /* Output key structures before connect if requested             */
   if(bVerbose)
   { 
     dumpOpts();
   }
   
   MQCONN(qmgrName, &hcon, &cc, &rc);
   printResults("MQCONN", &cc, &rc);
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

   /* Open queue for get  */
   memcpy(objDesc.ObjectName, srcQ, sizeof(objDesc.ObjectName));
   MQLONG openSrcOpts = MQOO_INPUT_SHARED + MQOO_FAIL_IF_QUIESCING;
   MQOPEN(hcon, &objDesc, openSrcOpts, &srcHobj, &cc, &rc);
   printResults("MQOPEN (src)", &cc, &rc);
   if(cc == MQCC_FAILED) exit(1);

   /*---------------------------------------------------------------*/
   /* Prepare PUT and GET structures                                */
   /*---------------------------------------------------------------*/
   MQGMO gmo      = {MQGMO_DEFAULT};
   MQBYTE msgBuf[65536];
   MQLONG bufLen = sizeof(msgBuf) - 1;
   MQLONG msgLen = 0;

   /* Set GET options */
   gmo.Options = MQGMO_CONVERT
               | MQGMO_FAIL_IF_QUIESCING
               | MQGMO_WAIT
               | MQGMO_NO_SYNCPOINT;

   /* We'll wait forever for new requests */
   gmo.WaitInterval = MQWI_UNLIMITED;

   MQPMO  pmo = {MQPMO_DEFAULT};

   /* Set PUT options  */
   pmo.Options = MQPMO_FAIL_IF_QUIESCING
               | MQPMO_NEW_MSG_ID
               | MQPMO_NO_SYNCPOINT;

   /*---------------------------------------------------------------*/
   /* MAIN LOOP                                                     */
   /* - get message from source queue                               */
   /* - pause                                                       */
   /* - send response message to ReplyToQ@ReplyToQMgr               */
   /*---------------------------------------------------------------*/
   while(TRUE)
   {
     /* clear MQMD fields for next GET */
     md.Version = MQMD_CURRENT_VERSION;
     md.MsgType = MQMT_REQUEST;
     memcpy(md.MsgId, MQMI_NONE, sizeof(md.MsgId));
     memcpy(md.CorrelId, MQCI_NONE, sizeof(md.CorrelId));
     md.Encoding       = MQENC_NATIVE;
     md.CodedCharSetId = MQCCSI_Q_MGR;

     /*-----------------------------------------------------------*/
     /* Get next request message                                  */
     /*-----------------------------------------------------------*/
     printf("Entering get....\n");
     fflush(stdout);

     MQGET(hcon, srcHobj, &md,
            &gmo, bufLen, msgBuf, &msgLen,
            &cc, &rc);
     printResults("MQGET", &cc, &rc);
     if(cc == MQCC_FAILED)
     {
       /* No errors expected */
       exit(1);
     }
     else
     {
       printf("Request received: <%s>\n", msgBuf);
       fflush(stdout);
     }

     memcpy(md.CorrelId, md.MsgId, sizeof(md.CorrelId));
     memcpy(md.MsgId, MQMI_NONE, sizeof(md.MsgId));

     /* Simulate some 'processing' time preparing a response */
     msSleep(delay * 1000);

     PMQCHAR putMsgBuf = "Response message body";
     MQLONG putMsgLen = (MQLONG)strlen(putMsgBuf);

     md.MsgType = MQMT_REPLY;
     strncpy(objDesc.ObjectName, md.ReplyToQ, MQ_Q_NAME_LENGTH);
     strncpy(objDesc.ObjectQMgrName, md.ReplyToQMgr, MQ_Q_MGR_NAME_LENGTH);
     printf("ReplyToQ %.48s ReplyToQM %.48s\n", objDesc.ObjectName, objDesc.ObjectQMgrName);

     /* Put response message */
     MQPUT1(hcon, &objDesc, &md, &pmo, putMsgLen, putMsgBuf, &cc, &rc);
     printResults("MQPUT1", &cc, &rc);
     if(cc == MQCC_FAILED) exit(1);

     getTimeStamp(ts);
     printf("%s MQPUT put message: <%s>\n", ts, putMsgBuf);
     fflush(stdout);


   }
   /*-----------------------------------------------------------*/
   /* END OF MAIN LOOP                                          */
   /*-----------------------------------------------------------*/

   /* Close target queue */
   MQLONG closeOpts = MQCO_NONE;

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


/* Print additional options supplied to stdout */
void dumpOpts()
{
    printf("\nControl options:\n");
    printf("  Response delay %d seconds\n", delay);
    printf("\n");
    fflush(stdout);
}



