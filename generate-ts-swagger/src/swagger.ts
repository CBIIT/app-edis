import * as path from "path"
import { ApiConsoleApp } from "ts-lambda-api-local"
import {AppConfig, LogLevel} from "ts-lambda-api";
import {RestClient} from "typed-rest-client";
import {HttpClientResponse} from "typed-rest-client/HttpClient";
import * as fs from "fs";

const args = process.argv.slice(2)
console.log('ARGUMENTS:', args)
const OUTPUT_PATH = (args && args.length > 0) ? args[0] : '../out'

const table = args[0];

let appConfig = new AppConfig()

appConfig.name = "User REST Web Service API";
appConfig.base = "/generatets/v1";
appConfig.version = "0.1.0";
appConfig.openApi.enabled = true
appConfig.openApi.useAuthentication = false

let controllers: string[] = [ path.join(__dirname, "./controllers")];
let app = new ApiConsoleApp(controllers, appConfig);
let restClient: RestClient = new RestClient("swagger-test", "http://localhost:8080", null, { allowRedirects: false})
let httpClient = restClient.client;

async function generate() {
    await app.runServer([])
    let response: HttpClientResponse = await httpClient.get("http://localhost:8080/generatets/v1/open-api.yml")
    let body = await response.readBody();
    console.log('Response:', body)
    fs.writeFileSync(path.join(__dirname, OUTPUT_PATH + "/generate-ts-swagger.yml"), body);
    await app.stopServer();
}

generate();