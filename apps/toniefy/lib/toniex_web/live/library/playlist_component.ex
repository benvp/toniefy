defmodule ToniexWeb.LibraryLive.PlaylistComponent do
  use ToniexWeb, :live_component

  require Integer

  defp format_duration(milliseconds) do
    time =
      milliseconds
      |> Timex.Duration.from_milliseconds()
      |> Timex.Duration.to_time!()

    "#{time.minute} min #{time.second} sec"
  end

  def render(assigns) do
    ~L"""
    <div class="flex flex-col mt-4">
      <div class="-my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
      <div class="py-2 align-middle inline-block min-w-full sm:px-6 lg:px-8">
        <div class="shadow overflow-hidden border-b border-gray-200 sm:rounded-lg">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  #
                </th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Interpret
                </th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Titel
                </th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Länge
                </th>
              </tr>
            </thead>
            <tbody>
              <%= for {track, index} <- Enum.with_index(@tracks) do %>
                <%= if Integer.is_even(index) do %>
                  <!-- Even row -->
                  <tr class="bg-gray-50">
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      <%= index + 1 %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      <%= track.artist %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                      <%= track.title %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                      <%= format_duration(track.duration) %>
                    </td>
                  </tr>
                <% else %>
                  <!-- Odd row -->
                  <tr class="bg-white">
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      <%= index + 1 %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      <%= track.artist %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                      <%= track.title %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                      <%= format_duration(track.duration) %>
                    </td>
                  </tr>
                <% end %>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
      </div>
    </div>
    """
  end
end
