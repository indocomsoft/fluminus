defmodule Fluminus.API.ModuleTest do
  use ExUnit.Case, async: true

  alias Fluminus.API.Module

  @id_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSIsImtpZCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSJ9.eyJpc3MiOiJodHRwczovL2x1bWludXMubnVzLmVkdS5zZy92Mi9hdXRoIiwiYXVkIjoidmVyc28iLCJleHAiOjE1NTIwMzQ4ODQsIm5iZiI6MTU1MjAzNDU4NCwibm9uY2UiOiJlYjA0Y2ZmN2U4YTg0YTM0YTlhOWE0YWI3NGU3NzE2NiIsImlhdCI6MTU1MjAzNDU4NCwiYXRfaGFzaCI6Im9RYmFrbkxxeUVPYWtWQV8tMjA2Q1EiLCJjX2hhc2giOiJfMi02T29UYjJJOUpFU2lDZEI2ZGVBIiwic2lkIjoiNTYyZGYxYWYyODRhMDA4MTY1MGE0MDQ4N2NhODAzOTgiLCJzdWIiOiIwMzA4OTI1Mi0wYzk2LTRmYWItYjA4MC1mMmFlYjA3ZWViMGYiLCJhdXRoX3RpbWUiOjE1NTIwMzQ1ODQsImlkcCI6Imlkc3J2IiwiYWRkcmVzcyI6IlJlcXVlc3QgYWxsIGNsYWltcyIsImFtciI6WyJwYXNzd29yZCJdfQ.R54fwml4-KmwaD_pNSJxmf3XXoQdf3coik7-c-Lt7dconpJHLlorsiymQaiGLTlUdvMGHYvN_1JzCi42azkCxF2kjAJiosdCigR3b4okM1sovXoJsbE7tIycx2jpZwCmusL6nMffzE0ly_Q28x55jdQmJ9PIyGe7XD4mfKqDweht4fhCAtoeJtNPeDKX2dG6p4ll0lJxgVBOZsdi8PYF6z_rTt7zmMgd9CSc6WH2sOl8f9FKpVxoGtLBmjEBcNbwODokTu-cgW20vLFc05a7UZa3uKzPZI3DONnUDptLGgatcYGmNDTooQrJdh5xDKrK1tmkgVgBTmvPb44WYIiqHw"
  @authorization %Fluminus.Authorization{jwt: @id_token, client: %Fluminus.HTTPClient{}}
  @module %Module{
    code: "ST2334",
    id: "40582141-1a1d-41b6-ba3a-efa44ff7fd05",
    name: "Probability and Statistics",
    teaching?: false,
    term: "1820",
    valid?: true
  }

  test("from_api") do
    assert Module.from_api(%{
             "id" => "57290e55-335a-4c09-b904-a795572d6cda",
             "name" => "CS1101S",
             "courseName" => "Programming Methodology",
             "access" => %{
               "access_Full" => true,
               "access_Create" => true,
               "access_Update" => true,
               "access_Delete" => true,
               "access_Settings_Read" => true,
               "access_Settings_Update" => true
             },
             "term" => "1820"
           }).valid?
  end

  test "from_api invalid" do
    refute Module.from_api(%{}).valid?

    refute Module.from_api(%{
             "id" => 5,
             "name" => "CS1101S",
             "courseName" => "Programming Methodology",
             "access" => %{
               "access_Full" => true,
               "access_Create" => true,
               "access_Update" => true,
               "access_Delete" => true,
               "access_Settings_Read" => true,
               "access_Settings_Update" => true
             },
             "term" => "1820"
           }).valid?

    refute Module.from_api(%{
             "id" => "5",
             "name" => "CS1101S",
             "courseName" => "Programming Methodology",
             "term" => "1820"
           }).valid?
  end

  test "announcements" do
    assert Module.announcements(@module, @authorization) == [
             {"Mid Term Seating Plan",
              "Dear All,\n\n \n\nThe midterm seating plan is now uploaded in the folder lecture_notes.\n\n \n\nKind Regards,\n\n \n\nA/P Ajay Jasra\n"},
             {"Gaussian CDF and Quantile Tables",
              "Dear All,\n\n \n\nThese have been added to `lecture notes'. I will quickly cover how to use these in our next lecture.\n\n \n\nKind Regards,\n\n \n\nA/P Ajay Jasra\n"},
             {"Mid Term",
              "Date/Time/Venue\nThe mid-semester test will be held on 12th Mar, Tuesday from 2000hrs to 2100 hrs in MPSH2.\n\nTest details\nScope of test -- Chapters: 1 to 2\n\nSeveral multiple choice questions and some short questions, attempt all. Duration: 60 mins.\n \nOthers\nYou are allowed to bring along with you ONE piece of A4 size, two-sided help sheet.\nProgrammable/graphical/scientific calculators are allowed.\n \nMake-up test Policy\nIf you miss the test due to illness, you will be allowed to take a make-up test provided you have a valid medical certificate for the day of test.\nContact me within 24 hrs after the test.\n\nYou will be notified of the details of the make-up test (to be held during week 13) via your NUS email.\n \nShould for any other reason you are not able to take the test, contact me ahead of time before the test (if it is possible). Legitimate reasons include:\n\n\n\tBereavement of immediate family member and burial or cremation takes place on same day and time as test;\n\tStudent is affected by serious trauma caused by crime, accidents or disasters (e.g. fire);\n\tStudent is officially representing the country in an official international competition in which the student has no control over the actual dates of the competition; and\n\tStudent is representing NUS at NUS-recognised University-level competitions, i.e. Universiade (World University Games), AseanUniversity Games and IndianRimAsianUniversity Games (IRAUG).\n\tInvolvement in University level performances. i.e. concerts, plays.\n\n\nNote that Hall activities or driving tests are not considered valid non-medical reasons for missing CA tests.\n"}
           ]
  end

  test "announcements archived" do
    assert Module.announcements(@module, @authorization, true) == []
  end
end
