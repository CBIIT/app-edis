// This is the entrypoint for the package
import * as path from "path"
import {ApiLambdaApp, ApiRequest, LogLevel} from "ts-lambda-api";
import {GetSecretValueCommand, SecretsManagerClient, GetSecretValueCommandInput} from "@aws-sdk/client-secrets-manager";
import {Config} from "./conf/Config";

const SECRET: string = process.env.SECRET || 'era-commons-connect';

const appConfig = new Config();
const secretsClient = new SecretsManagerClient({ region: 'us-east-1'});

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
    const input: GetSecretValueCommandInput = {
        SecretId: SECRET
    }
    const command = new GetSecretValueCommand(input);
    const data = await secretsClient.send(command);
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