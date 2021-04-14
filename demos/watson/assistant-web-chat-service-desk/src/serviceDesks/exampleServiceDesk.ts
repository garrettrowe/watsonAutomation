/**
 * (C) Copyright IBM Corp. 2020.
 *
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * https://opensource.org/licenses/MIT
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 */

import { ErrorType } from '../types/errors';
import { MessageRequest, MessageResponse } from '../types/message';
import { User } from '../types/profiles';
import { ServiceDesk, ServiceDeskFactoryParameters, ServiceDeskStateFromWAC } from '../types/serviceDesk';
import { AgentProfile, ServiceDeskCallback } from '../types/serviceDeskCallback';
import { stringToMessageResponseFormat } from '../utils';


/**
 * This class returns startChat, endChat, sendMessageToAgent, updateState, userTyping, userReadMessages and
 * areAnyAgentsOnline to be exposed to web chat through src/buildEntry.ts.
 */
class ExampleServiceDesk implements ServiceDesk {
  agentProfile: AgentProfile;
  ws: WebSocket;
  callback: ServiceDeskCallback;
  user: User;
  sessionID: string;
  constructor(parameters: ServiceDeskFactoryParameters) {
    this.callback = parameters.callback;
    this.user = { id: '' };
    this.sessionID = '';
    this.agentProfile = {
      id: "",
      nickname: '',
    };
  }

  // Public ServiceDesk Methods
  /**
   * Instructs the service desk to start a new chat. This should be called immediately after the service desk
   * instance has been created. It will make the appropriate calls to the service desk and begin communicating back
   * to the calling code using the callback produce to the instance. This may only be called once per instance.
   *
   * @param connectMessage The original server message response that caused the connection to an agent. It will
   * contain specific information to send to the service desk as part of the connection. This can includes things
   * like a message to display to a human agent.
   * @returns Returns a Promise that resolves when the service desk has successfully started a new chat. This does
   * not necessarily mean that an agent has joined the conversation or has read any messages sent by the user.
   */
  async startChat(connectMessage: MessageResponse): Promise<void> {
    // In your real implementation you will want to grab this.user and this.sessionID to make available to your service desk.
    var self = this;
    this.ws = new WebSocket('wss://' + location.hostname + '/ws/socket');
    this.ws.binaryType = "arraybuffer";
    this.ws.onopen = function() {
        console.log('socket is open');
        self.ws.send(JSON.stringify({action: "waiting", user: this.user, session: this.sessionID}));
    };
    this.ws.onclose = function(e) {
      console.log('Socket is closed. Reconnect will be attempted in 1 second.', e.reason);
      setTimeout(function() {
        self.ws = new WebSocket('wss://' + location.hostname + '/ws/socket');
      }, 1000);
    };
    this.ws.onmessage = (e:Event) => {
      let d = JSON.parse(e.data)
      if (d.event == "message"){
        this.callback.agentTyping(false);
        this.callback.sendMessageToUser(stringToMessageResponseFormat(d.message), this.agentProfile.id);
        speakOut(d.message);
      }
      else if (d.event == "end"){
        this.callback.agentEndedChat();
      }
      else if (d.event == "join"){
        this.agentProfile = d.agentProfile;
        this.callback.agentJoined(d.agentProfile);
        audioicons = setInterval(addAudioAgent, 100);
      }
      else if (d.event == "typing"){
        this.callback.agentTyping(true);
      }
    };
    this.ws.onerror = function(err) {
        console.error('Socket encountered error: ', err.message, 'Closing socket');
        self.ws.close();
    };

    this.callback.updateAgentAvailability({ estimated_wait_time: 1 });

  }

  /**
   * Sends a message to the agent in the service desk.
   *
   * @param message The message from the user.
   * @param messageID The unique ID of the message assigned by the widget.
   * @returns Returns a Promise that resolves when the service desk has successfully handled the call.
   */
  async sendMessageToAgent(message: MessageRequest, messageID: string): Promise<void> {
    this.ws.send(JSON.stringify({action: "message", message: message, messageID: messageID}));
  }

  /**
   * Tells the service desk to terminate the chat.
   *
   * @returns Returns a Promise that resolves when the service desk has successfully handled the call.
   */
  async endChat(): Promise<void> {
  }

  /**
   * Informs the service desk of a change in the state of the web chat that is relevant to the service desks. These
   * values may change at any time.
   *
   * @param state The current values of pieces of state from the main chat.
   */
  updateState(state: ServiceDeskStateFromWAC): void {
    this.user = { id: state.userID };
    this.sessionID = state.sessionID;
  }
}

export { ExampleServiceDesk };
