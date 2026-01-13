# Build stage
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /source

# Copy csproj and restore dependencies
COPY *.csproj .
RUN dotnet restore

# Copy everything else and build
COPY . .
RUN dotnet publish -c Release -o /app --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
COPY --from=build /app .

# Expose port
EXPOSE 80
EXPOSE 443

# Set environment variable
ENV ASPNETCORE_URLS=http://+:80

ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
