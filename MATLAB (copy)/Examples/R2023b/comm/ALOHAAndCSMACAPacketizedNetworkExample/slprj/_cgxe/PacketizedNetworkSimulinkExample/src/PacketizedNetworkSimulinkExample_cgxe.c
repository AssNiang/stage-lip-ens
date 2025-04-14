/* Include files */

#include "PacketizedNetworkSimulinkExample_cgxe.h"
#include "m_6ZqTk0OKN5QuhEtSrZC29B.h"

unsigned int cgxe_PacketizedNetworkSimulinkExample_method_dispatcher(SimStruct*
  S, int_T method, void* data)
{
  if (ssGetChecksum0(S) == 3555681173 &&
      ssGetChecksum1(S) == 210201439 &&
      ssGetChecksum2(S) == 3739409047 &&
      ssGetChecksum3(S) == 1544329537) {
    method_dispatcher_6ZqTk0OKN5QuhEtSrZC29B(S, method, data);
    return 1;
  }

  return 0;
}
