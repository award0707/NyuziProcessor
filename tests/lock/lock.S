
# Copyright 2011-2015 Jeff Bush
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


#
# Blink LEDs on fpga board in sequence
#

                .global     _start

_start:         load_32     s0, device_addr # LED Device address
                move        s1, 1       # Current display value
                shl         s1, s1, 18
                move        s2, s1 
                load_32     s3, delay       # Delay
                load_32     s5, test_lock_addr
                lock        s5, (s5)
                

loop0:          store_32    s1, (s0)        # Update LEDs

                # Wait
                move        s4, s3
delay0:         sub_i       s4, s4, 1
                btrue       s4, delay0

                # Rotate left
                shr         s1, s1, 1 

                # Check if we've wrapped
                btrue       s1, loop0

                move        s1, s2
                goto        loop0

device_addr:    .long 0xFFFF0000
delay:          .long 100000
test_lock_addr: .long 0x00050000
