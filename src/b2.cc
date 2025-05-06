#include "../impls/Heap.hpp"
#include <testing>

int main() {
  adtOperations *sll = CREATE_ADT_OPERATIONS(Heap<TrackedItem>, insert, extract,
                                             peek, FirstInLastOut);
  adtTestingOptions options = {.order = Unknown};

  test_adt(sll, &options);
}
