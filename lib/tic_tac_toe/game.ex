defmodule TicTacToe.Game do
  alias TicTacToe.{Board, Game, Rules, Coordinate}
  @enforce_keys [:board, :rules]
  defstruct [:board, :rules]

  def start() do
    Agent.start(fn ->
      {:ok, game} = new()
      game
    end, name: __MODULE__)
  end

  def start_game do
    %Game{rules: rules} = current_state = get_state(__MODULE__)
    {:ok, rules} = Rules.check(rules, :add_player)
    new_state = update_game(__MODULE__, current_state, [rules: rules])
    {:ok, new_state}
  end

  def place_mark(x, y)
  when is_integer(x) and is_integer(y) do
    game_state = get_state(__MODULE__)
    with {:ok, win_or_not, %Game{} = game_state}
           <- do_place_mark(game_state, x, y),
         {:ok, %Game{rules: rules} = game_state}
           <- chk_win(game_state, win_or_not)
    do
      case rules.state do
        :game_over ->
          new_state = update_game(__MODULE__, game_state, [rules: rules])
          {:ok, new_state}

        _otherwise -> next_player(game_state, __MODULE__)
      end
    end

  end

  defp new() do
    {:ok, board} = Board.new()
    {
      :ok,
      %Game{
        board: board,
        rules: Rules.new()
      }
    }
  end

  defp get_state(game) when is_atom(game), do:
    Agent.get(game, &(&1))

  defp update_game(game, %Game{} = current_state, updates) do
    new_state = struct(current_state, updates)
    Agent.update(game, fn %Game{} ->
      new_state
    end)
    new_state
  end

  defp do_place_mark(%Game{} = game_state, x, y) do
    with {:ok, coord} <- Coordinate.new(x, y),
         {:ok, win_or_not, board}
           <- Board.place_mark(game_state.board, get_mark(game_state), coord)
    do
      new_game_state = %Game{game_state | board: board}
      {:ok, win_or_not, new_game_state}
    end
  end

  defp chk_win(%Game{rules: rules} = game_state, :win) do
    with {:ok, rules} <- Rules.check(rules, {:chk_win, :win}),
    do: {:ok, %Game{game_state | rules: rules}}
  end

  defp chk_win(%Game{rules: rules} = game_state, :no_win) do
    with {:ok, rules} <- Rules.check(rules, {:chk_win, :no_win}),
    do: {:ok, %Game{game_state | rules: rules}}
  end

  defp get_mark(%Game{rules: rules}) do
    case rules.state do
      :player1_turn -> :x
      :player2_turn -> :o
    end
  end

  defp next_player(%Game{rules: rules} = current_game_state, game) do
    case rules.state do
      :player1_turn -> control_to_next_player(current_game_state, game, :player1)
      :player2_turn -> control_to_next_player(current_game_state, game, :player2)
    end
  end

  defp control_to_next_player(%Game{rules: rules} = game_state, game, player)
  when is_atom(game) do
    with {:ok, new_rules} <- Rules.check(rules, {:mark, player})
    do
      new_state =
        update_game(game, game_state, [rules: new_rules])
      {:ok, new_state, game}
    end
  end


end
