#ifndef TESTING_H
#define TESTING_H

#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif
/*--- Error reporting ---*/
enum testingResultCode_e {
  ADT_RESULT_SUCCESS = 0,
  ADT_RESULT_ERROR_NULL_PTR = -1,
  ADT_RESULT_ERROR_EMPTY = -2,
  ADT_RESULT_ERROR_ALLOC = -3,
  ADT_RESULT_ERROR_INVALID_HANDLE = -5,
  ADT_RESULT_ERROR_OTHER = -4
};

typedef enum testingResultCode_e testingResultCode;

/*--- Tracked Item ---*/
struct CTrackedItem_s {
  int value;
  int order;
};
typedef struct CTrackedItem_s CTrackedItem;

typedef CTrackedItem *TrackedItemHandle;
testingResultCode create_default(TrackedItemHandle *handle_out);
testingResultCode create_value(int value, int order,
                               TrackedItemHandle *handle_out);
testingResultCode destroy_tracked_item(TrackedItemHandle handle);
/*--- Notifications for zig singleton---*/
/** @brief Notifies Zig that a C++ TrackedItem was default constructed(Should
 * not happen). */
void notify_default_construct(void);
/** @brief Notifies Zig that a C++ TrackedItem was constructed(Should not
 * happen). */
void notify_value_construct(int value, int order);
/** @brief Notifies Zig that a C++ TrackedItem was destroyed. */
void notify_destruct(void);
/** @brief Notifies Zig that a C++ TrackedItem was copy-constructed. */
void notify_copy_construct(void);
/** @brief Notifies Zig that a C++ TrackedItem was copy-assigned. */
void notify_copy_assign(void);
/** @brief Notifies Zig that a C++ TrackedItem was move-constructed. */
void notify_move_construct(void);
/** @brief Notifies Zig that a C++ TrackedItem was move-assigned. */
void notify_move_assign(void);
/** @brief Notifies Zig that C++ performed an equality comparison (==). */
void notify_compare_eq(void);
/** @brief Notifies Zig that C++ performed a less-than comparison (<). */
void notify_compare_lt(void);

/** @brief Notifies Zig that C++ performed a greater-than comparison (>). */
void notify_compare_gt(void);
/** @brief Notifies Zig that C++ performed a not-equality comparison (!=). */
void notify_compare_neq(void);
/** @brief Notifies Zig that C++ performed a less-than-or-equal comparison (<=).
 */
void notify_compare_lte(void);
/** @brief Notifies Zig that C++ performed a greater-than-or-equal comparison
 * (>=). */
void notify_compare_gte(void);

/*--- Testing Options ---*/
enum Verbosity_e {
  Error = 0,
  Warning = -1,
  Info = -2,
  Debug = -2,
};

typedef enum Verbosity_e Verbosity;
enum InsertionOrder_e {
  Unknown = 0,
  FirstInFirstOut = -1,
  FirstInLastOut = -2,
};

typedef enum InsertionOrder_e InsertionOrder;
typedef struct adtOperations_s adtOperations;
enum Complexity_e {
  None = 0,
  O1 = -1,
  ON = -2,
  ONLogN = -3,
  ON2 = -4,
  Undetermined = -5,
  InsufficientData = -6
};
typedef enum Complexity_e Complexity;
struct adtSimpleTestingOptions_s {
  char *name;
  Verbosity verbosity;
  InsertionOrder order;
  bool sorted_output;
  int *input_sizes;
  int input_sizes_size;
  bool estimate_complexity;
  Complexity expected_insert_complexity;
  Complexity expected_peek_complexity;
  Complexity expected_remove_complexity;
};
typedef struct adtSimpleTestingOptions_s adtSimpleTestingOptions;
adtSimpleTestingOptions default_adtSimpleTestingOptions(const char *name);
// the pointer to the ADT in the operation
typedef void *ADTHandle;

/*--- Testing simple ADT Operations ---*/

struct adtOperations_s {
  testingResultCode (*insert)(ADTHandle handle, CTrackedItem value);
  testingResultCode (*remove)(ADTHandle handle, TrackedItemHandle *value_out);
  testingResultCode (*peek)(ADTHandle handle, TrackedItemHandle *value_out);
  testingResultCode (*create)(
      ADTHandle *handle_out); // allways nullptr otherwise unsafe
  testingResultCode (*destroy)(ADTHandle handle);
};

/*--- Testing functions that exist ---*/
int test_test(adtOperations *);
int test_adt(adtOperations *, adtSimpleTestingOptions *);

#ifdef __cplusplus
}
#endif

#endif

#ifdef __cplusplus
#ifndef TESTING_HPP
#define TESTING_HPP

#include <ostream>

