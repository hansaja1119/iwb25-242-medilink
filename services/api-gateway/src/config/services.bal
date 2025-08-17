import ballerina/http;

# Service URLs configuration
public type ServiceUrls record {|
    # User service URL
    string userService;
    # Appointment service URL
    string appointmentService;
    # Lab report service URL
    string labReportService;
|};

# Service client configuration
public type ServiceClient record {|
    # HTTP client for making requests
    http:Client httpClient;
    # Base URL of the service
    string baseUrl;
|};

# Service manager to handle all service clients
public class ServiceManager {
    private map<ServiceClient> services = {};

    # Initialize service manager with service URLs
    # + serviceConfig - Service URLs configuration
    public function init(ServiceUrls serviceConfig) returns error? {
        // Initialize user service client
        http:Client userClient = check new (serviceConfig.userService);
        self.services["user"] = {
            httpClient: userClient,
            baseUrl: serviceConfig.userService
        };

        // Initialize appointment service client
        http:Client appointmentClient = check new (serviceConfig.appointmentService);
        self.services["appointment"] = {
            httpClient: appointmentClient,
            baseUrl: serviceConfig.appointmentService
        };

        // Initialize lab report service client
        http:Client labReportClient = check new (serviceConfig.labReportService);
        self.services["labReport"] = {
            httpClient: labReportClient,
            baseUrl: serviceConfig.labReportService
        };
    }

    # Get service client by name
    # + serviceName - Name of the service
    # + return - Service client or error if not found
    public function getServiceClient(string serviceName) returns ServiceClient|error {
        ServiceClient? serviceClient = self.services[serviceName];
        if serviceClient is ServiceClient {
            return serviceClient;
        }
        return error(string `Service client not found: ${serviceName}`);
    }

    # Forward request to a service
    # + serviceName - Name of the target service
    # + path - Path to forward to
    # + method - HTTP method
    # + request - Request message
    # + return - Response from the service
public remote function forwardRequest(string serviceName, string path, string method, http:Request request)
        returns http:Response|error {
        ServiceClient serviceClient = check self.getServiceClient(serviceName);

        match method.toUpperAscii() {
            "GET" => {
                return serviceClient.httpClient->get(path);
            }
            "POST" => {
                return serviceClient.httpClient->post(path, request);
            }
            "PUT" => {
                return serviceClient.httpClient->put(path, request);
            }
            "DELETE" => {
                return serviceClient.httpClient->delete(path, request);
            }
            "PATCH" => {
                return serviceClient.httpClient->patch(path, request);
            }
            _ => {
                return error(string `Unsupported HTTP method: ${method}`);
            }
        }
    }
}
