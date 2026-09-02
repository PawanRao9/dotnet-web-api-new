using Microsoft.AspNetCore.Mvc;
using BlueGreenApi.Models;

namespace BlueGreenApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private static readonly List<Product> Products =
    [
        new() { Id = 1, Name = "Laptop",     Price = 50000, Description = "High-performance laptop" },
        new() { Id = 2, Name = "Keyboard",   Price = 1500,  Description = "Mechanical keyboard" },
        new() { Id = 3, Name = "Mouse",      Price = 800,   Description = "Wireless mouse" },
        new() { Id = 4, Name = "Monitor",    Price = 25000, Description = "27-inch 4K display" },
        new() { Id = 5, Name = "Headphones", Price = 3000,  Description = "Noise-cancelling headphones" },
    ];

    [HttpGet]
    public IActionResult GetAll() => Ok(Products);

    [HttpGet("{id:int}")]
    public IActionResult GetById(int id)
    {
        var product = Products.FirstOrDefault(p => p.Id == id);
        return product is null
            ? NotFound(new { Message = $"Product with ID {id} not found." })
            : Ok(product);
    }
}
