import prisma from './prisma';

const deviceInclude = {
  depot: { select: { id: true, name: true, merchant_code: true } },
} as const;

export const resolveDeviceFromToken = async (token?: string) => {
  if (!token?.trim()) return null;
  const device = await prisma.tblDevices.findUnique({
    where: { token: token.trim() },
    include: deviceInclude,
  });
  // Unpaired devices must not authenticate with an old token.
  if (!device?.paired) return null;
  return device;
};

export const resolveDeviceFromId = async (deviceId?: string) => {
  if (!deviceId?.trim()) return null;
  return prisma.tblDevices.findUnique({
    where: { id: deviceId.trim() },
    include: deviceInclude,
  });
};

/** Resolve a paired device from token header, or device_id body when token is absent. */
export const resolveDeviceForLogin = async (params: {
  token?: string;
  deviceId?: string;
}) => {
  const { token, deviceId } = params;
  const fromToken = await resolveDeviceFromToken(token);
  if (fromToken) return fromToken;

  if (token?.trim()) return null;

  const fromId = await resolveDeviceFromId(deviceId);
  if (fromId?.paired) return fromId;
  return null;
};
