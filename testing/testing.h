
#ifndef TESTING_H
#define TESTING_H

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  int value;
  int order;
} CTrackedItem;

enum testingResultCode {
  adt_RESULT_SUCCESS = 0,
  adt_RESULT_ERROR_NULL_PTR = -1,
  adt_RESULT_ERROR_EMPTY = -2,
  adt_RESULT_ERROR_ALLOC = -3,
  adt_RESULT_ERROR_INVALID_HANDLE = -5,
  adt_RESULT_ERROR_OTHER = -4
};

typedef void *ADTHandle;
typedef void *TrackedItemHandle;

struct adtOperations {
  testingResultCode (*insert)(ADTHandle handle, CTrackedItem value);
  TrackedItemHandle (*remove)(ADTHandle handle);
  TrackedItemHandle* (*peek)(ADTHandle handle);
  testingResultCode (*create)(
      ADTHandle *handle_out); // allways nullptr otherwise unsafe
  testingResultCode (*destroy)(ADTHandle handle);
};

testingResultCode create_tracked_item_default(TrackedItemHandle *handle_out);

testingResultCode create_tracked_item_value(int value, int order,
                                            TrackedItemHandle *handle_out);

testingResultCode destroy_tracked_item(TrackedItemHandle handle);

testingResultCode get_tracked_item_data(TrackedItemHandle handle,
                                        CTrackedItem *item_out);
void tracked_item_notify_default_construct(void);

/** @brief Notifies Zig that a C++ TrackedItem was constructed. */
void tracked_item_notify_value_construct(int value, int order);
/** @brief Notifies Zig that a C++ TrackedItem was destroyed. */
void tracked_item_notify_destruct(void);
/** @brief Notifies Zig that a C++ TrackedItem was copy-constructed. */
void tracked_item_notify_copy_construct(void);
/** @brief Notifies Zig that a C++ TrackedItem was copy-assigned. */
void tracked_item_notify_copy_assign(void);
/** @brief Notifies Zig that a C++ TrackedItem was move-constructed. */
void tracked_item_notify_move_construct(void);
/** @brief Notifies Zig that a C++ TrackedItem was move-assigned. */
void tracked_item_notify_move_assign(void);
/** @brief Notifies Zig that C++ performed an equality comparison (==). */
void tracked_item_notify_compare_eq(void);
/** @brief Notifies Zig that C++ performed a less-than comparison (<). */
void tracked_item_notify_compare_lt(void);

/** @brief Notifies Zig that C++ performed a greater-than comparison (>). */
void tracked_item_notify_compare_gt(void);
/** @brief Notifies Zig that C++ performed a not-equality comparison (!=). */
void tracked_item_notify_compare_neq(void);
/** @brief Notifies Zig that C++ performed a less-than-or-equal comparison (<=).
 */
void tracked_item_notify_compare_lte(void);
/** @brief Notifies Zig that C++ performed a greater-than-or-equal comparison
 * (>=). */
void tracked_item_notify_compare_gte(void);
#ifdef __cplusplus
}
#endif

#endif

#ifdef __cplusplus
#ifndef TESTING_HPP
#define TESTING_HPP

#include <ostream>

struct TrackedItem {
  int value;
  int order;

public:
  TrackedItem() : value(0), order(0) {
    tracked_item_notify_default_construct();
  }
  TrackedItem(int v, int o) : value(v), order(o) {
    tracked_item_notify_value_construct(v, o);
  }
  ~TrackedItem() { tracked_item_notify_destruct(); }
  TrackedItem(const TrackedItem &other)
      : value(other.value), order(other.order) {
    tracked_item_notify_copy_construct();
  }
  TrackedItem &operator=(const TrackedItem &other) {
    if (this != &other) {
      value = other.value;
      order = other.order;
      tracked_item_notify_copy_assign();
    }
    return *this;
  }
  TrackedItem(TrackedItem &&other) noexcept
      : value(other.value), order(other.order) {
    tracked_item_notify_move_construct();
  }
  TrackedItem &operator=(TrackedItem &&other) noexcept {
    if (this != &other) {
      value = other.value;
      order = other.order;
      tracked_item_notify_move_assign();
    }
    return *this;
  }

  bool operator==(const TrackedItem &rhs) const {
    tracked_item_notify_compare_eq();
    return this->value == rhs.value;
  }

  bool operator<(const TrackedItem &rhs) const {
    tracked_item_notify_compare_lt();
    return this->value < rhs.value;
  }

  bool operator!=(const TrackedItem &rhs) const {
    tracked_item_notify_compare_neq();
    return this->value != rhs.value;
  }
  bool operator>(const TrackedItem &rhs) const {
    tracked_item_notify_compare_gt();
    return this->value != rhs.value;
  }
  bool operator<=(const TrackedItem &rhs) const {
    tracked_item_notify_compare_lte();
    return this->value <= rhs.value;
  }
  bool operator>=(const TrackedItem &rhs) const {
    tracked_item_notify_compare_gte();
    return this->value >= rhs.value;
  }

  friend std::ostream &operator<<(std::ostream &os, const TrackedItem &obj);
};

inline std::ostream &operator<<(std::ostream &os, const TrackedItem &obj) {
  os << obj.value;
  return os;
}
#endif
#endif
