FROM mcr.microsoft.com/powershell
RUN apt-get update
RUN apt-get install azure-cli

CMD ["pwsh"]
