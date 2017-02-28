package org.amqp.impl
{
    import com.ericfeminella.utils.HashMap;
    import com.ericfeminella.utils.Map;

    import flash.utils.ByteArray;
    import flash.utils.IDataInput;

    import org.amqp.LongString;
    import org.amqp.error.MalformedFrameError;

    public class ValueReader
    {
        private static const INT_MASK:uint = 0xffff;

        private var _input:IDataInput;

        public function ValueReader(input:IDataInput)
        {
            _input = input;
        }

        protected static function unsignedExtend(value:int):int
        {
            return value & INT_MASK;
        }

        public function readShortStr():String
        {
            return _readShortStr(_input);
        }

        private static function _readShortStr(input:IDataInput):String
        {
            var length:int = input.readUnsignedByte();
            return input.readUTFBytes(length);
        }

        public function readLongStr():LongString
        {
            return _readLongStr(_input);
        }

        private static function _readLongStr(input:IDataInput):LongString
        {
            var contentLength:int = input.readInt();
            if (contentLength < int.MAX_VALUE)
            {
                var buf:ByteArray = new ByteArray();
                input.readBytes(buf, 0, contentLength);
                return new ByteArrayLongString(buf);
            } else
            {
                throw new Error("Very long strings not currently supported");
            }
        }

        public function readShort():int
        {
            return _input.readShort();
        }

        public function readLong():int
        {
            return _input.readInt();
        }

        public function readLongLong():uint
        {
            var higher:int = _input.readInt();
            var lower:int = _input.readInt();
            return lower + higher << 0x100000000;
        }

        public function readOctet():int
        {
            return _input.readUnsignedByte();
        }

        public function readTable():Map
        {
            return _readTable(_input);
        }

        private static function _readTable(input:IDataInput):Map
        {
            var table:Map = new HashMap();
            var tableLength:int = input.readInt();
            if (tableLength == 0) return table; // readBytes(tableIn,0,0) reads ALL bytes

            var tableIn:ByteArray = new ByteArray();
            input.readBytes(tableIn, 0, tableLength);
            var value:Object;

            while (tableIn.bytesAvailable > 0)
            {
                var name:String = _readShortStr(tableIn);
                value = readFieldValue(tableIn);
                if (!table.containsKey(name))
                    table.put(name, value);
            }

            return table;
        }

        private static function readFieldValue(input:IDataInput):Object
        {
            var type:uint = input.readUnsignedByte();
            var value:Object;
            switch (type)
            {
                case 83 : //'S'
                    value = _readLongStr(input);
                    break;
                case 73: //'I'
                    value = input.readInt();
                    break;
                case 84: //'T':
                    value = _readTimestamp(input);
                    break;
                case 70: //'F':
                    value = _readTable(input);
                    break;
                case 68: //'D' Big Decimal
                    throw new Error("BigDecimal not yet implemented on this platform");
                    break;
                case 98 : //'b'
                    value = input.readByte();
                    break;
                case 100 : //'d'
                    value = input.readDouble();
                    break;
                case 102 : //'f'
                    value = input.readFloat();
                    break;
                case 108 : //'l'
                    // value = tableIn.readLong();
                    //this might be dubious... but is the same as readLongLong
                    var higher:int = input.readInt();
                    var lower:int = input.readInt();
                    value = lower + higher << 0x100000000;
                    break;
                case 115 : //'s'
                    value = input.readShort();
                    break;
                case 116 : //'t'
                    value = input.readBoolean();
                    break;
                case 120: //'x'
                    value = _readBytes(input);
                    break;
                case 86: //'V'
                    value = null;
                    break;
                default:
                    throw new MalformedFrameError("Unrecognised type in table");
            }
            return value;
        }

        public function readBytes():IDataInput
        {
            return _readBytes(_input);
        }

        public static function _readBytes(input:IDataInput):ByteArray
        {
            var contentLength:int = input.readInt();
            if (contentLength < int.MAX_VALUE)
            {
                var buf:ByteArray = new ByteArray();
                input.readBytes(buf, 0, contentLength);
                return buf;
            }
            else
            {
                throw new Error("Very long bytearrays not currently supported");
            }
        }

        public function readTimestamp():Date
        {
            return _readTimestamp(_input);
        }

        private static function _readTimestamp(input:IDataInput):Date
        {
            var date:Date = new Date();
            date.setTime(input.readInt() * 1000)
            return date;
        }
    }
}
