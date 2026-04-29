import { collection, getDocs, query, where, limit, orderBy, doc, getDoc } from "firebase/firestore"
import { db } from "@/lib/firebase"
import type { CatalogProduct } from "@/lib/catalog"

/* ═══════════════════════════════════════════════════════════
   In-Memory Firestore Cache
   ─────────────────────────────────────────────────────────
   Caches Firestore query results in memory to avoid redundant
   network requests during client-side navigation.
   
   TTL (Time-To-Live): 5 minutes by default.
   ═══════════════════════════════════════════════════════════ */

const DEFAULT_TTL = 5 * 60 * 1000 // 5 minutes

interface CacheEntry<T> {
  data: T
  timestamp: number
  ttl: number
}

const cache = new Map<string, CacheEntry<unknown>>()

function getCacheEntry<T>(key: string): T | null {
  const entry = cache.get(key) as CacheEntry<T> | undefined
  if (!entry) return null
  if (Date.now() - entry.timestamp > entry.ttl) {
    cache.delete(key)
    return null
  }
  return entry.data
}

function setCacheEntry<T>(key: string, data: T, ttl = DEFAULT_TTL): void {
  cache.set(key, { data, timestamp: Date.now(), ttl })
}

/** Clear all cache entries or a specific key */
export function invalidateCache(key?: string): void {
  if (key) {
    cache.delete(key)
  } else {
    cache.clear()
  }
}

/* ═══════════════════════════════════════════════════════════
   Cached Query Functions
   ═══════════════════════════════════════════════════════════ */

/** Fetch all products (cached) */
export async function getAllProducts(): Promise<CatalogProduct[]> {
  const cacheKey = "all-products"
  const cached = getCacheEntry<CatalogProduct[]>(cacheKey)
  if (cached) return cached

  const q = query(collection(db, "products"))
  const snapshot = await getDocs(q)
  const products: CatalogProduct[] = []
  snapshot.forEach((d) => {
    products.push({ id: d.id, ...d.data() } as CatalogProduct)
  })

  setCacheEntry(cacheKey, products)
  return products
}

/** Fetch products by category (cached) */
export async function getProductsByCategory(category: string): Promise<CatalogProduct[]> {
  const cacheKey = `products-category-${category}`
  const cached = getCacheEntry<CatalogProduct[]>(cacheKey)
  if (cached) return cached

  const q = query(collection(db, "products"), where("category", "==", category))
  const snapshot = await getDocs(q)
  const products: CatalogProduct[] = []
  snapshot.forEach((d) => {
    products.push({ id: d.id, ...d.data() } as CatalogProduct)
  })

  setCacheEntry(cacheKey, products)
  return products
}

/** Fetch trending products (cached) */
export async function getTrendingProducts(maxCount = 4): Promise<CatalogProduct[]> {
  const cacheKey = `trending-products-${maxCount}`
  const cached = getCacheEntry<CatalogProduct[]>(cacheKey)
  if (cached) return cached

  const q = query(
    collection(db, "products"),
    where("isTrending", "==", true),
    limit(maxCount)
  )
  const snapshot = await getDocs(q)
  const products: CatalogProduct[] = []
  snapshot.forEach((d) => {
    products.push({ id: d.id, ...d.data() } as CatalogProduct)
  })

  setCacheEntry(cacheKey, products)
  return products
}

/** Fetch new arrival products (cached) */
export async function getNewArrivalProducts(): Promise<CatalogProduct[]> {
  const cacheKey = "new-arrival-products"
  const cached = getCacheEntry<CatalogProduct[]>(cacheKey)
  if (cached) return cached

  const q = query(collection(db, "products"), where("isNewArrival", "==", true))
  const snapshot = await getDocs(q)
  const products: CatalogProduct[] = []
  snapshot.forEach((d) => {
    products.push({ id: d.id, ...d.data() } as CatalogProduct)
  })

  setCacheEntry(cacheKey, products)
  return products
}

/** Fetch a single product by slug (cached) */
export async function getProductBySlug(slug: string): Promise<{ id: string; data: Record<string, unknown> } | null> {
  const cacheKey = `product-slug-${slug}`
  const cached = getCacheEntry<{ id: string; data: Record<string, unknown> }>(cacheKey)
  if (cached) return cached

  // Try slug field first
  const slugQuery = query(collection(db, "products"), where("slug", "==", slug))
  const slugSnap = await getDocs(slugQuery)

  if (!slugSnap.empty) {
    const docSnap = slugSnap.docs[0]
    const result = { id: docSnap.id, data: docSnap.data() }
    setCacheEntry(cacheKey, result)
    return result
  }

  // Fallback: try document ID directly
  const docRef = doc(db, "products", slug)
  const docSnap = await getDoc(docRef)
  if (docSnap.exists()) {
    const result = { id: docSnap.id, data: docSnap.data() }
    setCacheEntry(cacheKey, result)
    return result
  }

  return null
}

/** Fetch featured categories config (cached) */
export async function getFeaturedConfig(): Promise<Record<string, unknown> | null> {
  const cacheKey = "featured-categories-config"
  const cached = getCacheEntry<Record<string, unknown>>(cacheKey)
  if (cached) return cached

  const snapshot = await getDoc(doc(db, "settings", "featuredCategories"))
  if (snapshot.exists()) {
    const data = snapshot.data()
    setCacheEntry(cacheKey, data)
    return data
  }
  return null
}

/** Fetch products by category ordered by salesCount (for featured sliders) */
export async function getTopProductsByCategory(category: string, maxCount = 5): Promise<CatalogProduct[]> {
  const cacheKey = `top-products-${category}-${maxCount}`
  const cached = getCacheEntry<CatalogProduct[]>(cacheKey)
  if (cached) return cached

  const q = query(
    collection(db, "products"),
    where("category", "==", category),
    orderBy("salesCount", "desc"),
    limit(maxCount)
  )
  const snapshot = await getDocs(q)
  const products: CatalogProduct[] = []
  snapshot.forEach((d) => {
    products.push({ id: d.id, ...d.data() } as CatalogProduct)
  })

  setCacheEntry(cacheKey, products)
  return products
}

/** Fetch categories settings (cached) */
export async function getCategoriesConfig(): Promise<Record<string, unknown> | null> {
  const cacheKey = "categories-config"
  const cached = getCacheEntry<Record<string, unknown>>(cacheKey)
  if (cached) return cached

  const snapshot = await getDoc(doc(db, "settings", "categories"))
  if (snapshot.exists()) {
    const data = snapshot.data()
    setCacheEntry(cacheKey, data)
    return data
  }
  return null
}
