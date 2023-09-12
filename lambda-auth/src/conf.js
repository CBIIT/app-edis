
const conf = {
    ad: {
        serviceAccountsBase: 'ou=serviceaccounts,ou=ops,ou=nci,ou=nih,ou=ad,dc=nih,dc=gov',
        userAccountsBase: 'ou=Users,ou=NCI,ou=NIH,ou=AD,dc=nih,dc=gov',
    }
};

function initConfiguration(configuration) {
    conf.ad.cert = configuration.ad_cert;
    conf.ad.host = configuration.ad_auth_host;
}

module.exports = { conf, initConfiguration };
