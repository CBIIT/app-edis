/**
 * User REST Web Service API
 * Enterprise Data & Integration Services Web Services - **NED REST Web Service**
 *
 * The version of the OpenAPI document: 0.1.0
 * Contact: NCICBIITBizAppsSupportLowTier@mail.nih.gov
 *
 * NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).
 * https://openapi-generator.tech
 * Do not edit the class manually.
 */

import { RequestFile } from './models';
import { VDSUser } from './vDSUser';

export class VDSUsersChunk {
    'count'?: number;
    /**
    * Error message if not empty - rest of the fields are zeros
    */
    'error'?: string;
    /**
    * If present, the result is incomplete, pass this value as \"lastEvaluatedKey\" query parameter to get the next chunk of results
    */
    'lastEvaluatedKey'?: string;
    'items'?: Array<VDSUser>;

    static discriminator: string | undefined = undefined;

    static attributeTypeMap: Array<{name: string, baseName: string, type: string}> = [
        {
            "name": "count",
            "baseName": "count",
            "type": "number"
        },
        {
            "name": "error",
            "baseName": "error",
            "type": "string"
        },
        {
            "name": "lastEvaluatedKey",
            "baseName": "lastEvaluatedKey",
            "type": "string"
        },
        {
            "name": "items",
            "baseName": "items",
            "type": "Array<VDSUser>"
        }    ];

    static getAttributeTypeMap() {
        return VDSUsersChunk.attributeTypeMap;
    }
}
