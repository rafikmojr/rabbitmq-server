%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 1997-2022. All Rights Reserved.
%% 
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%% 
%% %CopyrightEnd%
%%
-module(rabbit_tcp_dist).

%% Handles the connection setup phase with other Erlang nodes.

%% Required API
-export([accept/1, accept_connection/5, address/0,
         close/1,
         listen/1, listen/2,
         select/1, setup/5]).

%% Optional API
-export([setopts/2, getopts/2]).

accept(Listen) ->
    inet_tcp_dist:accept(Listen).

accept_connection(AcceptPid, Socket, MyNode, Allowed, SetupTime) ->
    inet_tcp_dist:accept_connection(AcceptPid, Socket, MyNode, Allowed, SetupTime).

address() ->
    inet_tcp_dist:address().

close(Socket) ->
    inet_tcp_dist:close(Socket).

listen(Name, Host) ->
    RV = inet_tcp_dist:listen(Name, Host),
    io:format(standard_error, "@@@@@@@@ listen/2: ~p~n", [RV]),
    RV.

listen(Name) ->
    RV = inet_tcp_dist:listen(Name),
    io:format(standard_error, "@@@@@@@@ listen/1: ~p~n", [RV]),
    RV.

select(Node) ->
    inet_tcp_dist:select(Node).

setup(Node, Type, MyNode, LongOrShortNames,SetupTime) ->
    inet_tcp_dist:setup(Node, Type, MyNode, LongOrShortNames,SetupTime).

setopts(S, Opts) ->
    inet_tcp_dist:setopts(S, Opts).

getopts(S, Opts) ->
    inet_tcp_dist:getopts(S, Opts).