/*--- Cpp Struct Info ---*/
struct TrackedItem {
  int value;
  int order;

public:
  const CTrackedItem *get_c_const() const {
    return const_cast<CTrackedItem *>(
        reinterpret_cast<const CTrackedItem *>(this));
  };
  CTrackedItem *get_c() { return reinterpret_cast<CTrackedItem *>(this); };
  TrackedItem(const CTrackedItem &tr) {
    this->order = tr.order;
    this->value = tr.value;
  }
  TrackedItem() : value(0), order(0) { notify_default_construct(); }
  TrackedItem(int v, int o) : value(v), order(o) {
    notify_value_construct(v, o);
  }
  ~TrackedItem() { notify_destruct(); }
  TrackedItem(const TrackedItem &other)
      : value(other.value), order(other.order) {
    notify_copy_construct();
  }
  TrackedItem &operator=(const TrackedItem &other) {
    if (this != &other) {
      value = other.value;
      order = other.order;
      notify_copy_assign();
    }
    return *this;
  }
  TrackedItem(TrackedItem &&other) noexcept
      : value(other.value), order(other.order) {
    notify_move_construct();
  }
  TrackedItem &operator=(TrackedItem &&other) noexcept {
    if (this != &other) {
      value = other.value;
      order = other.order;
      notify_move_assign();
    }
    return *this;
  }

  bool operator==(const TrackedItem &rhs) const {
    notify_compare_eq();
    return this->value == rhs.value;
  }

  bool operator<(const TrackedItem &rhs) const {
    notify_compare_lt();
    return this->value < rhs.value;
  }

  bool operator!=(const TrackedItem &rhs) const {
    notify_compare_neq();
    return this->value != rhs.value;
  }
  bool operator>(const TrackedItem &rhs) const {
    notify_compare_gt();
    return this->value != rhs.value;
  }
  bool operator<=(const TrackedItem &rhs) const {
    notify_compare_lte();
    return this->value <= rhs.value;
  }
  bool operator>=(const TrackedItem &rhs) const {
    notify_compare_gte();
    return this->value >= rhs.value;
  }

  friend std::ostream &operator<<(std::ostream &os, const TrackedItem &obj);
};

testingResultCode create_default(TrackedItemHandle *handle_out) {
  *handle_out = (new TrackedItem())->get_c();
  return ADT_RESULT_SUCCESS;
};

testingResultCode create_value(int value, int order,
                               TrackedItemHandle *handle_out) {

  *handle_out = (new TrackedItem(value, order))->get_c();
  return ADT_RESULT_SUCCESS;
};
testingResultCode destroy_tracked_item(TrackedItemHandle handle){
  delete handle;
  return ADT_RESULT_SUCCESS;
}
inline std::ostream &operator<<(std::ostream &os, const TrackedItem &obj) {
  os << obj.value;
  return os;
}

/**
 * @brief Generates a C function pointer for a 'create' operation.
 * @param CPP_TYPE The C++ class type to instantiate (e.g.,
 * StackLinkedList<TrackedItem>).
 */
#define CREATE_CREATE_FN_PTR(CPP_TYPE)                                         \
  ([](ADTHandle *handle_out) -> testingResultCode {                            \
    /* Static lambda - NO CAPTURE */                                           \
    if (!handle_out) {                                                         \
      return ADT_RESULT_ERROR_NULL_PTR;                                        \
    }                                                                          \
    try {                                                                      \
      *handle_out = new CPP_TYPE();                                            \
      return ADT_RESULT_SUCCESS;                                               \
    } catch (const std::bad_alloc &) {                                         \
      *handle_out = nullptr;                                                   \
      return ADT_RESULT_ERROR_ALLOC;                                           \
    } catch (...) {                                                            \
      *handle_out = nullptr;                                                   \
      return ADT_RESULT_ERROR_OTHER;                                           \
    }                                                                          \
  }) // End of lambda

/**
 * @brief Generates a C function pointer for a 'destroy' operation.
 * @param CPP_TYPE The C++ class type to delete (e.g.,
 * StackLinkedList<TrackedItem>).
 */
#define CREATE_DESTROY_FN_PTR(CPP_TYPE)                                        \
  ([](ADTHandle handle) -> testingResultCode {                                 \
    /* Static lambda - NO CAPTURE */                                           \
    if (!handle) {                                                             \
      /* Destroying a null handle could be SUCCESS or ERROR */                 \
      /* Let's treat it as an error based on function signature needing a      \
       * valid handle */                                                       \
      return ADT_RESULT_ERROR_INVALID_HANDLE;                                  \
    }                                                                          \
    CPP_TYPE *obj = static_cast<CPP_TYPE *>(handle);                           \
    delete obj;                                                                \
    return ADT_RESULT_SUCCESS;                                                 \
  }) // End of lambda

