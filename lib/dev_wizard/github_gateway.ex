defmodule DevWizard.GithubGateway do
  defstruct(user: nil,
            tentacat_client: nil)

  def new(gh_access_token, user) do
    tentacat = Tentacat.Client.new(%{access_token: gh_access_token})
    %DevWizard.GithubGateway{
      user:            user,
      tentacat_client: tentacat
    }
  end

  def is_user_member_of_organization(gh_access_token, organization) do
    client = Tentacat.Client.new(%{access_token: gh_access_token})

    user = Tentacat.Users.me(client)
    user = %{name: user["name"], avatar: user["avatar_url"], login: user["login"]}

    is_member = Tentacat.Organizations.Members.member?(organization, user[:login], client)
    case is_member do
      {204, _} -> true
            _  -> false
    end
  end

  def pulls_involving_you(gw) do
    settings = Application.get_env(:dev_wizard, :github_settings)
    org = settings[:organization]
    repos = settings[:repositories]

    Enum.reduce(repos, %{},
      fn(repo, acc) ->
        pulls = Tentacat.Pulls.filter(org,
                                      repo,
                                      %{involving: gw.user[:login]},
                                      gw.tentacat_client)
        Map.put acc, repo, pulls
    end)
  end
end
