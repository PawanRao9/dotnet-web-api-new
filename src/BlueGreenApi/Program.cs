var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "Blue-Green Deployment API",
        Version = "v1",
        Description = "A .NET 8 Web API demonstrating Blue-Green deployment with Docker, Nginx, and GitHub Actions."
    });
});

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "Blue-Green API v1");
    options.RoutePrefix = "swagger";
});

app.UseAuthorization();
app.MapControllers();
app.Run();

public partial class Program { }
