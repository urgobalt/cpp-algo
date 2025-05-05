
#ifndef QUEUESTACKS_H
#define QUEUESTACKS_H
#include "StackArray.hpp"
#include <stdexcept>

template <typename T> class QueueStacks {
private:
public:
  QueueStacks();
  virtual ~QueueStacks();
  QueueStacks(const QueueStacks &other) = delete;
  QueueStacks &operator=(const QueueStacks &other) = delete;
  void enqueue(const T &element);
  T dequeue();
  const T &peek(); // Cannot be const in this version
  bool isEmpty() const;
  int size() const;
};

template <typename T> inline QueueStacks<T>::QueueStacks() {}

template <typename T> inline QueueStacks<T>::~QueueStacks() {}

template <typename T> inline void QueueStacks<T>::enqueue(const T &element) {}

template <typename T> inline T QueueStacks<T>::dequeue() {
  T removeThis;
  return removeThis;
}

template <typename T> inline const T &QueueStacks<T>::peek() {
  T removeThis;
  return removeThis;
}

template <typename T> inline bool QueueStacks<T>::isEmpty() const {
  return false;
}

template <typename T> inline int QueueStacks<T>::size() const { return -1; }

#endif
