import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import Stripe from "stripe";

admin.initializeApp();

const db = admin.firestore();
const stripeSecretKey = process.env.STRIPE_SECRET_KEY;

if (!stripeSecretKey) {
  console.warn("STRIPE_SECRET_KEY env var is missing.");
}

const stripe = stripeSecretKey
  ? new Stripe(stripeSecretKey, {
      apiVersion: "2024-06-20",
    })
  : null;

type CreateBookingInput = {
  propertyId: string;
  startDate: string;
  endDate: string;
  guests?: number;
};

type ExistingBooking = {
  startDate: admin.firestore.Timestamp;
  endDate: admin.firestore.Timestamp;
  status: string;
};

export const createBooking = onCall<CreateBookingInput>(
  {
    region: "europe-west1",
    cors: true,
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "User must be authenticated.");
    }
    if (!stripe) {
      throw new HttpsError(
        "failed-precondition",
        "Stripe is not configured in Cloud Functions."
      );
    }

    const { propertyId, startDate, endDate, guests = 1 } = request.data;
    if (!propertyId || !startDate || !endDate) {
      throw new HttpsError("invalid-argument", "Missing booking fields.");
    }

    const start = parseDateOrThrow(startDate, "startDate");
    const end = parseDateOrThrow(endDate, "endDate");
    const nights = Math.round((end.getTime() - start.getTime()) / 86400000);

    if (nights <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "endDate must be later than startDate."
      );
    }

    const propertyDoc = await db.collection("properties").doc(propertyId).get();
    if (!propertyDoc.exists) {
      throw new HttpsError("not-found", "Property was not found.");
    }

    const property = propertyDoc.data() ?? {};
    const nightlyPrice = parsePositiveInteger(property.nightlyPrice, "nightlyPrice");
    const cleaningFee = parseNonNegativeInteger(property.cleaningFee ?? 150, "cleaningFee");
    const serviceFee = parseNonNegativeInteger(property.serviceFee ?? 300, "serviceFee");
    const currency = String(property.currency ?? "eur").toLowerCase();

    const activeBookingsSnap = await db
      .collection("bookings")
      .where("propertyId", "==", propertyId)
      .where("status", "in", ["paid", "confirmed"])
      .get();

    const hasOverlap = activeBookingsSnap.docs.some((doc) => {
      const data = doc.data() as ExistingBooking;
      if (!data.startDate || !data.endDate) return false;
      return rangesOverlap(start, end, data.startDate.toDate(), data.endDate.toDate());
    });

    if (hasOverlap) {
      throw new HttpsError(
        "already-exists",
        "Selected dates are no longer available."
      );
    }

    const subtotal = nightlyPrice * nights;
    const totalAmount = subtotal + cleaningFee + serviceFee;
    const amountInCents = totalAmount * 100;

    if (amountInCents <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Calculated payment amount is invalid."
      );
    }

    const bookingId = db.collection("bookings").doc().id;
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInCents,
      currency,
      automatic_payment_methods: { enabled: true },
      metadata: {
        bookingId,
        propertyId,
        userId: request.auth.uid,
        startDate,
        endDate,
        nights: String(nights),
        guests: String(guests),
      },
    });

    if (!paymentIntent.client_secret) {
      throw new HttpsError(
        "internal",
        "Stripe did not return a payment intent client secret."
      );
    }

    return {
      bookingId,
      currency,
      nightlyPrice,
      cleaningFee,
      serviceFee,
      nights,
      totalAmount,
      paymentIntentId: paymentIntent.id,
      paymentIntentClientSecret: paymentIntent.client_secret,
    };
  }
);

function parseDateOrThrow(value: string, fieldName: string): Date {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new HttpsError("invalid-argument", `${fieldName} is not a valid ISO date.`);
  }
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function parsePositiveInteger(value: unknown, fieldName: string): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0 || !Number.isInteger(parsed)) {
    throw new HttpsError(
      "failed-precondition",
      `${fieldName} must be a positive integer in property data.`
    );
  }
  return parsed;
}

function parseNonNegativeInteger(value: unknown, fieldName: string): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 0 || !Number.isInteger(parsed)) {
    throw new HttpsError(
      "failed-precondition",
      `${fieldName} must be a non-negative integer.`
    );
  }
  return parsed;
}

function rangesOverlap(
  startA: Date,
  endA: Date,
  startB: Date,
  endB: Date
): boolean {
  const normalizedStartB = new Date(
    Date.UTC(startB.getUTCFullYear(), startB.getUTCMonth(), startB.getUTCDate())
  );
  const normalizedEndB = new Date(
    Date.UTC(endB.getUTCFullYear(), endB.getUTCMonth(), endB.getUTCDate())
  );
  return startA < normalizedEndB && endA > normalizedStartB;
}
