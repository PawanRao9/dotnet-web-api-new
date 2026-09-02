using Microsoft.AspNetCore.Mvc;

namespace BlueGreenApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController(IConfiguration configuration) : ControllerBase
{
    [HttpGet]
    public IActionResult GetHealth()
    {
        var environment = Environment.GetEnvironmentVariable("APP_ENVIRONMENT")
                          ?? configuration["AppSettings:Environment"]
                          ?? "UNKNOWN";

        var version = Environment.GetEnvironmentVariable("APP_VERSION")
                      ?? configuration["AppSettings:Version"]
                      ?? "0.0.0";

        return Ok(new
        {
            Status = "Healthy",
            Environment = environment,
            Version = version,
            Timestamp = DateTime.UtcNow.ToString("o"),
            MachineName = Environment.MachineName
        });
    }
}