/**
 * @brief Generates a C function pointer for a 'peek' operation.
 * @param CPP_TYPE The C++ class type (e.g., StackLinkedList<TrackedItem>).
 * @param CPP_METHOD_NAME The name of the *const* member function for peek
 * (e.g., peek). This function must exist on CPP_TYPE and return const
 * TrackedItem&.
 * @warning Contains an unsafe const_cast due to the C API expecting non-const
 * output.
 * @warning Assumes the method throws std::out_of_range or similar if container
 * is empty.
 */
#define CREATE_PEEK_FN_PTR(CPP_TYPE, CPP_METHOD_NAME)                          \
  ([](ADTHandle handle, TrackedItemHandle *value_out) -> testingResultCode {   \
    /* Static lambda - NO CAPTURE */                                           \
    if (!value_out) {                                                          \
      return ADT_RESULT_ERROR_NULL_PTR;                                        \
    }                                                                          \
    *value_out = nullptr;                                                      \
    if (!handle) {                                                             \
      return ADT_RESULT_ERROR_INVALID_HANDLE;                                  \
    }                                                                          \
                                                                               \
    const CPP_TYPE *sl = static_cast<const CPP_TYPE *>(handle);                \
    try {                                                                      \
      /* Call the specific C++ method by name */                               \
      const TrackedItem &item_ref = sl->CPP_METHOD_NAME();                     \
                                                                               \
      /* Get pointer to the item *inside* the container */                     \
      const TrackedItem *item_ptr = &item_ref;                                 \
                                                                               \
      /* Convert const C++* to const C* representation */                      \
      const CTrackedItem *c_item_ptr_const =                                   \
          item_ptr->get_c_const(); /* Use helper if needed */                  \
      /* Or: reinterpret_cast<const CTrackedItem*>(item_ptr); */               \
                                                                               \
      /* *** UNSAFE CONST_CAST *** needed for the current C API */             \
      *value_out = const_cast<CTrackedItem *>(c_item_ptr_const);               \
                                                                               \
      return ADT_RESULT_SUCCESS;                                               \
    } catch (const std::out_of_range &) {                                      \
      /* Assuming out_of_range means empty */                                  \
      return ADT_RESULT_ERROR_EMPTY;                                           \
    } catch (const std::exception &) {                                         \
      return ADT_RESULT_ERROR_OTHER;                                           \
    } catch (...) {                                                            \
      return ADT_RESULT_ERROR_OTHER;                                           \
    }                                                                          \
  }) // End of lambda

/**
 * @brief Generates a C function pointer for an 'insert' operation.
 * @param CPP_TYPE The C++ class type (e.g., StackLinkedList<TrackedItem>).
 * @param CPP_METHOD_NAME The name of the member function for insert (e.g.,
 * push). This function must exist on CPP_TYPE and accept a TrackedItem argument
 * (usually by value or const ref).
 * @warning Assumes the method may throw std::bad_alloc on allocation failure.
 */
#define CREATE_INSERT_FN_PTR(CPP_TYPE, CPP_METHOD_NAME)                        \
  ([](ADTHandle handle, CTrackedItem value) -> testingResultCode {             \
    /* Static lambda - NO CAPTURE */                                           \
    if (!handle) {                                                             \
      return ADT_RESULT_ERROR_INVALID_HANDLE;                                  \
    }                                                                          \
                                                                               \
    CPP_TYPE *sl = static_cast<CPP_TYPE *>(handle);                            \
    try {                                                                      \
      /* Convert C value to C++ object and call method by name */              \
      /* Assumes CPP_METHOD_NAME takes TrackedItem by value or const ref */    \
      sl->CPP_METHOD_NAME(TrackedItem(value));                                 \
      return ADT_RESULT_SUCCESS;                                               \
    } catch (const std::bad_alloc &) {                                         \
      return ADT_RESULT_ERROR_ALLOC;                                           \
    } catch (const std::exception &) {                                         \
      return ADT_RESULT_ERROR_OTHER;                                           \
    } catch (...) {                                                            \
      return ADT_RESULT_ERROR_OTHER;                                           \
    }                                                                          \
  }) // End of lambda

/**
 * @brief Generates a C function pointer for a 'remove' operation.
 * @param CPP_TYPE The C++ class type (e.g., StackLinkedList<TrackedItem>).
 * @param CPP_METHOD_NAME The name of the member function for remove (e.g.,
 * pop). This function must exist on CPP_TYPE and return a TrackedItem
 * (typically by value).
 * @warning Assumes the method throws std::out_of_range or similar if container
 * is empty.
 */
