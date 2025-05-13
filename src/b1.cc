#include "../impls/QueueArray.hpp"
#include "../impls/QueueLinkedList.hpp"
#include "../impls/QueueStack.hpp"
#include "../impls/StackArray.hpp"
#include "../impls/StackLinkedList.hpp"

#include <iostream>
#include <testing>

int main() {
  adtSimpleTestingOptions options =
      default_adtSimpleTestingOptions((char *)"testing");
  adtOperations *sll = CREATE_ADT_OPERATIONS(StackLinkedList<TrackedItem>, push,
                                             pop, peek, FirstInLastOut);
  test_adt(sll, &options);

  adtOperations *sa = CREATE_ADT_OPERATIONS(StackArray<TrackedItem>, push, pop,
                                            peek, FirstInLastOut);
  test_adt(sa, &options);
  adtOperations *qa = CREATE_ADT_OPERATIONS(QueueArray<TrackedItem>, enqueue,
                                            dequeue, peek, FirstInFirstOut);
  test_adt(qa, &options);

  adtOperations *qsll = CREATE_ADT_OPERATIONS(QueueLinkedList<TrackedItem>, enqueue,
                                            dequeue, peek, FirstInFirstOut);
  test_adt(qsll, &options);

  QueueStacks<int> queue=QueueStacks<int>();
  queue.enqueue(1);
}
