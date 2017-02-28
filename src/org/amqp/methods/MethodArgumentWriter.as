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

    import flash.utils.IDataOutput;

    import org.amqp.LongString;
    import org.amqp.impl.ValueWriter;

    public class MethodArgumentWriter
    {
        private var _out:ValueWriter;

        private var needBitFlush:Boolean;
        /** The current group of bits */
        private var bitAccumulator:int;
        /** The current position within the group of bits */
        private var bitMask:int;

        public function MethodArgumentWriter(output:IDataOutput)
        {
            _out = new ValueWriter(output);
            resetBitAccumulator();
        }

        private function resetBitAccumulator():void
        {
            needBitFlush = false;
            bitAccumulator = 0;
            bitMask = 1;
        }

        /**
         * Private API - called when we may be transitioning from encoding
         * a group of bits to encoding a non-bit value.
         */
        private final function bitflush():void
        {
            if (needBitFlush)
            {
                _out.writeOctet(bitAccumulator);
                resetBitAccumulator();
            }
        }

        /** Public API - encodes a short string argument. */
        public final function writeShortstr(str:String):void
        {
            bitflush();
            _out.writeShortStr(str);
        }

        /** Public API - encodes a long string argument from a LongString. */
        public final function writeLongstr(str:LongString):void
        {
            bitflush();
            _out.writeLongStr(str);
        }

        /** Public API - encodes a long string argument from a String. */
        public final function writeString(str:String):void
        {
            bitflush();
            _out.writeString(str);
        }

        /** Public API - encodes a short integer argument. */
        public final function writeShort(s:int):void
        {
            bitflush();
            _out.writeShort(s);
        }

        /** Public API - encodes an integer argument. */
        public final function writeLong(long:int):void
        {
            bitflush();
            _out.writeLong(long);
        }

        /** Public API - encodes a long integer argument. */
        public final function writeLonglong(ll:Number):void
        {
            bitflush();
            _out.writeLonglong(ll);
        }

        /** Public API - encodes a boolean/bit argument. */
        public function writeBit(b:Boolean):void
        {
            if (bitMask > 0x80)
            {
                bitflush();
            }
            if (b)
            {
                bitAccumulator |= bitMask;
            } else
            {
                // um, don't set the bit.
            }

            bitMask = bitMask << 1;
            needBitFlush = true;
        }

        /** Public API - encodes a table argument. */
        public final function writeTable(table:Map):void
        {
            bitflush();
            _out.writeTable(table);
        }


        /** Public API - encodes an octet argument from an int. */
        public final function writeOctet(octet:int):void
        {
            bitflush();
            _out.writeOctet(octet);
        }

        /** Public API - encodes a timestamp argument. */
        public final function writeTimestamp(timestamp:Date):void
        {
            _out.writeTimestamp(timestamp);
        }

        /**
         * Public API - call this to ensure all accumulated argument
         * values are correctly written to the output stream.
         */
        public function flush():void
        {
            bitflush();
        }
    }
}
