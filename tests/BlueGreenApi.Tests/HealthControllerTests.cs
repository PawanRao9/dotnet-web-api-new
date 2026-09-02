using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace BlueGreenApi.Tests
{
    public class HealthControllerTests : IClassFixture<WebApplicationFactory<Program>>
    {
        private readonly WebApplicationFactory<Program> _factory;

        public HealthControllerTests(WebApplicationFactory<Program> factory)
        {
            _factory = factory;
        }

        [Fact]
        public async Task GetHealth_ReturnsOkResult_WithExpectedStructure()
        {
            // Arrange
            var client = _factory.CreateClient();

            // Act
            var response = await client.GetAsync("/api/health");

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            
            var content = await response.Content.ReadAsStringAsync();
            using var document = JsonDocument.Parse(content);
            var root = document.RootElement;

            Assert.True(root.TryGetProperty("status", out var status));
            Assert.Equal("Healthy", status.GetString());
            
            Assert.True(root.TryGetProperty("environment", out _));
            Assert.True(root.TryGetProperty("version", out _));
            Assert.True(root.TryGetProperty("timestamp", out _));
            Assert.True(root.TryGetProperty("machineName", out _));
        }

        [Fact]
        public async Task GetHealth_WithEnvironmentVariables_ReturnsOverriddenValues()
        {
            // Arrange
            // Temporarily set environment variables
            Environment.SetEnvironmentVariable("APP_ENVIRONMENT", "TEST_BLUE");
            Environment.SetEnvironmentVariable("APP_VERSION", "9.9.9");

            try
            {
                var client = _factory.CreateClient();

                // Act
                var response = await client.GetAsync("/api/health");
                response.EnsureSuccessStatusCode();

                var content = await response.Content.ReadAsStringAsync();
                using var document = JsonDocument.Parse(content);
                var root = document.RootElement;

                // Assert
                Assert.Equal("TEST_BLUE", root.GetProperty("environment").GetString());
                Assert.Equal("9.9.9", root.GetProperty("version").GetString());
            }
            finally
            {
                // Clean up
                Environment.SetEnvironmentVariable("APP_ENVIRONMENT", null);
                Environment.SetEnvironmentVariable("APP_VERSION", null);
            }
        }
    }
}
