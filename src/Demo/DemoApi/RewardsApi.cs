using System;
using System.Collections.Generic;
using System.Net;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Enums;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;

namespace DemoApi
{
    public class Points
    {
        [OpenApiProperty(Description = "Points effective date.")]
        public DateTime Effective { get; set; }

        [OpenApiProperty(Description = "Points expiration date.")]
        public DateTime Expires { get; set; }

        [OpenApiProperty(Description = "Value of points.")]
        public int Value { get; set; }
    }

    public class AnnualPoints
    {
        [OpenApiProperty(Description = "Member Id.")]
        public string MemberId { get; set; }

        [OpenApiProperty(Description = "Collection of Points.")]
        public IList<Points> Points { get; set; }
    }

    public static class RewardsApi
    {
        [FunctionName(nameof(GetMemberAnnualPoints))]
        [OpenApiOperation(operationId: "GetMemberAnnualPointsByMemberIdAndYear", tags: new[] { "Get Member Annual Points By MemberId And Year." })]
        [OpenApiSecurity("api_key", SecuritySchemeType.ApiKey, Name = "x-functions-key", In = OpenApiSecurityLocationType.Header)]
        [OpenApiParameter(name: "memberId", In = ParameterLocation.Path, Required = true, Type = typeof(string), Description = "The **MemberId** parameter")]
        [OpenApiParameter(name: "year", In = ParameterLocation.Path, Required = true, Type = typeof(int), Description = "The **Year** parameter")]
        [OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "application/json", bodyType: typeof(AnnualPoints), Description = "The AnnualPoints response")]
        public static IActionResult GetMemberAnnualPoints(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = "member/{memberId}/year/{year}/points")] HttpRequest req,
            ILogger log,
            string memberId,
            int year)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

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
                var effective = new DateTime(year, month, 1);
                response.Points.Add(new Points { Effective = effective, Expires = effective.AddMonths(2), Value = rand.Next(10, 250) });
            }

            return new OkObjectResult(response);
        }
    }
}

