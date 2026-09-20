export interface NotificationPreferences {
  emailEnabled: boolean;
  smsEnabled: boolean;
  pushEnabled: boolean;
  shipmentUpdates: boolean;
  slaAlerts: boolean;
  deliveryConfirmations: boolean;
}

const DEFAULT_PREFERENCES: NotificationPreferences = {
  emailEnabled: true,
  smsEnabled: false,
  pushEnabled: true,
  shipmentUpdates: true,
  slaAlerts: true,
  deliveryConfirmations: true,
};

export function getDefaultPreferences(): NotificationPreferences {
  return { ...DEFAULT_PREFERENCES };
}

export function validatePreferences(
  prefs: Partial<NotificationPreferences>
): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (prefs.emailEnabled !== undefined && typeof prefs.emailEnabled !== "boolean") {
    errors.push("emailEnabled must be a boolean");
  }

  if (prefs.smsEnabled !== undefined && typeof prefs.smsEnabled !== "boolean") {
    errors.push("smsEnabled must be a boolean");
  }

  if (prefs.pushEnabled !== undefined && typeof prefs.pushEnabled !== "boolean") {
    errors.push("pushEnabled must be a boolean");
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

export function mergePreferences(
  existing: NotificationPreferences,
  updates: Partial<NotificationPreferences>
): NotificationPreferences {
  const { valid, errors } = validatePreferences(updates);
  if (!valid) {
    throw new Error(`Invalid preferences: ${errors.join(", ")}`);
  }

  return {
    ...existing,
    ...updates,
  };
}

export function hasAnyChannelEnabled(prefs: NotificationPreferences): boolean {
  return prefs.emailEnabled || prefs.smsEnabled || prefs.pushEnabled;
}

export function getEnabledChannels(prefs: NotificationPreferences): string[] {
  const channels: string[] = [];
  if (prefs.emailEnabled) channels.push("email");
  if (prefs.smsEnabled) channels.push("sms");
  if (prefs.pushEnabled) channels.push("push");
  return channels;
}
