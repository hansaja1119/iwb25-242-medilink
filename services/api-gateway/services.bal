import ballerina/http;

# Service client configuration
public type GatewayServiceClient record {|
    # HTTP client for making requests
    http:Client httpClient;
    # Base URL of the service
    string baseUrl;
|};

# Service manager for handling service forwarding
public class ApiGatewayServiceManager {
    private map<GatewayServiceClient> clients = {};

    public function init(ServiceUrls serviceConfig) returns error? {
        // Initialize user service client
        http:Client userClient = check new (serviceConfig.userService);
        self.clients["user"] = {
            httpClient: userClient,
            baseUrl: serviceConfig.userService
        };

        // Initialize appointment service client
        http:Client appointmentClient = check new (serviceConfig.appointmentService);
        self.clients["appointment"] = {
            httpClient: appointmentClient,
            baseUrl: serviceConfig.appointmentService
        };

        // Initialize lab report service client
        http:Client labReportClient = check new (serviceConfig.labReportService);
        self.clients["labReport"] = {
            httpClient: labReportClient,
            baseUrl: serviceConfig.labReportService
        };
    }

    # Get service client by name
    # + serviceName - Name of the service
    # + return - Service client or error
    public function getServiceClient(string serviceName) returns GatewayServiceClient|error {
        GatewayServiceClient? serviceClient = self.clients[serviceName];
        if serviceClient is GatewayServiceClient {
            return serviceClient;
        }
        return error(string `Service client not found: ${serviceName}`);
    }
}
