-module(sumo_conditionals_test_helper).

%% Test Cases - Helpers
-export([
  dates/1,
  backward_compatibility/1,
  or_conditional/1,
  and_conditional/1,
  not_null_conditional/1,
  null_conditional/1,
  operators/1,
  deeply_nested/1,
  init_store/1
]).

-type config() :: [{atom(), term()}].

%%%=============================================================================
%%% Test Cases - Helpers
%%%=============================================================================

-spec dates(config()) -> ok.
dates(Config) ->
  {_, Module} = lists:keyfind(module, 1, Config),
  ct:comment("dates with ~p", [Module]),

  [_, _, _, _, _] = sumo:find_all(Module),

  Now = {Today, _} = calendar:universal_time(),

  [] = sumo:find_by(Module, [{birthdate, '>', Today}]),
  [_, _, _, _, _] = sumo:find_by(Module, [{birthdate, '==', Today}]),
  [_, _, _, _, _] = sumo:find_by(Module, [{birthdate, '=<', Today}]),
  [] = sumo:find_by(Module, [{created_at, '>', Now}]),
  [_, _, _, _, _] = sumo:find_by(Module, [{created_at, '=<', Now}]),
  ok.

-spec backward_compatibility(config()) -> ok.
backward_compatibility(Config) ->
  {_, Module} = lists:keyfind(module, 1, Config),
  ct:comment("backward_compatibility with ~p", [Module]),

  [_, _, _, _, _] = sumo:find_all(Module),
  [_, _, _] = sumo:find_by(Module, [{last_name, <<"Doe">>}]),
  [_] = sumo:find_by(Module, [{name, <<"Jane">>}, {last_name, <<"Doe">>}]),
  ok.

-spec or_conditional(config()) -> ok.
or_conditional(Config) ->
  {_, Module} = lists:keyfind(module, 1, Config),
  ct:comment("or_conditional with ~p", [Module]),

  [_, _, _] = sumo:find_by(Module,
    {'or', [
      {name, <<"John">>},
      {name, <<"Joe">>},
      {name, <<"Alan">>}
    ]}
  ),

  [_, _] = sumo:find_by(Module, [
    {last_name, <<"Doe">>},
    {'or', [
      {name, <<"Jane">>},
      {name, <<"Jane Jr.">>}
    ]}
  ]),
  ok.

-spec and_conditional(config()) -> ok.
and_conditional(Config) ->
  {_, Module} = lists:keyfind(module, 1, Config),
  ct:comment("and_conditional with ~p", [Module]),

  [] = sumo:find_by(Module,
    {'and', [
      {name, <<"John">>},
      {name, <<"Joe">>},
      {name, <<"Alan">>}
    ]}
  ),

  [_, _] = sumo:find_by(Module,
    {'and', [
      {last_name, <<"Doe">>},
      {'or', [
        {name, <<"Jane">>},
        {name, <<"Jane Jr.">>}
      ]}
    ]}
  ),
  ok.

-spec not_null_conditional(config()) -> ok.
not_null_conditional(Config) ->
  {_, Module} = lists:keyfind(module, 1, Config),
  ct:comment("not_null_conditional with ~p", [Module]),

  [_, _, _] = sumo:find_by(Module, {age, 'not_null'}),
  [_] = sumo:find_by(Module, {address, 'not_null'}),
  ok.

-spec null_conditional(config()) -> ok.
null_conditional(Config) ->
  {_, Module} = lists:keyfind(module, 1, Config),
  ct:comment("null_conditional with ~p", [Module]),

  [_, _] = sumo:find_by(Module, {age, 'null'}),
  [_, _, _, _] = sumo:find_by(Module, {address, 'null'}),
  ok.

-spec operators(config()) -> ok.
operators(Config) ->
  {_, Module} = lists:keyfind(module, 1, Config),
  ct:comment("operators with ~p", [Module]),

  [_, _] = sumo:find_by(Module,
    {'and', [
      {age, 'not_null'},
      {age, '<', 100}
    ]}
  ),

  [_] = sumo:find_by(Module,
    {'and', [
      {age, 'not_null'},
      {age, '>', 100}
    ]}
  ),

  [] = sumo:find_by(Module,
    {'and', [
      {age, 'not_null'},
      {age, '>', 102}
    ]}
  ),

  [_] = sumo:find_by(Module,
    {'and', [
      {age, 'not_null'},
      {age, '>=', 102}
    ]}
  ),

  [_] = sumo:find_by(Module,
    {'and', [
      {age, 'not_null'},
      {age, '<', 30}
    ]}
  ),

  [_, _] = sumo:find_by(Module,
    {'and', [
      {age, 'not_null'},
      {age, '=<', 30}
    ]}
  ),

  [_, _, _] = sumo:find_by(Module,
    {'or', [
      {age, 'null'},
      {age, '==', 30}
    ]}
  ),

  [_, _] = sumo:find_by(Module,
    {'and', [
      {age, 'not_null'},
      {age, '/=', 30}
    ]}
  ),

  case sumo_utils:keyfind(people_with_like, Config, false) of
    true ->
      [_, _, _, _] = sumo:find_by(Module, {name, 'like', <<"J%">>}),
      [_, _] = sumo:find_by(Module, {'and', [{name, 'like', <<"Ja%">>}]}),
      [_] = sumo:find_by(Module, {name, 'like', <<"A%">>}),
      [_, _] = sumo:find_by(Module, {name, 'like', <<"%n">>}),
      ok;
    false ->
      ok
  end.

-spec deeply_nested(config()) -> ok.
deeply_nested(Config) ->
  {_, Module} = lists:keyfind(module, 1, Config),
  ct:comment("deeply_nested with ~p", [Module]),

  Conditions =
    {'or', [
      {'and', [
        {age, '>', 100},
        {address, '==', <<"something">>}
      ]},
      {age, 'null'},
      {last_name, <<"Turing">>}
    ]},
  [_, _, _] = sumo:find_by(Module, Conditions),
  ok.

-spec init_store(module()) -> ok.
init_store(Module) ->
  sumo:create_schema(Module),
  sumo:delete_all(Module),

  sumo:persist(Module, Module:new(<<"Jane">>, <<"Doe">>)),
  sumo:persist(Module, Module:new(<<"John">>, <<"Doe">>, 30)),
  sumo:persist(Module, Module:new(<<"Jane Jr.">>, <<"Doe">>, 5)),
  sumo:persist(Module, Module:new(<<"Joe">>, <<"Armstrong">>)),
  sumo:persist(Module, Module:new(
    <<"Alan">>, <<"Turing">>, 102, <<"Computer St.">>)),
  ok.
