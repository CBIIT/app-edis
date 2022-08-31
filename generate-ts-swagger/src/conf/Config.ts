import {AppConfig} from "ts-lambda-api";
import {injectable} from "inversify";

@injectable()
export class Config extends AppConfig{
    
    public ned?: NedConfig;

    public initConfiguration(configuration: any): void {
        this.ned = new NedConfig();
        this.ned.wsdl = configuration.ned_wsdl;
        this.ned.wsdl_changes = configuration.ned_wsdl_changes;
        this.ned.user = configuration.ned_user;
        this.ned.pwd = configuration.ned_pwd;
    }
}

export class NedConfig {
    
    wsdl?: string;
    wsdl_changes?: string;
    user?: string;
    pwd?: string;
}