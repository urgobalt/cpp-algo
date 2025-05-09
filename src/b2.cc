#include "../impls/Heap.hpp"
#include <testing>

int main() {
  adtOperations *sll = CREATE_ADT_OPERATIONS(Heap<TrackedItem>, insert, extract,
                                             peek, FirstInLastOut);

  adtSimpleTestingOptions options =
      default_adtSimpleTestingOptions((char *)("Heap"));
  test_adt(sll, &options);
}
