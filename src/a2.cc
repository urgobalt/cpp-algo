#ifndef A2_HPP
#define A2_HPP

#include <algorithm>
#include <cstring>
#include <iostream>

template <class T>
void Merge(T *elements, T *left, T *right, int nrOfElements,
           int leftNrOfElements, int rightNrOfElements) {
  int i = 0, j = 0, k = 0;

  while (j < leftNrOfElements and k < rightNrOfElements) {
    if (left[j] <= right[k]) {
      elements[i] = left[j];
      ++j;
    } else {
      elements[i] = right[k];
      ++k;
    }
    ++i;
  }

  while (j < leftNrOfElements) {
    elements[i] = left[j];
    ++i;
    ++j;
  }
  while (k < rightNrOfElements) {
    elements[i] = right[k];
    ++i;
    ++k;
  }
}

template <class T> void Mergesort(T elements[], int nrOfElements) {}

template <class T> void MergesortBook(T elements[], int nrOfElements) {
  MergeBook(elements, 0, (nrOfElements - 1) / 2, nrOfElements - 1);
}

// void Merge(T* elements, int startIndex, int midIndex, int endIndex)
template <class T> void MergeBook(T elements[], int start, int mid, int end) {}

template <class T> int PartitionLomuto(T elements[], int start, int end) {
  return -11;
}

template <class T>
void QuicksortLomutoRecursive(T elements[], int start, int end) {
  if (start < end) {
    int pivot = PartitionLomuto(elements, start, end);
    QuicksortLomutoRecursive(elements, start, pivot - 1);
    QuicksortLomutoRecursive(elements, pivot + 1, end);
  }
}

template <class T> void QuicksortLomuto(T elements[], int nrOfElements) {
  QuicksortLomutoRecursive(elements, 0, nrOfElements - 1);
}

template <class T> void QuicksortHoare(T elements[], int nrOfElements) {}

template <class T>
void QuicksortHoareImproved(T elements[], int nrOfElements) {}

template <class T> int MedianOfThree(T elements[], int start, int end) {
  int mid = (start + end) / 2;
  if ((elements[start] <= elements[mid] && elements[mid] <= elements[end]) ||
      (elements[start] >= elements[mid] and elements[mid] >= elements[end]))
    return mid;
  if ((elements[mid] <= elements[start] && elements[start] <= elements[end]) ||
      (elements[mid] >= elements[start] and elements[start] >= elements[end]))
    return start;
  return end;
}

template <class T>
void QuicksortHoareImprovedMedian3(T elements[], int nrOfElements) {}

template <class T> void Heapsort(T elements[], int nrOfElements) {}

#endif
int main() { std::cout << "a2" << std::endl; }
