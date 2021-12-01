using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DemoHostedApp.Controllers
{
    public class Points
    {
        public DateTime Effective { get; set; }
        public DateTime Expires { get; set; }
        public int Value { get; set; }
    }

    public class AnnualPoints
    {
        public string MemberId { get; set; }
        public IList<Points> Points { get; set; }
    }

    [ApiController]
    [Route("[controller]")]
    public class RewardsController : ControllerBase
    {
        private readonly ILogger<RewardsController> _logger;

        public RewardsController(ILogger<RewardsController> logger)
        {
            _logger = logger;
        }

        // Example: https://localhost:49153/Rewards?memberId=1234A&year=2021
        [HttpGet]
        public IActionResult Get(string memberId, int? year)
        {
            if (string.IsNullOrEmpty(memberId) || !year.HasValue)
            {
                return new BadRequestResult();
            }

            if (year > DateTime.UtcNow.Year)
            {
                return new BadRequestResult();
            }

            var response = new AnnualPoints { MemberId = memberId, Points = new List<Points>() };
            var rand = new Random();

            var count = rand.Next(1, 10);

            for (int i = 0; i < count; i++)
            {
                var month = rand.Next(1, 12);
                var effective = new DateTime(year.Value, month, 1);
                response.Points.Add(new Points { Effective = effective, Expires = effective.AddMonths(2), Value = rand.Next(10, 250) });
            }

            return new OkObjectResult(response);
        }
    }
}
