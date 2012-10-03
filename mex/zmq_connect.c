#include "mex.h"
#include "zmq.h"

/*
 [ctx, socket] = zmq_init_socket
 [ctx, socket] = zmq_init_socket(type)
*/

void mexFunction(int nlhs, mxArray *plhs[],
		 int nrhs, const mxArray *prhs[])
{
  const mxArray *curarg;
  int nchars, sockettype;
  char *urlstr;
  void *ctx, *socket, **ptr;
  mxClassID classid;

  if (nlhs != 2)
    mexErrMsgTxt("Must receive two outputs, the context and socket");
  if (nrhs < 1 || nrhs > 2)
    mexErrMsgTxt("Requires 1 or 2 inputs: url, <socket type>");

  /* Get the url */
  curarg = prhs[0];
  if (!mxIsChar(curarg) || mxGetM(prhs[0]) != 1)
    mexErrMsgTxt("The first input must be the url (a string) that you want to connect to");
  nchars = mxGetN(curarg);
  /*
  mexPrintf("There are %d characters in the string", nchars);
  char* urlstr = (char*) mxMalloc(nchars+1);
  int status = mxGetString(curarg, urlstr, nchars);
  if (status != 0)
    mexErrMsgTxt("Converting url to cstring failed");
  */
  urlstr = mxArrayToString(curarg);
  if (urlstr == NULL)
    mexErrMsgTxt("Converting url to cstring failed");

  /* Determine the socket type */
  sockettype = ZMQ_REQ;
  if (nrhs > 1) {
    curarg = prhs[1];
    if (mxGetNumberOfElements(curarg) != 1 || !mxIsNumeric(curarg))
      mexErrMsgTxt("Socket type must be a number");
    sockettype = (int) mxGetScalar(curarg);
  }
  
  /* Allocate the output */
  if (sizeof(void*) == 4)
    classid = mxUINT32_CLASS;
  else
    classid = mxUINT64_CLASS;

  plhs[0] = mxCreateNumericMatrix(1, 1, classid, mxREAL);
  plhs[1] = mxCreateNumericMatrix(1, 1, classid, mxREAL);

  /* Initialize the context */
  ctx = zmq_init(1);
  if (ctx == NULL)
    mexErrMsgTxt(zmq_strerror(zmq_errno()));
  /* Initialize the socket */
  socket = zmq_socket(ctx, sockettype);
  if (socket == NULL)
    mexErrMsgTxt(zmq_strerror(zmq_errno()));
  /* Connect the socket to url */
  if (zmq_connect(socket, urlstr) != 0)
    mexErrMsgTxt(zmq_strerror(zmq_errno()));

  mxFree(urlstr);

  /* Package the context and socket pointers in the output */
  ptr = (void**)mxGetData(plhs[0]);
  *ptr = ctx;
  ptr = (void**)mxGetData(plhs[1]);
  *ptr = socket;
}
