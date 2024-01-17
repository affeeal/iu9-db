using Microsoft.Data.SqlClient;
using System.Configuration;
using System.Data;

namespace Lab12
{
  class Program
  {
    static void Main(string[] args)
    {
      string connectionString = ConfigurationManager.
          ConnectionStrings["DefaultConnection"].ConnectionString;
      
      // testConnectedLayer(connectionString);
      // testDisconnectedLayer(connectionString);
    }

    static void testConnectedLayer(string connectionString)
    {
      using (SqlConnection connection = new SqlConnection(connectionString))
      {
        connection.Open();

        // Добавление данных таблицы
        {
          SqlCommand command = new SqlCommand(
              "INSERT INTO Users (Email, Name, PasswordHash) " +
              "VALUES (@Email, @Name, @PasswordHash); " +
              "SELECT SCOPE_IDENTITY()", connection);
          command.Parameters.Add(new SqlParameter("@Email", "user3@gmail.com"));
          command.Parameters.Add(new SqlParameter("@Name", "user3"));
          command.Parameters.Add(new SqlParameter("@PasswordHash", "hash"));

          object result = command.ExecuteScalar();
          
          Console.WriteLine($"Id добавленного объекта: {result}");
        }

        // Обновление данных таблицы
        {
          SqlCommand command = new SqlCommand(
            "UPDATE Users SET BirthDate = @BirthDate WHERE Id = @Id",
            connection);
          command.Parameters.Add(new SqlParameter("@BirthDate", "1990-01-01"));
          command.Parameters.Add(new SqlParameter("@Id", 1));

          command.ExecuteNonQuery();
        }

        // Удаление данных таблицы
        {
          SqlCommand command = new SqlCommand(
            "DELETE Users WHERE Email = @Email", connection);
          command.Parameters.Add(new SqlParameter("@Email", "user2@gmail.com"));

          command.ExecuteNonQuery();
        }

        // Просмотр содержимого таблицы
        {
          SqlCommand command = new SqlCommand(
              "SELECT * FROM Users", connection);
          using (SqlDataReader reader = command.ExecuteReader())
          {
            for (int i = 0; i < reader.FieldCount; i++)
              Console.Write($"{reader.GetName(i)}\t");
            Console.WriteLine();

            while (reader.Read())
            {
              for (int i = 0; i < reader.FieldCount; i++)
                Console.Write($"{reader.GetValue(i).ToString()}\t");
              Console.WriteLine();
            }
          }
        }
      }
    }

    static void testDisconnectedLayer(string connectionString)
    {
      using (SqlConnection connection = new SqlConnection(connectionString))
      {
        using (SqlDataAdapter adapter = new SqlDataAdapter(
            "SELECT * FROM Users", connection))
        {
          adapter.MissingSchemaAction = MissingSchemaAction.AddWithKey;
          
          adapter.InsertCommand = new SqlCommand(
              "INSERT Users (Email, Name, PasswordHash) " +
              "VALUES (@Email, @Name, @PasswordHash); " +
              "SET @Id = SCOPE_IDENTITY()", connection);
          adapter.InsertCommand.Parameters.Add(
              "@Email", SqlDbType.NVarChar, 320, "Email");
          adapter.InsertCommand.Parameters.Add(
              "@Name", SqlDbType.NVarChar, 50, "Name");
          adapter.InsertCommand.Parameters.Add(
              "@PasswordHash", SqlDbType.NVarChar, 100, "PasswordHash");
          SqlParameter idParameter = adapter.InsertCommand.Parameters.Add(
              "@Id", SqlDbType.Int);
          idParameter.Direction = ParameterDirection.Output;

          // TODO: fix with SourceColumn?

          adapter.UpdateCommand = new SqlCommand(
              "UPDATE Users SET BirthDate = @BirthDate WHERE Id = @Id",
              connection);
          adapter.UpdateCommand.Parameters.Add(
              "@BirthDate", SqlDbType.Date, 0, "BirthDate");
          SqlParameter parameter = adapter.UpdateCommand.Parameters.Add(
              "@Id", SqlDbType.Int, 0, "Id");
          parameter.SourceVersion = DataRowVersion.Original;

          adapter.DeleteCommand = new SqlCommand(
              "DELETE Users WHERE Email = @Email", connection);
          parameter = adapter.DeleteCommand.Parameters.Add(
              "@Email", SqlDbType.NVarChar, 320, "Email");
          parameter.SourceVersion = DataRowVersion.Original;

          DataTable usersTable = new DataTable();
          adapter.Fill(usersTable);

          // Добавление данных
          DataRow newRow = usersTable.NewRow();
          newRow["Email"] = "user3@gmail.com";
          newRow["Name"] = "user3";
          newRow["PasswordHash"] = "hash";
          newRow["BirthDate"] = "2006-01-17";
          newRow["AvatarPath"] = "default_avatar.jpg";
          usersTable.Rows.Add(newRow);

          // Обновление данных
          DataRow user1Row = usersTable.Rows[0];
          user1Row["BirthDate"] = "1990-01-01";

          // Удаление данных
          usersTable.Rows[1].Delete();

          adapter.Update(usersTable);

          Console.WriteLine($"Id добавленного объекта: {idParameter.Value}");

          // Просмотр содержимого таблицы
          using (DataTableReader reader = usersTable.CreateDataReader())
          {
            for (int i = 0; i < reader.FieldCount; i++)
              Console.Write($"{reader.GetName(i)}\t");
            Console.WriteLine();

            while (reader.Read())
            {
              for (int i = 0; i < reader.FieldCount; i++)
                Console.Write($"{reader.GetValue(i).ToString()}\t");
              Console.WriteLine();
            }
          }
        }
      }
    }
  }
}
