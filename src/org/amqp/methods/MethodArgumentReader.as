/**
 * ---------------------------------------------------------------------------
 *   Copyright (C) 2008 0x6e6562
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 * ---------------------------------------------------------------------------
 **/
package org.amqp.methods
{
    import com.ericfeminella.utils.Map;

    import flash.utils.IDataInput;

    import org.amqp.LongString;
    import org.amqp.impl.ValueReader;

    public class MethodArgumentReader
    {
        private var _in:ValueReader;
        /** If we are reading one or more bits, holds the current packed collection of bits */
        private var bits:int;
        /** If we are reading one or more bits, keeps track of which bit position we are reading from */
        private var bit:int;

        public function MethodArgumentReader(input:IDataInput)
        {
            _in = new ValueReader(input);
            clearBits();
        }

        /**
         * Private API - resets the bit group accumulator variables when
         * some non-bit argument value is to be read.
         */
        private function clearBits():void
        {
            bits = 0;
            bit = 0x100;
        }

        public final function readShortstr():String
        {
            clearBits();
            return _in.readShortStr();
        }

        public final function readLongstr():LongString
        {
            clearBits();
            return _in.readLongStr();
        }

        public final function readShort():int
        {
            clearBits();
            return _in.readShort();
        }

        public final function readLong():int
        {
            clearBits();
            return _in.readLong();
        }

        public final function readLonglong():uint
        {
            clearBits();
            return _in.readLongLong();
        }

        public final function readBit():Boolean
        {
            if (bit > 0x80)
            {
                bits = _in.readOctet();
                bit = 0x01;
            }
            var result:Boolean = (bits & bit) != 0;
            bit = bit << 1;
            return result;
        }

        public final function readTable():Map
        {
            clearBits();
            return _in.readTable();
        }

        public function readOctet():int
        {
            clearBits();
            return _in.readOctet();
        }

        /** Public API - reads an timestamp argument. */
        public final function readTimestamp():Date
        {
            clearBits();
            return _in.readTimestamp();
        }
    }
}
