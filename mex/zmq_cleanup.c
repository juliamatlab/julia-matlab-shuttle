#include "mex.h"
#include "zmq.h"

/* zmq_cleanup(ctx, socket) */

void mexFunction(int nlhs, mxArray *plhs[],
		 int nrhs, const mxArray *prhs[])
{
  const mxArray *curarg;

  if (nrhs != 2)
    mexErrMsgTxt("Requires two inputs, the context and socket");

  /* Get the context and socket pointers */
  void **ctx = (void**)mxGetData(prhs[0]);
  void **socket = (void**)mxGetData(prhs[1]);

  int ret1 = 0;
  int ret2 = 0;
  if (*socket != NULL)
    ret1 = zmq_close(*socket);
  if (*ctx != NULL)
    ret2 = zmq_term(*ctx);

  if (ret1 != 0 || ret2 != 0)
    mexErrMsgTxt("Error closing socket or terminating context");

  *socket = NULL;
  *ctx = NULL;
}
