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
package org.amqp
{
    import com.ericfeminella.utils.Map;

    import org.amqp.error.IllegalArgumentError;

    public class FrameHelper
    {
        public static function shortStrSize(str:String):int
        {
            return str.length + 1;
        }

        /** Computes the AMQP wire-protocol length of a protocol-encoded long string. */
        public static function longStrSize(str:String):int
        {
            return str.length + 4;
        }

        public static function tableSize(table:Map):int
        {
            var acc:int = 0;
            for (var key:String in table)
            {
                acc += shortStrSize(key);
                acc += fieldValueSize(table.getValue(key));
            }
            return acc;
        }

        private static function fieldValueSize(value:Object):int
        {
            var acc:int = 1;    // for the type tag
            if (value is String)
            {
                acc += longStrSize(value as String);
            } else if (value is LongString)
            {
                acc += 4;
                var optimizeMe:int = (value as LongString).length();
                acc += optimizeMe;
            } else if (value is int)
            {
                acc += 4;
            } else if (value is Date)
            {
                acc += 8;
            } else if (value is Map)
            {
                acc += 4;
                acc += tableSize(value as Map);
            } else if (value is Boolean)
            {
                acc += 1;
            } else if (value == null)
            {
                // empty
            } else
            {
                throw new IllegalArgumentError("Invalid value in table: [" + value + "]");
            }
            return acc;
        }
    }
}
