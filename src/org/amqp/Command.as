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
    import de.polygonal.ds.Prioritizable;

    import flash.utils.ByteArray;
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;

    import org.amqp.error.UnexpectedFrameError;
    import org.amqp.headers.ContentHeader;
    import org.amqp.headers.ContentHeaderReader;
    import org.amqp.methods.MethodArgumentWriter;
    import org.amqp.methods.MethodReader;

    /**
     * EMPTY_CONTENT_BODY_FRAME_SIZE, 8 = 1 + 2 + 4 + 1
     * - 1 byte of frame type
     * - 2 bytes of channel number
     * - 4 bytes of frame payload length
     * - 1 byte of payload trailer FRAME_END byte
     *
     **/
    public class Command extends Prioritizable
    {
        public static var STATE_EXPECTING_METHOD:int = 0;
        public static var STATE_EXPECTING_CONTENT_HEADER:int = 1;
        public static var STATE_EXPECTING_CONTENT_BODY:int = 2;
        public static var STATE_COMPLETE:int = 3;
        public static var EMPTY_CONTENT_BODY_FRAME_SIZE:int = 8;
        public static var EMPTY_BYTE_ARRAY:ByteArray = new ByteArray();

        private var _state:int;
        private var _remainingBodyBytes:int;
        public var method:Method;
        public var contentHeader:ContentHeader;
        public var content:ByteArray = new ByteArray;

        public function Command(m:Method = null,
                                c:ContentHeader = null,
                                b:ByteArray = null)
        {
            method = m;
            contentHeader = c;
            content = new ByteArray();
            addToContentBody(b);
            _state = (m == null) ? STATE_EXPECTING_METHOD : STATE_COMPLETE;
            priority = (m == null) ? -1 : (m.getClassId() * 100 + m.getMethodId() ) * -1;
            _remainingBodyBytes = 0;
        }

        public function isComplete():Boolean
        {
            return _state == STATE_COMPLETE;
        }

        private function addToContentBody(b:ByteArray):void
        {
            if (b != null)
            {
                content.writeBytes(b, content.position, 0);
            }
        }

        /**
         * Chops the content of this command into frames and dispatches
         * it to the underlying transport mechanism.
         **/
        public function transmit(channelNumber:int, connection:Connection):void
        {

            var f:Frame = new Frame();
            f.type = AMQP.FRAME_METHOD;
            f.channel = channelNumber;

            var bodyOut:IDataOutput = f.getOutputStream();

            if (method.getClassId() < 0 || method.getMethodId() < 0)
            {
                throw new Error("Method not implemented properly" + method);
            }

            bodyOut.writeShort(method.getClassId());
            bodyOut.writeShort(method.getMethodId());
            var argWriter:MethodArgumentWriter = new MethodArgumentWriter(bodyOut);
            method.writeArgumentsTo(argWriter);
            argWriter.flush();
            connection.sendFrame(f);

            if (this.method.hasContent())
            {

                f = new Frame();
                f.type = AMQP.FRAME_HEADER;
                f.channel = channelNumber;
                bodyOut = f.getOutputStream();
                bodyOut.writeShort(contentHeader.getClassId());
                contentHeader.writeTo(bodyOut, this.content.length);
                connection.sendFrame(f);

                var frameMax:int = connection.frameMax;
                var bodyPayloadMax:int =
                        (frameMax == 0) ? this.content.length : frameMax - EMPTY_CONTENT_BODY_FRAME_SIZE;

                for (var offset:int = 0; offset < this.content.length; offset += bodyPayloadMax)
                {
                    var remaining:int = this.content.length - offset;

                    f = new Frame();
                    f.type = AMQP.FRAME_BODY;
                    f.channel = channelNumber;
                    bodyOut = f.getOutputStream();
                    bodyOut.writeBytes(this.content, offset,
                            (remaining < bodyPayloadMax) ? remaining : bodyPayloadMax);
                    connection.sendFrame(f);
                }
            }
        }

        public function handleFrame(frame:Frame):Boolean
        {
            switch (_state)
            {
                case STATE_EXPECTING_METHOD:
                    consumeMethodFrame(frame);
                    break;

                case STATE_EXPECTING_CONTENT_HEADER:
                    consumeHeaderFrame(frame);
                    break;

                case STATE_EXPECTING_CONTENT_BODY:
                    consumeBodyFrame(frame);
                    break;

                default:
                    throw new Error("Bad Command State " + _state);
            }
            return isComplete();
        }

        private function consumeMethodFrame(frame:Frame):void
        {
            if (frame.type == AMQP.FRAME_METHOD)
            {
                this.method = MethodReader.readMethodFrom(frame.getInputStream());
                _state = this.method.hasContent() ? STATE_EXPECTING_CONTENT_HEADER : STATE_COMPLETE;
            } else
            {
                throw new UnexpectedFrameError("State: STATE_EXPECTING_METHOD", frame);
            }
        }

        private function consumeHeaderFrame(frame:Frame):void
        {
            if (frame.type == AMQP.FRAME_HEADER)
            {
                var input:IDataInput = frame.getInputStream();
                this.contentHeader = ContentHeaderReader.readContentHeaderFrom(input);
                _remainingBodyBytes = this.contentHeader.readFrom(input);
                updateContentBodyState();
            } else
            {
                throw new Error("Unexpected frame");
            }
        }

        private function consumeBodyFrame(frame:Frame):void
        {
            if (frame.type == AMQP.FRAME_BODY)
            {
                var fragment:ByteArray = frame.getPayload();
                _remainingBodyBytes -= fragment.length;
                updateContentBodyState();
                if (_remainingBodyBytes < 0)
                {
                    throw new Error("%%%%%% FIXME unimplemented");
                }
                addToContentBody(fragment);
            } else
            {
                throw new Error("Unexpected frame");
            }
        }

        public function updateContentBodyState():void
        {
            _state = (_remainingBodyBytes > 0) ? STATE_EXPECTING_CONTENT_BODY : STATE_COMPLETE;
        }
    }
}