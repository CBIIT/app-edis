
const conf = {
    vds: {
        userAttributes: [
            'UNIQUEIDENTIFIER',
            'NIHDUPUID',
            'NIHADACCTREQ',
            'NIHSSOUSERNAME',
            'distinguishedName',
            'NIHADMAILBOXREQ',
            'NIHPRIMARYSMTP',
            'MAIL',
            'proxyAddresses',
            'displayName',
            'PERSONALTITLE',
            'GIVENNAME',
            'NIHCOMMONGIVENNAME',
            'NIHNOMIDDLENAME',
            'MIDDLENAME',
            'NIHCOMMONMIDDLENAM',
            'NIHMIXCASESN',
            'NIHMIXCASECOMMONSN',
            'SN',
            'NIHCOMMONSN',
            'GENERATIONQUALIF',
            'NIHCOMMONGENQUALIF',
            'NIHSUFFIXQUALIFIER',
            'TITLE',
            'NIHIPD',
            'NIHBADGETITLE',
            'NIHIDBADGEEXPDATE',
            'NIHSAC',
            'NIHPrivacyAwarenessCompDate',
            'PrivacyAwarenessRefresherCompDate',
            'NIHInformationSecurityAwarenessCompDate',
            'InformationSecurityRefresherCompDate',
            'description',
            'ORGANIZATIONALSTAT',
            'NIHSUBORGSTATUS',
            'NIHSUMMERSTATUS',
            'NIHORGPATH',
            'NIHPHYSICALADDRESS',
            'NIHORGACRONYM',
            'NIHSERVAO',
            'MANAGER',
            'NIHCOTRID',
            'NIHPOC',
            'NIHCOMPANYNAME',
            'NIHCOMPANYPHONE',
            'countryCode',
            'TELEPHONENUMBER',
            'MOBILETELEPHONENUM',
            'mobile',
            'ipPhone',
            'NIHSITE',
            'L',
            'BUILDINGNAME',
            'ROOMNUMBER',
            'POSTALADDRESS',
            'NIHIDBADGELESS6MOS',
            'managedObjects',
            'memberOf',
            'NIHCREATETIMESTAMP',
            'NIHCREATORSNAME',
            'NIHMODIFYTIMESTAMP',
            'NIHMODIFIERSNAME',
            'NIHDIRENTRYEFFECTIVEDATE',
            'NIHDIRENTRYEXPIRATIONDATE',
            'userAccountControl' // Ming added 2021-06-09 for usersLocal GraphQL query
        ],
        excludedAttributes: [
            'createTimeStamp',
            'modifyTimeStamp',
            'uSNChanged',
            'lastLogon',
            'whenChanged',
            'logonCount',
            'lastLogonTimestamp',
            'lockoutTime',
            'userCertificate',
            'homeDrive',
            'ADPROVISIONERHHSID',
            'subschemaSubentry',
            'badPasswordTime',
            'MBPROVISIONERHHSID',
            'MBLASTUPDATEDATE',
            'NIHDIRENTRYNOPRINT',
            'badPwdCount',
            'whenCreated',
            'objectclass',
            'objectSid',
            'unixHomeDirectory',
            'MBPROVISIONTYPECD'
        ],
        searchBase: 'ou=Users,ou=NIH,ou=NIHInternalview,ou=NIHViews',
        base64LdapFields: [
            'objectGUID',
            'mS-DS-ConsistencyGuid',
            'msExchArchiveGUID',
            'msRTCSIP-UserRoutingGroupId',
            'msExchMailboxGuid',
            'objectSid',
            'userCertificate',
            'msExchSafeSendersHash',
            'msExchUMSpokenName',
            'userSMIMECertificate',
            'msRTCSIP-UserRoutingGroupId',
            'thumbnailPhoto'
        ]
    },
    ned: {}
} 

function initConfiguration(configuration) {
    conf.ned.wsdl = configuration.ned_wsdl;
    conf.ned.wsdl_changes = configuration.ned_wsdl_changes;
    conf.ned.user = configuration.ned_user;
    conf.ned.pwd = configuration.ned_pwd;
    conf.vds.cert = configuration.vds_cert;
    conf.vds.dn = configuration.vds_dn;
    conf.vds.pwd = configuration.vds_pwd;
    conf.vds.host = configuration.vds_host;
}

module.exports = { initConfiguration, conf }
