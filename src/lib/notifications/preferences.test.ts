import { describe, it, expect } from "vitest";
import {
  getDefaultPreferences,
  validatePreferences,
  mergePreferences,
  hasAnyChannelEnabled,
  getEnabledChannels,
} from "./preferences";

describe("notification preferences", () => {
  describe("getDefaultPreferences", () => {
    it("should return default preferences", () => {
      const prefs = getDefaultPreferences();
      expect(prefs.emailEnabled).toBe(true);
      expect(prefs.smsEnabled).toBe(false);
      expect(prefs.pushEnabled).toBe(true);
      expect(prefs.shipmentUpdates).toBe(true);
    });
  });

  describe("validatePreferences", () => {
    it("should accept valid preferences", () => {
      const result = validatePreferences({ emailEnabled: true });
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it("should reject invalid types", () => {
      const result = validatePreferences({ emailEnabled: "yes" as any });
      expect(result.valid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
    });
  });

  describe("mergePreferences", () => {
    it("should merge updates with existing", () => {
      const existing = getDefaultPreferences();
      const updated = mergePreferences(existing, { smsEnabled: true });
      expect(updated.smsEnabled).toBe(true);
      expect(updated.emailEnabled).toBe(true);
    });

    it("should throw on invalid input", () => {
      const existing = getDefaultPreferences();
      expect(() => mergePreferences(existing, { emailEnabled: "no" as any })).toThrow();
    });
  });

  describe("hasAnyChannelEnabled", () => {
    it("should return true when any channel enabled", () => {
      expect(hasAnyChannelEnabled({ ...getDefaultPreferences(), emailEnabled: true })).toBe(true);
    });

    it("should return false when all disabled", () => {
      expect(
        hasAnyChannelEnabled({
          ...getDefaultPreferences(),
          emailEnabled: false,
          smsEnabled: false,
          pushEnabled: false,
        })
      ).toBe(false);
    });
  });

  describe("getEnabledChannels", () => {
    it("should return enabled channels", () => {
      const channels = getEnabledChannels({
        ...getDefaultPreferences(),
        emailEnabled: true,
        smsEnabled: false,
        pushEnabled: true,
      });
      expect(channels).toContain("email");
      expect(channels).toContain("push");
      expect(channels).not.toContain("sms");
    });
  });
});
