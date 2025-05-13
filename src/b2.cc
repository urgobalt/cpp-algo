#include "../impls/Heap.hpp"
#include "../impls/HeapList.hpp"
#include "../impls/IndexedList.hpp"
#include "../impls/OrderedList.hpp"
#include "../impls/PriorityQueueHeap.hpp"
#include "../impls/PriorityQueueOrderdList.hpp"
#include <testing>

int main() {
  adtSimpleTestingOptions options =
      default_adtSimpleTestingOptions((char *)"testing");
  adtOperations *sll =
      CREATE_ADT_OPERATIONS(Heap<TrackedItem>, insert, extract, peek, Sorted);
  test_adt(sll, &options);

  adtOperations *hl = CREATE_ADT_OPERATIONS(HeapList<TrackedItem>, insert,
                                            extract, peek, Unknown);
  test_adt(hl, &options);
  adtOperations *il = CREATE_ADT_OPERATIONS(IndexedList<TrackedItem>, add,
                                            removeFirst, first, Unknown);
  test_adt(il, &options);

  adtOperations *ol = CREATE_ADT_OPERATIONS(OrderedList<TrackedItem>, add,
                                            removeFirst, first, Unkown);
  test_adt(ol, &options);
  adtOperations *pqh = CREATE_ADT_OPERATIONS(PriorityQueueHeap<TrackedItem>,
                                             enqueue, dequeue, peek, Unkown);
  test_adt(pqh, &options);
  adtOperations *pqol = CREATE_ADT_OPERATIONS(
      PriorityQueueOrderedList<TrackedItem>, enqueue, dequeue, peek, Unkown);
  test_adt(pqol, &options);
}
