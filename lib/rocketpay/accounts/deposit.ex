defmodule Rocketpay.Accounts.Deposit do
alias Ecto.Multi
alias Rocketpay.{Account, Repo}
    def call(%{"id"=>id, "value"=>value} = params) do
      Multi.new()
      |> Multi.run(:account, fn repo, _changes-> get_account(repo,id) end)
      |> Multi.run(:update_balance, fn repo, %{account: account}-> update_balance(repo,account,value) end)
    end

defp get_account(repo,id) do
  case repo.get(Account, id) do
nill->{:error, "Account, not found!"}
account->{:ok,account}
  end
end

  defp update_balance(repo, account,value) do
    account
    |> sum_values(value)
    |> update_account(repo)
  end

  defp sum_values(%Account{balance: balance}, value) do
    value
    |> Decimal.cast()
    |> handle_cast(balance)
  end

  defp handle_cast({:ok,value},balance), do: Decimal.add(value, balance)
  defp handle_cast(:error, _balance), do: {:error, "Invalid deposit value!"}

  defp update_account({:error, _reason}=error, _repo), do: error

  defp update_account(value,repo) do
  params = %{balance: value}
  params
  |> Account.changeset()
  |>repo.update()
  end

  defp run_transaction(multi) do
    case Repo.transaction(multi) do
      {:error, _operation, reason, _changes} -> {:error, reason}
      {:ok, %{update_balance: account}} -> {:ok, account}
    end
  end
end
