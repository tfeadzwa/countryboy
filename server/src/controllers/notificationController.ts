import { AuthenticatedRequest } from '../middleware/auth';
import { Response } from 'express';
import * as notificationService from '../services/notificationService';

export const list = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const notifications = await notificationService.getFleetComplianceNotifications(req.depotId);
    const unreadish = notifications.filter(
      (n) => n.severity === 'expired' || n.severity === 'urgent' || n.severity === 'warning'
    );

    res.json({
      notifications,
      summary: {
        total: notifications.length,
        urgent: notifications.filter((n) => n.severity === 'expired' || n.severity === 'urgent').length,
        warning: notifications.filter((n) => n.severity === 'warning').length,
        monthly: notifications.filter((n) => n.frequency === 'monthly').length,
        weekly: notifications.filter((n) => n.frequency === 'weekly').length,
        daily: notifications.filter((n) => n.frequency === 'daily').length,
        attention_count: unreadish.length,
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Unable to list notifications', details: err });
  }
};
