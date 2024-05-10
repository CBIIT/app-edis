
const conf = {
    nidap: {}
}

function initConfiguration(configuration) {
    Object.assign(conf.nidap, configuration);
}

export {conf, initConfiguration};