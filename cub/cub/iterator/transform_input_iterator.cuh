/******************************************************************************
 * Copyright (c) 2011, Duane Merrill.  All rights reserved.
 * Copyright (c) 2011-2018, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

/**
 * @file
 * Random-access iterator types
 */

#pragma once

#include <cub/config.cuh>

#if defined(_CCCL_IMPLICIT_SYSTEM_HEADER_GCC)
#  pragma GCC system_header
#elif defined(_CCCL_IMPLICIT_SYSTEM_HEADER_CLANG)
#  pragma clang system_header
#elif defined(_CCCL_IMPLICIT_SYSTEM_HEADER_MSVC)
#  pragma system_header
#endif // no system header

#include <cub/thread/thread_load.cuh>
#include <cub/thread/thread_store.cuh>

#include <thrust/iterator/iterator_facade.h>
#include <thrust/iterator/iterator_traits.h>

#include <iosfwd>

CUB_NAMESPACE_BEGIN

/**
 * @brief A random-access input wrapper for transforming dereferenced values.
 *
 * @par Overview
 * - TransformInputIterator wraps a unary conversion functor of type
 *   @p ConversionOp and a random-access input iterator of type <tt>InputIteratorT</tt>,
 *   using the former to produce references of type @p ValueType from the latter.
 * - Can be used with any data type.
 * - Can be constructed, manipulated, and exchanged within and between host and device
 *   functions.  Wrapped host memory can only be dereferenced on the host, and wrapped
 *   device memory can only be dereferenced on the device.
 * - Compatible with Thrust API v1.7 or newer.
 *
 * @par Snippet
 * The code snippet below illustrates the use of @p TransformInputIterator to
 * dereference an array of integers, tripling the values and converting them to doubles.
 * @par
 * @code
 * #include <cub/cub.cuh>   // or equivalently <cub/iterator/transform_input_iterator.cuh>
 *
 * // Functor for tripling integer values and converting to doubles
 * struct TripleDoubler
 * {
 *     __host__ __device__ __forceinline__
 *     double operator()(const int &a) const {
 *         return double(a * 3);
 *     }
 * };
 *
 * // Declare, allocate, and initialize a device array
 * int *d_in;                   // e.g., [8, 6, 7, 5, 3, 0, 9]
 * TripleDoubler conversion_op;
 *
 * // Create an iterator wrapper
 * cub::TransformInputIterator<double, TripleDoubler, int*> itr(d_in, conversion_op);
 *
 * // Within device code:
 * printf("%f\n", itr[0]);  // 24.0
 * printf("%f\n", itr[1]);  // 18.0
 * printf("%f\n", itr[6]);  // 27.0
 *
 * @endcode
 *
 * @tparam ValueType
 *   The value type of this iterator
 *
 * @tparam ConversionOp
 *   Unary functor type for mapping objects of type @p InputType to type @p ValueType.
 *   Must have member <tt>ValueType operator()(const InputType &datum)</tt>.
 *
 * @tparam InputIteratorT
 *   The type of the wrapped input iterator
 *
 * @tparam OffsetT
 *   The difference type of this iterator (Default: @p ptrdiff_t)
 */
template <typename ValueType, typename ConversionOp, typename InputIteratorT, typename OffsetT = ptrdiff_t>
class CCCL_DEPRECATED_BECAUSE("Use thrust::transform_iterator instead") TransformInputIterator
{
public:
  // Required iterator traits

  /// My own type
  using self_type = TransformInputIterator;

  /// Type to express the result of subtracting one iterator from another
  using difference_type = OffsetT;

  /// The type of the element the iterator can point to
  using value_type = ValueType;

  /// The type of a pointer to an element the iterator can point to
  using pointer = ValueType*;

  /// The type of a reference to an element the iterator can point to
  using reference = ValueType;

  /// The iterator category
  using iterator_category = typename THRUST_NS_QUALIFIER::detail::iterator_facade_category<
    THRUST_NS_QUALIFIER::any_system_tag,
    THRUST_NS_QUALIFIER::random_access_traversal_tag,
    value_type,
    reference>::type;

private:
  ConversionOp conversion_op;
  InputIteratorT input_itr;

public:
  /**
   * @param input_itr
   *   Input iterator to wrap
   *
   * @param conversion_op
   *   Conversion functor to wrap
   */
  _CCCL_HOST_DEVICE _CCCL_FORCEINLINE TransformInputIterator(InputIteratorT input_itr, ConversionOp conversion_op)
      : conversion_op(conversion_op)
      , input_itr(input_itr)
  {}

  /// Postfix increment
  _CCCL_HOST_DEVICE _CCCL_FORCEINLINE self_type operator++(int)
  {
    self_type retval = *this;
    input_itr++;
    return retval;
  }

  /// Prefix increment
  _CCCL_HOST_DEVICE _CCCL_FORCEINLINE self_type operator++()
  {
    input_itr++;
    return *this;
  }

  /// Indirection
  _CCCL_HOST_DEVICE _CCCL_FORCEINLINE reference operator*() const
  {
    return conversion_op(*input_itr);
  }

  /// Addition
  template <typename Distance>
  _CCCL_HOST_DEVICE _CCCL_FORCEINLINE self_type operator+(Distance n) const
  {
    self_type retval(input_itr + n, conversion_op);
    return retval;
  }

  /// Addition assignment
  template <typename Distance>
  _CCCL_HOST_DEVICE _CCCL_FORCEINLINE self_type& operator+=(Distance n)
  {
    input_itr += n;
    return *this;
  }

  /// Subtraction
  template <typename Distance>
  _CCCL_HOST_DEVICE _CCCL_FORCEINLINE self_type operator-(Distance n) const
  {
    self_type retval(input_itr - n, conversion_op);
    return retval;
  }

  /// Subtraction assignment
  template <typename Distance>
  _CCCL_HOST_DEVICE _CCCL_FORCEINLINE self_type& operator-=(Distance n)
  {
    input_itr -= n;
    return *this;
  }

  /// Distance
  _CCCL_HOST_DEVICE _CCCL_FORCEINLINE difference_type operator-(self_type other) const
  {
    return input_itr - other.input_itr;
  }

  /// Array subscript
  template <typename Distance>
  _CCCL_HOST_DEVICE _CCCL_FORCEINLINE reference operator[](Distance n) const
  {
    return conversion_op(input_itr[n]);
  }

  /// Equal to
  _CCCL_HOST_DEVICE _CCCL_FORCEINLINE bool operator==(const self_type& rhs) const
  {
    return (input_itr == rhs.input_itr);
  }

  /// Not equal to
  _CCCL_HOST_DEVICE _CCCL_FORCEINLINE bool operator!=(const self_type& rhs) const
  {
    return (input_itr != rhs.input_itr);
  }

  /// ostream operator
  _CCCL_SUPPRESS_DEPRECATED_PUSH
  friend std::ostream& operator<<(std::ostream& os, const self_type& /* itr */)
  {
    return os;
  }
  _CCCL_SUPPRESS_DEPRECATED_POP
};

CUB_NAMESPACE_END
