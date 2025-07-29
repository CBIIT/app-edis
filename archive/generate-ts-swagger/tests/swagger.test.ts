import {AppConfig} from "ts-lambda-api";
import path from "path";
import {ApiConsoleApp} from "ts-lambda-api-local";
import {HttpClient, HttpClientResponse} from "typed-rest-client/HttpClient";
import {RestClient} from "typed-rest-client";
// import * as fs from "fs";

let app: ApiConsoleApp;
let httpClient: HttpClient;

describe('Swagger generator test', () => {
    beforeAll(async () => {
        
        let restClient: RestClient = new RestClient("swagger-test", "http://localhost:8080", null, { allowRedirects: false})
        httpClient = restClient.client;
        
        let appConfig = new AppConfig()
        appConfig.name = "User REST Web Service API";
        appConfig.base = "/generatets/v1";
        appConfig.version = "0.1.0";
        appConfig.openApi.enabled = true
        appConfig.openApi.useAuthentication = false

        let controllers: string[] = [ path.join(__dirname, "../dist/controllers")];
        console.log('Paths:', __dirname, controllers[0]);
        app = new ApiConsoleApp(controllers, appConfig);
        await app.runServer([])        
    });

    afterAll(async () => {
        await app.stopServer();
    })
    
    it('Fake test', () => {
        const num: number = 2
        expect(num).toBe(2)
    });
    it('should run and create swagger yml file', async () => {
        let response: HttpClientResponse = await httpClient.get("http://localhost:8080/generatets/v1/open-api.json")
        let body = await response.readBody();
        console.log('Response:', body)
        // fs.writeFileSync(path.join(__dirname, "../../lambda-zip/generate-ts-swagger.yml"), body);
        expect(response).toBeDefined()
    });
})