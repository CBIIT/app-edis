
const conf = {
    nidap: {}
}

function initConfiguration(configuration) {
    Object.assign(conf.nidap, configuration);
}

module.exports = {conf, initConfiguration};