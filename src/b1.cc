#include "../impls/StackLinkedList.hpp"
#include <iostream>
#include <testing>

int main() {
  adtOperations *sll = CREATE_ADT_OPERATIONS(StackLinkedList<TrackedItem>, push,
                                             pop, peek, FirstInLastOut);

  adtOperations options = default_adtSimpleTestingOptions("testing");
  test_simple_adt(sll);
}
