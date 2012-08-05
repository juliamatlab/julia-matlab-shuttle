#include "mex.h"
#include "zmq.h"
#include <string.h>   /* for memcpy */

/*
 reply = zmq_exec(socket, request)
   request and reply are arrays of serialized bytes

 Handling CTRL-C within Malab
 We must declare the function for checking for CTRL-C because it's
 "undocumented"
 Thanks to Wotao Yin, http://www.caam.rice.edu/~wy1/links/mex_ctrl_c_trick/
*/
#ifdef __cplusplus 
    extern "C" bool utIsInterruptPending();
#else
    extern bool utIsInterruptPending();
#endif

void donothing(void *data, void *hint)
{
}

void mexFunction(int nlhs, mxArray *plhs[],
		 int nrhs, const mxArray *prhs[])
{
  const mxArray *curarg;

  if (nrhs != 2)
    mexErrMsgTxt("Requires 2 inputs: socket, request");
  if (nlhs != 1)
    mexErrMsgTxt("Requires 1 output: reply");

  /* Get the socket */
  curarg = prhs[0];
  if (mxGetNumberOfElements(curarg) != 1 || !mxIsNumeric(curarg))
    mexErrMsgTxt("The first input must be the socket");
  void **pptr = (void**)mxGetData(curarg);
  void *socket = *pptr;
  
  /* Get the data */
  curarg = prhs[1];
  if (mxGetClassID(curarg) != mxUINT8_CLASS)
    mexErrMsgTxt("Data must be an array of uint8");
  void *data = mxGetData(curarg);
  int nbytes = mxGetNumberOfElements(curarg);

  /* Create a message. Use zero-copy */
  zmq_msg_t msg;
  int rc = zmq_msg_init_data(&msg, data, nbytes, donothing, NULL);
  if (rc != 0)
    mexErrMsgTxt(zmq_strerror(zmq_errno()));

  /* Send the message */
  rc = zmq_send(socket, &msg, 0);
  if (rc != 0)
    mexErrMsgTxt(zmq_strerror(zmq_errno()));

  /* Receive the reply */
  zmq_msg_t msgback;
  rc = zmq_msg_init(&msgback);
  if (rc != 0)
    mexErrMsgTxt("Error creating recipient message");
  rc = zmq_recv(socket, &msgback, 0);
  if (rc != 0)
    mexErrMsgTxt(zmq_strerror(zmq_errno()));
  
  /* Create the output & copy the reply data */
  nbytes = zmq_msg_size(&msgback);
  plhs[0] = mxCreateNumericMatrix(nbytes, 1, mxUINT8_CLASS, mxREAL);
  memcpy(mxGetData(plhs[0]), zmq_msg_data(&msgback), nbytes);
}
