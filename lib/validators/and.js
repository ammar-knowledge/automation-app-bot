const { Validator } = require('./validator')
const logicalConnectiveValidatorProcessor = require('./lib/logicalConnectiveValidatorProcessor')

class And extends Validator {
  constructor () {
    super('and')
    this.supportedEvents = [
      '*'
    ]
    this.supportedOptions = [
      'validate'
    ]
    this.supportedSettings = {}
  }

  async validate (context, validationSettings, registry) {
    return logicalConnectiveValidatorProcessor(context, validationSettings.validate, registry, 'And')
  }

  // skip validating settings
  validateSettings (supportedSettings, settingToCheck) {}
}

module.exports = And
