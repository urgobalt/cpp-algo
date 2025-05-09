#include "../impls/Heap.hpp"
#include <testing>

int main() {
  adtOperations *sll = CREATE_ADT_OPERATIONS(Heap<TrackedItem>, insert, extract,
                                             peek, FirstInLastOut);

  adtOperations options = default_adtSimpleTestingOptions("Heap");
  test_adt(sll, &options);
}
