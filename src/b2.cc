#include "StackLinkedList.hpp"
#include <iostream>
#include <testing>

int main() {
  adtOperations *sll =
      CREATE_ADT_OPERATIONS(StackLinkedList<TrackedItem>, push, pop, peek);

  test_adt(sll);
}
