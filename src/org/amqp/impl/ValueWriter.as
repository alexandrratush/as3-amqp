package org.amqp.impl
{
    import com.ericfeminella.utils.Map;

    import flash.utils.ByteArray;
    import flash.utils.IDataOutput;

    import org.amqp.FrameHelper;
    import org.amqp.LongString;
    import org.amqp.error.IllegalArgumentError;
    import org.amqp.util.IOUtils;

    public class ValueWriter
    {
        private var _output:IDataOutput;

        public function ValueWriter(output:IDataOutput)
        {
            _output = output;
        }

        public function writeShortStr(str:String):void
        {
            var buf:ByteArray = new ByteArray();
            buf.writeUTFBytes(str);
            _output.writeByte(buf.length);
            _output.writeBytes(buf, 0, 0);
        }

        public function writeLongStr(str:LongString):void
        {
            writeLong(str.length());
            IOUtils.copy(str.getBytes(), _output);
        }

        public function writeLong(long:int):void
        {
            _output.writeInt(long);
        }

        public final function writeLonglong(ll:Number):void
        {
            _output.writeDouble(ll);
        }

        public function writeString(str:String):void
        {
            writeLong(str.length);
            _output.writeUTFBytes(str);
        }

        public function writeShort(s:int):void
        {
            _output.writeShort(s);
        }

        public final function writeOctet(octet:int):void
        {
            _output.writeByte(octet);
        }

        public function writeTable(table:Map):void
        {
            if (table == null)
            {
                // Convenience.
                _output.writeInt(0);
            } else
            {
                _output.writeInt(FrameHelper.tableSize(table));
                for (var key:String in table)
                {
                    writeShortStr(key);
                    writeFieldValue(table.getValue(key));
                }
            }
        }

        private function writeFieldValue(value:Object):void
        {
            if (value is String)
            {
                writeOctet(83);     // 'S'
                writeString(value as String);
            } else if (value is LongString)
            {
                writeOctet(83);     // 'S'
                writeLongStr(value as LongString);
            } else if (value is Boolean)
            {
                writeOctet(116);    //'t'
                _output.writeBoolean(value);
            } else if (value is int)
            {
                writeOctet(73);     // 'I'
                writeLong(value as int);
            } else if (value is Number)
            {
                writeOctet(100);    //'d'
                _output.writeDouble(value as Number);
            } else if (value is Date)
            {
                writeOctet(84);     //'T'
                writeTimestamp(value as Date);
            } else if (value is Map)
            {
                writeOctet(70);     // 'F"
                writeTable(value as Map);
            } else if (value == null)
            {
                //corresponding 'read' is 'V' :
                writeOctet(86);
            } else
            {
                throw new IllegalArgumentError("Invalid value type: [" + value + "]");
            }
        }

        public final function writeTimestamp(timestamp:Date):void
        {
            writeLonglong(timestamp.time / 1000);
        }

        public function get byteArray():ByteArray
        {
            return _output as ByteArray;
        }
    }
}
