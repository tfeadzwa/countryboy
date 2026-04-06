import bcryptjs from 'bcryptjs';
import { promisify } from 'util';

const hash = (...args: any[]) => promisify(bcryptjs.hash as any)(...args);
const compare = (...args: any[]) => promisify(bcryptjs.compare as any)(...args);
const genSalt = (...args: any[]) => promisify(bcryptjs.genSalt as any)(...args);

export default {
  hash,
  compare,
  genSalt,
};
