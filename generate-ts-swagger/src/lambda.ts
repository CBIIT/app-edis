// This is the entrypoint for the package
import * as path from "path"
import {ApiLambdaApp, ApiRequest, LogLevel} from "ts-lambda-api";
import {SecretsManager} from "aws-sdk";
import {Config} from "./conf/Config";
import {GetSecretValueRequest} from "aws-sdk/clients/secretsmanager";

const SECRET: string = process.env.SECRET || 'era-commons-connect';

const appConfig = new Config();
const secretsClient = new SecretsManager({ region: 'us-east-1'});

appConfig.base = "/userapi/v1";
appConfig.version = "v1";
appConfig.serverLogger.level = LogLevel.debug;

let configuration;

const controllerPath = [path.join(__dirname, "controllers")];
const app = new ApiLambdaApp(controllerPath, appConfig);

app.configureApp(container => {
    container.bind(Config).toConstantValue(appConfig);
})


export async function handler(event: ApiRequest, context: any) {

    if (!configuration) {
        console.debug('Getting secret parameters...');
        configuration = await getSecretParameters();
        appConfig.initConfiguration(configuration);
    }

    return await app.run(event, context)
}

async function getSecretParameters() {
    const input: GetSecretValueRequest = {
        SecretId: SECRET
    }
    const data = await secretsClient.getSecretValue(input).promise();
    if (data) {
        if (data.SecretString) {
            return JSON.parse(data.SecretString);
        }
    }
    else {
        console.error('SecretsManager Success: NO ERR OR DATA');
        throw new Error('SecretsManager Success: NO ERR OR DATA');
    }
}

// export * from './api/apis';
// export * from './model/models';