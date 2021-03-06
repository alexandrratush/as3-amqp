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
package org.amqp.impl
{
    import de.polygonal.ds.ArrayedQueue;

    import flash.events.EventDispatcher;

    import org.amqp.Command;
    import org.amqp.CommandReceiver;
    import org.amqp.Connection;
    import org.amqp.Frame;
    import org.amqp.LifecycleEventHandler;
    import org.amqp.Method;
    import org.amqp.Session;

    public class SessionImpl implements Session
    {
        protected var QUEUE_SIZE:int = 100;

        private var connection:Connection;
        private var channel:int;
        private var commandReceiver:CommandReceiver;
        private var currentCommand:Command = new Command();

        private var dispatcher:EventDispatcher = new EventDispatcher();

        protected var rpcQueue:ArrayedQueue = new ArrayedQueue(QUEUE_SIZE);

        private var lifecycleHandlers:Array = new Array();

        public function SessionImpl(con:Connection, ch:int, receiver:CommandReceiver)
        {
            connection = con;
            channel = ch;
            commandReceiver = receiver;
        }

        public function handleFrame(frame:Frame):void
        {
            var command:Command = currentCommand;
            if (command.handleFrame(frame))
            {
                /**
                 * The idea is that this callback will always be invoked when a command is
                 * to be processed by the session handler, so it can kick off the dequeuing
                 * of any pending RPCs in addition to dispatching to the target callback handler,
                 * which is implemented in the super class.
                 */
                currentCommand = new Command(); // prepare for the next one
                commandReceiver.receive(command);
                if (command.method.isBottomHalf())
                {
                    rpcBottomHalf();
                }
            }
        }

        public function registerLifecycleHandler(handler:LifecycleEventHandler):void
        {
            lifecycleHandlers.push(handler);
        }

        public function emitLifecyleEvent():void
        {
            for (var i:uint = 0; i < lifecycleHandlers.length; i++)
            {
                (lifecycleHandlers[i] as LifecycleEventHandler).afterOpen();
            }
        }

        /**
         * The logic behind this is that a non-null fun signifies an RPC,
         * if the fun is null, then it is an asynchronous command.
         */
        public function sendCommand(cmd:Command, fun:Function = null):void
        {

            if (null != fun)
            {
                if (rpcQueue.isEmpty())
                {
                    send(cmd);
                }
                rpcQueue.enqueue({command: cmd, callback: fun});
            }
            else
            {
                send(cmd);
            }
        }

        private function send(cmd:Command):void
        {
            cmd.transmit(channel, connection);
        }

        public function rpc(cmd:Command, fun:Function):void
        {
            var method:Method = cmd.method;
            commandReceiver.addEventListener(method.getResponse(), fun);
            if (null != method.getAltResponse())
            {
                commandReceiver.addEventListener(method.getAltResponse(), fun);
            }
            sendCommand(cmd, fun);
        }

        private function rpcBottomHalf():void
        {
            if (!rpcQueue.isEmpty())
            {
                rpcQueue.dequeue();
                if (!rpcQueue.isEmpty())
                {
                    var o:Object = rpcQueue.peek();
                    send(o.command);
                }
            }
        }

        public function closeGracefully():void
        {
            commandReceiver.closeGracefully();
        }

        public function forceClose():void
        {
            commandReceiver.forceClose();
        }

    }
}
