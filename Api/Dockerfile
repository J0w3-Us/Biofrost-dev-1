FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore
COPY ["src/IntegradorHub.API/IntegradorHub.API.csproj", "src/IntegradorHub.API/"]
RUN dotnet restore "src/IntegradorHub.API/IntegradorHub.API.csproj"

# Copy full source and build
COPY . .
WORKDIR "/src/src/IntegradorHub.API"
RUN dotnet build "IntegradorHub.API.csproj" -c Release -o /app/build

# Publish
FROM build AS publish
RUN dotnet publish "IntegradorHub.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Final stage/image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Important for Render
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "IntegradorHub.API.dll"]
