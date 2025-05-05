#ifndef STACKLINKEDLIST_H
#define STACKLINKEDLIST_H
#include <stdexcept>

template <typename T> class StackLinkedList {
private:
  class Node {
  public:
    T data;
    Node *next;
    Node(T data, Node *next = nullptr) : data(data), next(next) {}
  };
  Node *start = nullptr;

public:
  StackLinkedList();
  virtual ~StackLinkedList();
  StackLinkedList(const StackLinkedList &other) = delete;
  StackLinkedList &operator=(const StackLinkedList &other) = delete;
  void push(const T &element);
  T pop();
  const T &peek() const;
  bool isEmpty() const;
  int size() const;
};

template <typename T> inline StackLinkedList<T>::StackLinkedList() {}

template <typename T> inline StackLinkedList<T>::~StackLinkedList() {}

template <typename T> inline void StackLinkedList<T>::push(const T &element) {
  start = new Node(element, start);
}

template <typename T> inline T StackLinkedList<T>::pop() {
  if (start == nullptr) {
    throw "No one exists";
  }
  T data = start->data;
  start = start->next;
  return data;
}

template <typename T> inline const T &StackLinkedList<T>::peek() const {
  return start->data;
}

template <typename T> inline bool StackLinkedList<T>::isEmpty() const {
  return start == nullptr;
}

template <typename T> inline int StackLinkedList<T>::size() const {
  Node *next = start;
  int size = 0;
  while (next != nullptr) {
    next = next->next;
    size++;
  }
  return size;
}

#endif