#define CREATE_REMOVE_FN_PTR(CPP_TYPE, CPP_METHOD_NAME)                        \
  ([](ADTHandle handle, TrackedItemHandle *value_out) -> testingResultCode {   \
    /* Static lambda - NO CAPTURE */                                           \
    if (!value_out) {                                                          \
      return ADT_RESULT_ERROR_NULL_PTR;                                        \
    }                                                                          \
    *value_out = nullptr;                                                      \
    if (!handle) {                                                             \
      return ADT_RESULT_ERROR_INVALID_HANDLE;                                  \
    }                                                                          \
                                                                               \
    CPP_TYPE *sl = static_cast<CPP_TYPE *>(handle);                            \
    try {                                                                      \
      /* Call the specific C++ method by name */                               \
      TrackedItem removed_item = sl->CPP_METHOD_NAME();                        \
                                                                               \
      /* *** ALLOCATION REQUIRED + CALLER MUST FREE *** */                     \
      /* Use nothrow to avoid exception during allocation check */             \
      CTrackedItem *allocated_copy = new (std::nothrow) CTrackedItem();        \
      if (!allocated_copy) {                                                   \
        return ADT_RESULT_ERROR_ALLOC;                                         \
      }                                                                        \
      allocated_copy->value = removed_item.value;                              \
      allocated_copy->order = removed_item.order;                              \
      *value_out = allocated_copy;                                             \
      /* ********************************************** */                     \
                                                                               \
      return ADT_RESULT_SUCCESS;                                               \
    } catch (const std::out_of_range &) {                                      \
      /* Assuming out_of_range means empty */                                  \
      return ADT_RESULT_ERROR_EMPTY;                                           \
    } catch (const std::bad_alloc &) {                                         \
      /* If allocation *within* the C++ method failed */                       \
      return ADT_RESULT_ERROR_ALLOC;                                           \
    } catch (const std::exception &) {                                         \
      return ADT_RESULT_ERROR_OTHER;                                           \
    } catch (...) {                                                            \
      return ADT_RESULT_ERROR_OTHER;                                           \
    }                                                                          \
  }) // End of lambda
/**
 * @brief Creates and populates an adtOperations struct for a given C++ type and
 * its methods.
 *
 * @param CPP_TYPE The C++ class type (e.g., StackLinkedList<TrackedItem>).
 * @param INSERT_METHOD_NAME The name of the C++ method for insertion (e.g.,
 * push). Must accept a TrackedItem (by value or const ref).
 * @param REMOVE_METHOD_NAME The name of the C++ method for removal (e.g., pop).
 * Must return a TrackedItem (typically by value).
 * @param PEEK_METHOD_NAME The name of the *const* C++ method for peeking (e.g.,
 * peek). Must return a const TrackedItem&.
 *
 * @return A pointer to a newly allocated adtOperations struct, or nullptr on
 * failure. The caller is responsible for deleting the returned struct when no
 * longer needed.
 *
 * @warning The generated 'remove' function allocates memory which the C/Zig
 * caller MUST free.
 * @warning The generated 'peek' function uses an unsafe const_cast due to C API
 * limitations.
 */
#define CREATE_ADT_OPERATIONS(CPP_TYPE, INSERT_METHOD_NAME,                    \
                              REMOVE_METHOD_NAME, PEEK_METHOD_NAME, ORDER)     \
  ([]() -> adtOperations * {                                                   \
    /* Allocate the struct to hold the function pointers */                    \
    /* Use nothrow to prevent allocation exception here */                     \
    adtOperations *ops = new (std::nothrow) adtOperations();                   \
    if (!ops) {                                                                \
      /* Failed to allocate the operations struct itself */                    \
      return nullptr;                                                          \
    }                                                                          \
                                                                               \
    /* Use helper macros to generate and assign the function pointers */       \
    ops->create = CREATE_CREATE_FN_PTR(CPP_TYPE);                              \
    ops->destroy = CREATE_DESTROY_FN_PTR(CPP_TYPE);                            \
    ops->insert = CREATE_INSERT_FN_PTR(CPP_TYPE, INSERT_METHOD_NAME);          \
    ops->remove = CREATE_REMOVE_FN_PTR(CPP_TYPE, REMOVE_METHOD_NAME);          \
    ops->peek = CREATE_PEEK_FN_PTR(CPP_TYPE, PEEK_METHOD_NAME);                \
    /* --- Sanity Check --- */                                                 \
    /* Verify that all function pointers were successfully assigned */         \
    /* (macros should always generate valid pointers if compilation succeeds)  \
     */                                                                        \
    if (!ops->create || !ops->destroy || !ops->insert || !ops->remove ||       \
        !ops->peek) {                                                          \
      delete ops;     /* Clean up partially allocated struct */                \
      return nullptr; /* Indicate failure */                                   \
    }                                                                          \
                                                                               \
    return ops; /* Return the fully populated struct */                        \
  }())          // Immediately invoke the lambda to get the result
#endif
#endif
