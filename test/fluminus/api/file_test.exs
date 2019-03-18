defmodule Fluminus.API.FileTest do
  use ExUnit.Case, async: true

  alias Fluminus.API.File

  @temp_dir "test/temp/api/file/"
  @id_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSIsImtpZCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSJ9.eyJpc3MiOiJodHRwczovL2x1bWludXMubnVzLmVkdS5zZy92Mi9hdXRoIiwiYXVkIjoidmVyc28iLCJleHAiOjE1NTIwMzQ4ODQsIm5iZiI6MTU1MjAzNDU4NCwibm9uY2UiOiJlYjA0Y2ZmN2U4YTg0YTM0YTlhOWE0YWI3NGU3NzE2NiIsImlhdCI6MTU1MjAzNDU4NCwiYXRfaGFzaCI6Im9RYmFrbkxxeUVPYWtWQV8tMjA2Q1EiLCJjX2hhc2giOiJfMi02T29UYjJJOUpFU2lDZEI2ZGVBIiwic2lkIjoiNTYyZGYxYWYyODRhMDA4MTY1MGE0MDQ4N2NhODAzOTgiLCJzdWIiOiIwMzA4OTI1Mi0wYzk2LTRmYWItYjA4MC1mMmFlYjA3ZWViMGYiLCJhdXRoX3RpbWUiOjE1NTIwMzQ1ODQsImlkcCI6Imlkc3J2IiwiYWRkcmVzcyI6IlJlcXVlc3QgYWxsIGNsYWltcyIsImFtciI6WyJwYXNzd29yZCJdfQ.R54fwml4-KmwaD_pNSJxmf3XXoQdf3coik7-c-Lt7dconpJHLlorsiymQaiGLTlUdvMGHYvN_1JzCi42azkCxF2kjAJiosdCigR3b4okM1sovXoJsbE7tIycx2jpZwCmusL6nMffzE0ly_Q28x55jdQmJ9PIyGe7XD4mfKqDweht4fhCAtoeJtNPeDKX2dG6p4ll0lJxgVBOZsdi8PYF6z_rTt7zmMgd9CSc6WH2sOl8f9FKpVxoGtLBmjEBcNbwODokTu-cgW20vLFc05a7UZa3uKzPZI3DONnUDptLGgatcYGmNDTooQrJdh5xDKrK1tmkgVgBTmvPb44WYIiqHw"
  @authorization %Fluminus.Authorization{jwt: @id_token, client: %Fluminus.HTTPClient{}}
  @module %Fluminus.API.Module{
    code: "ST2334",
    id: "40582141-1a1d-41b6-ba3a-efa44ff7fd05",
    name: "Probability and Statistics",
    teaching?: false,
    term: "1820"
  }
  @sample_file %File{
    allow_upload?: false,
    children: [],
    directory?: false,
    id: "731db9ba-b919-4614-928c-1ac7d4172b3c",
    name: "Jasra, Ajay - Tut1.docx"
  }

  setup_all do
    Elixir.File.rm_rf!(@temp_dir)
    Elixir.File.mkdir_p!(@temp_dir)

    on_exit(fn ->
      Elixir.File.rm_rf!(@temp_dir)
    end)
  end

  test "from_module" do
    assert {:ok, file} = File.from_module(@module, @authorization)

    assert file ==
             %File{
               allow_upload?: false,
               children: [
                 %File{
                   allow_upload?: false,
                   children: nil,
                   directory?: true,
                   id: "7c464b62-3811-4c87-b1d1-7407e6ec321b",
                   name: "Tutorial Questions"
                 },
                 %File{
                   allow_upload?: false,
                   children: nil,
                   directory?: true,
                   id: "5a9525ba-e90c-44aa-a659-267bbf508d11",
                   name: "Lecture Notes"
                 }
               ],
               directory?: true,
               id: "40582141-1a1d-41b6-ba3a-efa44ff7fd05",
               name: "ST2334"
             }
  end

  test "from_module filename sanitised" do
    module = %Fluminus.API.Module{@module | code: "CS1231/MA1100"}
    assert {:ok, file} = File.from_module(module, @authorization)
    assert file.name == "CS1231-MA1100"
  end

  test "load_children directory allow_upload prepends with creator name" do
    assert {:ok, file} =
             File.load_children(
               %File{
                 allow_upload?: true,
                 children: nil,
                 directory?: true,
                 id: "7c464b62-3811-4c87-b1d1-7407e6ec321b",
                 name: "Tutorial Questions"
               },
               @authorization
             )

    assert file.children == [
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "399c60ce-26a9-4567-9864-83a7964c60d3",
               name: "Jasra, Ajay - ST2334 Solution to Tut 5.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "6d2c2c56-0ee5-4f63-a56d-2c5b64565ff5",
               name: "Jasra, Ajay - ST2334 Solution to Tut 4.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "64904b93-cc80-4397-b085-122852b711b1",
               name: "Jasra, Ajay - ST2334 Solution to Tut 3.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "e9109d02-4054-4c5c-ae94-264e424fd525",
               name: "Jasra, Ajay - ST2334 Solution to Tut 2.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "e5014221-6e1d-4907-a0e0-1ce6a30a67da",
               name: "Jasra, Ajay - ST2334 Solution to Tut 1.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "566fcc1a-d5e2-4e9d-b53d-b12f25ec37ee",
               name: "Jasra, Ajay - Tut11.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "361d6f87-f2ca-499f-9c61-1c200baed725",
               name: "Jasra, Ajay - Tut10.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "bb9a448d-4757-4767-bd8d-2fc1220224bf",
               name: "Jasra, Ajay - Tut9.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "ad3f5277-f9d0-4c9f-8283-04d4b2ce986a",
               name: "Jasra, Ajay - Tut8.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "2dd73690-b6ee-47cd-99d5-b486fb3cb513",
               name: "Jasra, Ajay - Tut6.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "b8889d6d-3a38-4404-ac0f-aa53799a5237",
               name: "Jasra, Ajay - Tut7.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "dbc6c7fd-0261-4603-b233-beca395067fa",
               name: "Jasra, Ajay - Tut4.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "8ae29e68-822b-471b-866b-9b1098fcede2",
               name: "Jasra, Ajay - Tut5.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "d3009c67-f037-484e-bcab-3028f9a321da",
               name: "Jasra, Ajay - Tut2.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "08905bc1-de56-4c5e-9620-7dacf0cca377",
               name: "Jasra, Ajay - Tut3.docx"
             },
             %File{
               allow_upload?: false,
               children: [],
               directory?: false,
               id: "731db9ba-b919-4614-928c-1ac7d4172b3c",
               name: "Jasra, Ajay - Tut1.docx"
             }
           ]
  end

  test "load_children directory" do
    assert {:ok, file} =
             File.load_children(
               %File{
                 allow_upload?: false,
                 children: nil,
                 directory?: true,
                 id: "40582141-1a1d-41b6-ba3a-efa44ff7fd05",
                 name: "ST2334"
               },
               @authorization
             )

    assert file.children == [
             %File{
               allow_upload?: false,
               children: nil,
               directory?: true,
               id: "7c464b62-3811-4c87-b1d1-7407e6ec321b",
               name: "Tutorial Questions"
             },
             %File{
               allow_upload?: false,
               children: nil,
               directory?: true,
               id: "5a9525ba-e90c-44aa-a659-267bbf508d11",
               name: "Lecture Notes"
             }
           ]
  end

  test "load_children file" do
    assert {:ok, file} =
             File.load_children(
               %File{
                 allow_upload?: false,
                 children: nil,
                 directory?: false,
                 id: "731db9ba-b919-4614-928c-1ac7d4172b3c",
                 name: "Tut1.docx"
               },
               @authorization
             )

    assert file.children == []
  end

  test "load_children already_loaded" do
    assert {:ok, file} =
             File.load_children(
               %File{
                 allow_upload?: false,
                 children: [],
                 directory?: false,
                 id: "731db9ba-b919-4614-928c-1ac7d4172b3c",
                 name: "Tut1.docx"
               },
               @authorization
             )

    assert file.children == []
  end

  test "get_download_url" do
    assert {:ok, "http://localhost:8082/v2/api/files/download/6f3cfb8c-5b91-4d5a-849a-70dcb31eea87"} =
             File.get_download_url(@sample_file, @authorization)
  end

  test "download" do
    assert :ok = File.download(@sample_file, @authorization, @temp_dir)
    assert @temp_dir |> Path.join(@sample_file.name) |> Elixir.File.read!() == "This is just a sample file.\n"
    assert {:error, :exists} = File.download(@sample_file, @authorization, @temp_dir)
  end
end
