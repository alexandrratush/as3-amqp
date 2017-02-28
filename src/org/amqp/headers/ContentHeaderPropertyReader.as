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

    import flash.utils.IDataInput;

    import org.amqp.LongString;
    import org.amqp.impl.ValueReader;

    public class ContentHeaderPropertyReader
    {
        private var _in:ValueReader;
        /** Collected field flags */
        public var flags:Array;
        /** Position in argument stream */
        private var argumentIndex:int;

        public function ContentHeaderPropertyReader(input:IDataInput)
        {
            _in = new ValueReader(input);
            readFlags();
            this.argumentIndex = 0;
        }

        /**
         * Private API - reads the initial absence/presence flags from the
         * input stream
         */
        public function readFlags():void
        {
            var acc:Array = [];
            do {
                var flagsWord:int = _in.readShort();
                acc.push(flagsWord);
                if ((flagsWord & 1) == 0)
                {
                    break;
                }
            } while (true);
            flags = acc;
        }

        /**
         * Private API - checks the flags to see if the argument at the
         * current position is to be expected to be present in the main
         * data stream.
         */
        private function argPresent():Boolean
        {
            var word:int = argumentIndex / 15;
            var bit:int = 15 - (argumentIndex % 15);
            argumentIndex++;
            return (flags[word] & (1 << bit)) != 0;
        }

        /** Reads and returns an AMQP short string content header field, or null if absent. */
        public function readShortstr():String
        {
            if (!argPresent()) return null;
            return _in.readShortStr();
        }

        /** Reads and returns an AMQP "long string" (binary) content header field, or null if absent. */
        public function readLongstr():LongString
        {
            if (!argPresent()) return null;
            return _in.readLongStr();
        }

        /** Reads and returns an AMQP short integer content header field, or null if absent. */
        public function readShort():int
        {
            if (!argPresent()) return 0;
            return _in.readShort();
        }

        /** Reads and returns an AMQP integer content header field, or null if absent. */
        public function readLong():int
        {
            if (!argPresent()) return 0;
            return _in.readLong();
        }

        /** Reads and returns an AMQP long integer content header field, or null if absent. */
        public function readLonglong():uint
        {
            if (!argPresent()) return null;
            return _in.readLongLong();
        }

        /** Reads and returns an AMQP bit content header field. */
        public function readBit():Boolean
        {
            return argPresent();
        }

        /** Reads and returns an AMQP table content header field, or null if absent. */
        public function readTable():Map
        {
            if (!argPresent()) return null;
            return _in.readTable();
        }

        /** Reads and returns an AMQP octet content header field, or null if absent. */
        public function readOctet():int
        {
            if (!argPresent()) return 0;
            return _in.readOctet();
        }

        /** Reads and returns an AMQP timestamp content header field, or null if absent. */
        public function readTimestamp():Date
        {
            if (!argPresent()) return null;
            return _in.readTimestamp();
        }
    }
}
