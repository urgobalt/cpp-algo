
#ifndef QUEUELINKEDLIST_H
#define QUEUELINKEDLIST_H
#include <stdexcept>

template <typename T> class QueueLinkedList {
private:
  class Node {
  public:
    T data;
    Node *next;
    Node(T data, Node *next = nullptr) : data(data), next(next) {}
  };

public:
  QueueLinkedList();
  virtual ~QueueLinkedList();
  QueueLinkedList(const QueueLinkedList &other) = delete;
  QueueLinkedList &operator=(const QueueLinkedList &other) = delete;
  void enqueue(const T &element);
  T dequeue();
  const T &peek() const;
  bool isEmpty() const;
  int size() const;
};

template <typename T> inline QueueLinkedList<T>::QueueLinkedList() {}

template <typename T> inline QueueLinkedList<T>::~QueueLinkedList() {}

template <typename T>
inline void QueueLinkedList<T>::enqueue(const T &element) {}

template <typename T> inline T QueueLinkedList<T>::dequeue() {
  T removeThis;
  return removeThis;
}

template <typename T> inline const T &QueueLinkedList<T>::peek() const {
  T removeThis;
  return removeThis;
}

template <typename T> inline bool QueueLinkedList<T>::isEmpty() const {
  return false;
}

template <typename T> inline int QueueLinkedList<T>::size() const { return -1; }

#endif
