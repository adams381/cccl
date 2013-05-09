/*
 *  Copyright 2008-2012 NVIDIA Corporation
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#pragma once

#include <thrust/detail/config.h>
#include <limits>


namespace thrust
{
namespace detail
{


template<typename Integer>
__host__ __device__ __thrust_forceinline__
Integer clz(Integer x)
{
  // XXX optimize by lowering to intrinsics
  
  Integer num_non_sign_bits = std::numeric_limits<Integer>::digits;
  for(int i = num_non_sign_bits; i >= 0; --i)
  {
    if((1 << i) & x)
    {
      return num_non_sign_bits - i;
    }
  }

  return num_non_sign_bits + 1;
}


template<typename Integer>
__host__ __device__ __thrust_forceinline__
bool is_power_of_2(Integer x)
{
  return 0 == (x & (x - 1));
}


template<typename Integer>
__host__ __device__ __thrust_forceinline__
Integer log2(Integer x)
{
  return std::numeric_limits<Integer>::digits - clz(x);
}


template<typename Integer>
__host__ __device__ __thrust_forceinline__
Integer log2_ri(Integer x)
{
  Integer result = log2(x);

  // this is where we round up to the nearest log
  if(!is_power_of_2(x))
  {
    ++result;
  }

  return result;
}


template<typename Integer>
__host__ __device__ __thrust_forceinline__
bool is_odd(Integer x)
{
  return 1 & x;
}


} // end detail
} // end thrust

