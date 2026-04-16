FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["CoinMaster.API/CoinMaster.API.csproj", "CoinMaster.API/"]
RUN dotnet restore "CoinMaster.API/CoinMaster.API.csproj"
COPY . .
WORKDIR "/src/CoinMaster.API"
RUN dotnet build "CoinMaster.API.csproj" -c Release -o /app/build
RUN dotnet publish "CoinMaster.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "CoinMaster.API.dll"]
