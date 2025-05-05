#include <cinttypes>
#include <cstring>
#ifndef A1_HPP
#define A1_HPP
#include <algorithm> // Included for use of std::swap()

template <class T> int LinearSearch(T elements[], int nrOfElements, T element) {
  for (int i = 0; i < nrOfElements; i++) {
    if (element == elements[i]) {
      return i;
    }
  }
  return -1;
}

template <class T> void Selectionsort(T elements[], int nrOfElements) {
  for (int i = 0; i < nrOfElements - 1; i++) {
    int min = i;
    for (int j = i + 1; j < nrOfElements; j++) {
      if (elements[min] > elements[j]) {
        min = j;
      }
    }
    std::swap(elements[i], elements[min]);
  }
}

template <class T> void Insertionsort(T elements[], int nrOfElements) {
  for (int i = 1; i < nrOfElements; i++) {
    T element = elements[i];
    int j = i - 1;
    while (j >= 0) {
      if (element < elements[j]) {
        elements[j + 1] = elements[j];
        j -= 1;
      } else {
        break;
      }
    }
    elements[j + 1] = element;
  }
}

template <class T> int BinarySearch(T elements[], int nrOfElements, T element) {
  int start = 0;
  int stop = nrOfElements - 1;
  while (start <= stop) {
    int center = (start + stop) / 2;
    if (elements[center] == element) {
      return center;
    }

    if (elements[center] < element) {
      start = center + 1;
    } else {
      stop = center - 1;
    }
  }

  return -1;
}

template <class T>
int LinearSearchRecursive(T elements[], int nrOfElements, T element) {
  // Implementera en rekursiv linjärsökning.
  // Anropa er egna rekursiva funktion härifrån.
  return -11;
}

template <class T>
int BinarySearchRecurse(T elements[], T element, int start, int stop) {
  if (start > stop)
    return -1;
  int center = (start + stop) / 2;
  if (elements[center] == element) {
    return center;
  }

  if (elements[center] > element) {
    return BinarySearchRecurse(elements, element, start, center - 1);
  } else {
    return BinarySearchRecurse(elements, element, center + 1, stop);
  }
}

template <class T>
int BinarySearchRecursive(T elements[], int nrOfElements, T element) {
  return BinarySearchRecurse(elements, element, 0, nrOfElements - 1);
}

template <class T> void BinaryInsertionsort(T elements[], int nrOfElements) {
  for (int i = 1; i < nrOfElements; i++) {
    T element = elements[i];
    int placement = 0;
    int start = 0;
    int stop = i - 1;
    while (true) {
      int center = (start + stop) / 2;
      if (start > stop) {
        placement = center + 1;
        break;
      }
      if (elements[center] == element) {
        placement = center;
        break;
      }

      if (elements[center] < element) {
        start = center + 1;
      } else {
        stop = center - 1;
      }
    }
    for (int j = placement; j < i; j++) {
      elements[j + 1] = elements[j];
    }
    elements[placement] = element;
  }
}
#endif


int main() {
  const int size = 7;
  int arr[size] = {4, 6, 5, 4, 3, 2, 1};
  int idxes[size] = {0, 1, 2, 3, 4, 5, 6};

  BinaryInsertionsort(arr, size);
}
