#ifndef STACKARRAY_H
#define STACKARRAY_H
#include <stdexcept>

template <typename T> class StackArray {
private:
  T *elements;
  int capacity;
  int amount = 0;

public:
  StackArray(int initialCapacity = 10);
  virtual ~StackArray();
  StackArray(const StackArray &other) = delete;
  StackArray &operator=(const StackArray &other) = delete;
  void push(const T &element);
  T pop();
  const T &peek() const;
  bool isEmpty() const;
  int size() const;
};

template <typename T> inline StackArray<T>::StackArray(int initialCapacity) {
  elements = new T[initialCapacity];
  capacity = initialCapacity;
}

template <typename T> inline StackArray<T>::~StackArray() { delete[] elements; }

template <typename T> inline void StackArray<T>::push(const T &element) {
  amount = (amount++) % capacity;
  elements[amount] = element;
}
template <typename T> inline T StackArray<T>::pop() {
  T element = elements[amount];
  amount--;
  return element;
}

template <typename T> inline const T &StackArray<T>::peek() const {
  T &element = &elements[amount];
  return element;
}

template <typename T> inline bool StackArray<T>::isEmpty() const {
  return amount == 0;
}

template <typename T> inline int StackArray<T>::size() const { return amount; }

#endif
