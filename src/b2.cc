#include "../impls/Heap.hpp"
#include <testing>

int main() {
  adtOperations *sll = CREATE_ADT_OPERATIONS(Heap<TrackedItem>, insert, extract,
                                             peek, FirstInLastOut);
  adtTestingOptions_s options = adtTestingOptions_default;

  test_adt(sll, &options);
}
