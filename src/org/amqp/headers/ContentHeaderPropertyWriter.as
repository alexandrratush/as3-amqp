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
package org.amqp.headers
{
    import com.ericfeminella.utils.Map;

    import flash.utils.ByteArray;
    import flash.utils.IDataOutput;

    import org.amqp.impl.ValueWriter;

    public class ContentHeaderPropertyWriter
    {
        public var flags:Array;
        /** Output stream collecting the packet as it is generated */
        public var _output:ValueWriter;

        /** Current flags word being accumulated */
        public var flagWord:int;
        /** Position within current flags word */
        public var bitCount:int;

        public function ContentHeaderPropertyWriter()
        {
            this.flags = [];
            _output = new ValueWriter(new ByteArray());
            this.flagWord = 0;
            this.bitCount = 0;
        }

        /**
         * Private API - encodes the presence or absence of a particular
         * object, and returns true if the main data stream should contain
         * an encoded form of the object.
         */
        public function argPresent(value:Object):Boolean
        {
            if (bitCount == 15)
            {
                flags[flags.length] = flagWord | 1;
                flagWord = 0;
                bitCount = 0;
            }

            if (value != null)
            {
                var bit:int = 15 - bitCount;
                flagWord |= (1 << bit);
                bitCount++;
                return true;
            } else
            {
                bitCount++;
                return false;
            }
        }

        public function dumpTo(output:IDataOutput):void
        {
            if (bitCount > 0)
            {
                flags[flags.length] = flagWord;
            }
            for (var i:int = 0; i < flags.length; i++)
            {
                output.writeShort(flags[i]);
            }
            output.writeBytes(_output.byteArray, 0, 0);
        }

        /** Protected API - Writes a String value as a short-string to the stream, if it's non-null */
        public function writeShortstr(x:String):void
        {
            if (argPresent(x))
            {
                _output.writeShortStr(x);
            }
        }

        /** Protected API - Writes a String value as a long-string to the stream, if it's non-null */
        public function writeLongstr(x:String):void
        {
            if (argPresent(x))
            {
                _output.writeString(x);
            }
        }

        /** Protected API - Writes a short integer value to the stream, if it's non-null */
        public function writeShort(x:int):void
        {
            if (argPresent(x))
            {
                _output.writeShort(x);
            }
        }

        /** Protected API - Writes an integer value to the stream, if it's non-null */
        public function writeLong(x:int):void
        {
            if (argPresent(x))
            {
                _output.writeLong(x);
            }
        }

        /** Protected API - Writes a long integer value to the stream, if it's non-null */
        public function writeLonglong(x:uint):void
        {
            if (argPresent(x))
            {
                _output.writeLonglong(x);
            }
        }

        /** Protected API - Writes a table value to the stream, if it's non-null */
        public function writeTable(x:Map):void
        {
            if (argPresent(x))
            {
                _output.writeTable(x);
            }
        }

        /** Protected API - Writes an octet value to the stream, if it's non-null */
        public function writeOctet(x:int):void
        {
            if (argPresent(x))
            {
                _output.writeOctet(x);
            }
        }

        /** Protected API - Writes a timestamp value to the stream, if it's non-null */
        public function writeTimestamp(x:Date):void
        {
            if (argPresent(x))
            {
                _output.writeTimestamp(x);
            }
        }
    }
}
