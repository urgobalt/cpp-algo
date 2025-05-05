#ifndef QUEUEARRAY_H
#define QUEUEARRAY_H
#include <stdexcept>

template <typename T> class QueueArray {
private:
  T *elements;
  int capacity;
  int start = 0;
  int end = 0;
  int amount = 0;

public:
  QueueArray();
  virtual ~QueueArray();
  QueueArray(const QueueArray &other) = delete;
  QueueArray &operator=(const QueueArray &other) = delete;
  void enqueue(const T &element);
  T dequeue();
  const T &peek() const;
  bool isEmpty() const;
  int size() const;

private:
  void expand();
};

template <typename T> void QueueArray<T>::expand() {
  T *new_arr = new T[capacity * 2];
  for (int i = 0; i < capacity; i++) {
    new_arr[i] = elements[(i + start) % capacity];
  }
  delete[] elements;
  elements = new_arr;
  start = 0;
  end = capacity;
  capacity *= 2;
}
template <typename T> inline QueueArray<T>::QueueArray() {
  capacity = 10;
  elements = new T[capacity];
}

template <typename T> inline QueueArray<T>::~QueueArray() {
  while (start != end) {
    delete elements[start];
    start++;
  }
  delete[] elements;
};

template <typename T> inline void QueueArray<T>::enqueue(const T &element) {
  amount++;
  end = (end + 1) % capacity;
  if (start == end) {
    this->expand();
  }
  end = (end + 1) % capacity;
  elements[end] = element;
}

template <typename T> inline T QueueArray<T>::dequeue() {
  amount--;
  start = (start + 1) % capacity;
  return elements[start - 1];
}

template <typename T> inline const T &QueueArray<T>::peek() const {
  return &elements[start];
}

template <typename T> inline bool QueueArray<T>::isEmpty() const {
  return start == end;
}

template <typename T> inline int QueueArray<T>::size() const { return amount; }

#endif
