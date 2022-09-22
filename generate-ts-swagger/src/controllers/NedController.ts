import {inject, injectable} from "inversify"
import {
    api,
    apiController,
    apiOperation,
    apiResponse,
    Controller, controllerNoAuth,
    GET,
    pathParam,
    queryParam
} from "ts-lambda-api"
import {GetNEDChangesByIC200Response} from "../model/getNEDChangesByIC200Response";
import {Client, createClientAsync} from "soap";
const WSSecurity = require("wssecurity");
import {Config} from "../conf/Config";


@apiController("/generatets/v1/ned")
@api("NED APIs Controller", "API endpoints to retrieve data from NED")
@controllerNoAuth
@injectable()
export class NedController extends Controller {
    
    public constructor(@inject(Config) private readonly conf: Config) {
        super();
    }

    // soapClient: Client;
    soapClientForChanges: Client;
    wsSecurity_v7;        // Soap security


    @GET("/changesByIc/:ic")
    @apiOperation({ name: "List NED Changes for the given IC", description: "List NED Change records that satisfy given IC criteria"})
    @apiResponse(200, {class: GetNEDChangesByIC200Response  })
    public async  getChangesByIC(
        @pathParam("ic") ic: string,
        @queryParam("fromDate") fromDate?: string,
        @queryParam("fromTime") fromTime?: string,
        @queryParam("toDate") toDate?: string,
        @queryParam("toTime") toTime?: string,
        @queryParam("Testing") Testing?: boolean) {
        try {
            if (Testing) {
                console.info(`Return in Testing mode - no actual call is performed`);
                return {'Success': true};
            }
            
            return await this._getChangesByIc(ic, fromDate, fromTime, toDate, toTime);

        } catch (error) {
            console.error(error);
            this.response.status(500).send(error);
        }
    }

    private async _getChangesByIc(ic: string, fromDate?: string, fromTime?: string, toDate?: string, toTime?: string) : Promise<GetNEDChangesByIC200Response> {
        console.info(`Getting NED changes by IC`, ic, fromDate, fromTime, toDate, toTime);
        const args: any = {
            ICorSITE: ic,
            From_Date: fromDate,
        };
        if (fromTime) {
            args['From_time'] = fromTime;
        }
        if (toDate) {
            args['To_Date'] = toDate;
        }
        if (toTime) {
            args['To_time'] = toTime;
        }
        console.debug(`Continue in real mode `, args);
        const client = await this._getSoapClientForNedChanges();
        const result = await client.ByICAsync(args);
        return (Array.isArray(result) && result.length > 0) ? result[0] : result;
    }

    // async _getSoapClientForNed() {
    //     if (!this.soapClient) {
    //         this.soapClient = await createClientAsync(this.conf.ned.wsdl);
    //         this.soapClient.setSecurity(this._getWsSecurity_v7());
    //     }
    //     return this.soapClient;
    // }
    
    async _getSoapClientForNedChanges() {
        if (!this.soapClientForChanges) {
            this.soapClientForChanges = await createClientAsync(this.conf.ned.wsdl_changes);
            this.soapClientForChanges.setSecurity(this._getWsSecurity_v7());
        }
        return this.soapClientForChanges;
    }
    
    _getWsSecurity_v7() {
        if (!this.wsSecurity_v7) {
            this.wsSecurity_v7 = new WSSecurity(this.conf.ned.user, this.conf.ned.pwd);
        }
        return this.wsSecurity_v7;
    }

}
    