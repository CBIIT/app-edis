import * as path from "path"
import { ApiConsoleApp } from "ts-lambda-api-local"
import {AppConfig, LogLevel} from "ts-lambda-api";

let appConfig = new AppConfig()

appConfig.name = "User REST Web Service API";
appConfig.base = "/generatets/v1";
appConfig.version = "0.1.0";
appConfig.openApi.enabled = true
appConfig.openApi.useAuthentication = false

let controllers: string[] = [ path.join(__dirname, "./controllers")];
let app = new ApiConsoleApp(controllers, appConfig);
app.runServer(process.argv)