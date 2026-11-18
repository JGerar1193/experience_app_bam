import Ajv2020, { type ValidateFunction } from 'ajv/dist/2020';
import addFormats from 'ajv-formats';
import transferSchema from './transfer.schema.json';

export const contractNames = [
  'LookupRequest',
  'LookupResponse',
  'RecipientRequest',
  'RecipientResponse',
  'RecipientList',
  'QuoteRequest',
  'QuoteResponse',
  'ReserveRequest',
  'ConfirmRequest',
  'CancelRequest',
  'TransferResponse',
  'ReceiptResponse',
  'ErrorResponse',
  'OperationResponse',
] as const;

export type ContractName = (typeof contractNames)[number];

export interface ContractError {
  instancePath: string;
  keyword: string;
  message: string;
}

export type ContractValidation =
  | { valid: true }
  | { valid: false; errors: ContractError[] };

export class ContractValidator {
  private readonly validators = new Map<ContractName, ValidateFunction>();

  constructor() {
    const ajv = new Ajv2020({
      strict: true,
      allErrors: true,
      validateFormats: true,
      coerceTypes: false,
      removeAdditional: false,
      useDefaults: false,
      verbose: false,
    });
    addFormats(ajv);
    ajv.addSchema(transferSchema);

    for (const name of contractNames) {
      const validator = ajv.getSchema(`${transferSchema.$id}#/$defs/${name}`);
      if (!validator) {
        throw new Error(`Missing contract schema: ${name}`);
      }
      this.validators.set(name, validator);
    }
  }

  validate(name: ContractName, payload: unknown): ContractValidation {
    const validator = this.validators.get(name);
    if (!validator) {
      throw new RangeError('Unknown contract schema.');
    }
    if (validator(payload)) {
      return { valid: true };
    }
    return {
      valid: false,
      errors: (validator.errors ?? []).map((error) => ({
        instancePath: error.instancePath,
        keyword: error.keyword,
        message: error.message ?? 'Invalid contract.',
      })),
    };
  }
}