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
/* (C Header file)                                                    */
/**********************************************************************/

/* Portable millisecond sleep macro */
#ifdef WIN32
   #include <windows.h>
   #define msSleep(time)  Sleep(time)
#else
   #include <sys/types.h>
   #include <sys/time.h>
   #define msSleep(time)                                             \
   {                                                                 \
      struct timeval tval;                                           \
                                                                     \
      tval.tv_sec  = (time) / 1000;                                  \
      tval.tv_usec = ((time) % 1000) * 1000;                         \
                                                                     \
      select(0, NULL, NULL, NULL, &tval);                            \
   }
#endif

/********************************************************************/
/* Function prototypes                                              */
/********************************************************************/
void EventHandler(MQHCONN hcon, PMQMD md, PMQGMO gmo, PMQBYTE buf, PMQCBC cbc);
void printResults(PMQCHAR mqi, PMQLONG cc, PMQLONG rc);
PMQCHAR  getTimeStamp(PMQCHAR buf);
PMQCHAR  stripWhiteSpace(PMQCHAR buf);
void dumpBNO(PMQBNO pBNO);
void dumpCNO(MQCNO cno);

