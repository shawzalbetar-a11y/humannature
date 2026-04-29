"use client"

import { useEffect, useState, useMemo } from "react"
import { useSearchParams, useParams, notFound } from "next/navigation"
import { ProductListingPage } from "@/components/storefront/ProductListingPage"
import { getProductsByCategory, getCategoriesConfig } from "@/lib/firestore-cache"

import type { CatalogProduct, CategoryMeta } from '@/types';

import { Suspense } from "react"

function DynamicCategoryContent() {
  const params = useParams()
  const categorySlug = params.kategori as string

  const [products, setProducts] = useState<CatalogProduct[]>([])
  const [links, setLinks] = useState<{ href: string; label: string }[]>([])
  const [categoryMeta, setCategoryMeta] = useState<CategoryMeta | null>(null)
  const [loading, setLoading] = useState(true)
  const [notFoundState, setNotFoundState] = useState(false)
  const searchParams = useSearchParams()

  const activeSub = searchParams.get("sub")

  // Load category metadata + products in parallel
  useEffect(() => {
    const fetchData = async () => {
      try {
        const [catData, fetchedProducts] = await Promise.all([
          getCategoriesConfig(),
          getProductsByCategory(categorySlug)
        ])

        // Process category metadata
        if (!catData) {
          setNotFoundState(true)
          setLoading(false)
          return
        }

        const list = (catData?.list as CategoryMeta[]) ?? []
        const found = list.find((c) => c.slug === categorySlug)

        if (!found) {
          setNotFoundState(true)
          setLoading(false)
          return
        }

        setCategoryMeta(found)

        // Build subcategory links
        const basePath = `/${categorySlug}`
        const subLinks = [
          { href: basePath, label: "Tümü" },
          ...(found.subCategories ?? []).map((sub) => ({
            href: `${basePath}?sub=${sub.slug}`,
            label: sub.title,
          })),
        ]
        setLinks(subLinks)

        // Set products
        setProducts(fetchedProducts)
        setLoading(false)
      } catch (error) {
        console.error("Error fetching category data:", error)
        setNotFoundState(true)
        setLoading(false)
      }
    }

    fetchData()
  }, [categorySlug])

  // Filter by subcategory
  const filteredProducts = useMemo(() => {
    if (!activeSub) return products
    return products.filter((p) => p.subCategory === activeSub)
  }, [products, activeSub])

  const activeLink = activeSub
    ? `/${categorySlug}?sub=${activeSub}`
    : `/${categorySlug}`

  if (notFoundState) {
    notFound()
  }

  if (loading) {
    return (
      <div className="w-full min-h-screen bg-black flex items-center justify-center pt-20">
        <div className="w-10 h-10 border-2 border-white/20 border-t-white rounded-full animate-spin" />
      </div>
    )
  }

  return (
    <ProductListingPage
      title={categoryMeta?.title ?? categorySlug}
      description=""
      products={filteredProducts}
      links={links}
      activeLink={activeLink}
      emptyMessage={
        activeSub
          ? "Bu alt kategoride henüz ürün bulunmuyor."
          : "Yakında yeni ürünler eklenecektir."
      }
    />
  )
}

export default function DynamicCategoryPage() {
  return (
    <Suspense fallback={
      <div className="w-full min-h-screen bg-black flex items-center justify-center pt-20">
        <div className="w-10 h-10 border-2 border-white/20 border-t-white rounded-full animate-spin" />
      </div>
    }>
      <DynamicCategoryContent />
    </Suspense>
  )
}
