using Microsoft.Data.SqlClient;
using System.Configuration;
using System.Data;

namespace Lab12
{
  class Program
  {
    static async Task Main(string[] args)
    {
      string connectionString = ConfigurationManager.
          ConnectionStrings["DefaultConnection"].ConnectionString;

      // Связный уровень
      using (SqlConnection connection = new SqlConnection(connectionString))
      {
        await connection.OpenAsync();

        // Добавление данных таблицы
        {
          SqlCommand command = new SqlCommand(
              "INSERT INTO Users (Email, Name, PasswordHash) " +
              "VALUES (@email, @name, @passwordHash)", connection);

          command.Parameters.Add(new SqlParameter("@email", "user3@gmail.com"));
          command.Parameters.Add(new SqlParameter("@name", "user3"));
          command.Parameters.Add(new SqlParameter("@passwordHash", "hash"));

          int rowsAffected = await command.ExecuteNonQueryAsync();
          Console.WriteLine($"Добавлено объектов: {rowsAffected}");
        }

        // Обновление данных таблицы
        {
          SqlCommand command = new SqlCommand(
            "UPDATE Users SET BirthDate = @birthDate WHERE Email = @email",
            connection);

          command.Parameters.Add(new SqlParameter("@birthDate", "1990-01-01"));
          command.Parameters.Add(new SqlParameter("@email", "user3@gmail.com"));

          int rowsAffected = await command.ExecuteNonQueryAsync();
          Console.WriteLine($"Обновлено объектов: {rowsAffected}");
        }

        // Удаление данных таблицы
        {
          SqlCommand command = new SqlCommand(
            "DELETE Users WHERE Email = @email", connection);

          command.Parameters.Add(new SqlParameter("@email", "user2@gmail.com"));

          int rowsAffected = await command.ExecuteNonQueryAsync();
          Console.WriteLine($"Удалено объектов: {rowsAffected}");
        }

        // Просмотр содержимого таблицы
        {
          SqlCommand command = new SqlCommand(
              "SELECT * FROM Users", connection);

          using (SqlDataReader reader = await command.ExecuteReaderAsync())
          {
            for (int i = 0; i < reader.FieldCount; i++)
              if (i < reader.FieldCount - 1)
                Console.Write($"{reader.GetName(i)}\t");
              else
                Console.WriteLine($"{reader.GetName(i)}");

            while (await reader.ReadAsync())
            {
              for (int i = 0; i < reader.FieldCount; i++)
                if (i < reader.FieldCount - 1)
                  Console.Write($"{reader.GetValue(i).ToString()}\t");
                else
                  Console.WriteLine($"{reader.GetValue(i).ToString()}");
            }
          }
        }
      }

      // Несвязный уровень
      // ...
    }
  }
}
