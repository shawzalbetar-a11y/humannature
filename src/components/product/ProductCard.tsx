"use client";

import Image from "next/image";
import Link from "next/link";
import { Heart, ShoppingBag } from "lucide-react";
import { memo, useState } from "react"; // eslint-disable-line @typescript-eslint/no-unused-vars
import { useCartStore } from "@/store/cartStore";
import { useFavoritesStore } from "@/store/favoritesStore";
import { storeConfig } from "@/lib/storeConfig";
import { routes } from "@/lib/routes";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";

/* ───────────────────────── Types ───────────────────────── */

interface ProductCardProps {
  /** Unique product identifier */
  id: string;
  /** Primary product image URL */
  imageUrl: string;
  /** Product title (clamped to 2 lines) */
  title: string;
  /** Number of available colors (shows color badge when > 0) */
  colorCount?: number;
  /** Number of items remaining in stock */
  stockCount?: number;
  /** Original price before discount (shown with line-through) */
  originalPrice: number;
  /** Discounted selling price */
  discountPrice: number;
  /** Special price when added to cart (shows red banner) */
  cartPrice?: number;
  /** Whether the product is favorited */
  isFavorite?: boolean;
  /**
   * Custom text for the dark banner.
   * - If provided → overrides the global default
   * - If `null` → explicitly hides the banner
   * - If `undefined` → falls back to `storeConfig.defaultBannerText`
   */
  customBannerText?: string | null;
  /** Custom href for the product detail page. Defaults to routes.product(id) */
  productHref?: string;
  /** Callback when favorite icon is toggled */
  onFavoriteToggle?: (id: string) => void;
  /** Callback when cart icon is clicked */
  onAddToCart?: (id: string) => void;
  /** Trendyol URL */
  trendyolUrl?: string;
  /** Shopier URL */
  shopierUrl?: string;
  /** Product Code */
  productCode?: string;
}

/* ───────────────────────── Helpers ───────────────────────── */

function formatPrice(price: number): string {
  return price.toLocaleString(storeConfig.currency.locale, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

/* ───────────────────────── Component ───────────────────────── */

export const ProductCard = memo(function ProductCard({
  id,
  imageUrl,
  title,
  colorCount,
  stockCount,
  originalPrice,
  discountPrice,
  cartPrice,
  isFavorite: isFavoriteProp = false,
  customBannerText,
  productHref,
  onFavoriteToggle,
  onAddToCart,
  trendyolUrl,
  shopierUrl,
  productCode,
}: ProductCardProps) {
  const toggleFavorite = useFavoritesStore((state) => state.toggleFavorite);
  const isFavoriteStore = useFavoritesStore((state) => state.isFavorite(id));
  
  // Prop override vs store state
  const favorite = isFavoriteProp || isFavoriteStore;

  const addItem = useCartStore((state) => state.addItem);

  const [externalModalOpen, setExternalModalOpen] = useState(false);
  const [activeExternalPlatform, setActiveExternalPlatform] = useState<"trendyol" | "shopier" | null>(null);

  /* ── Banner text logic ── */
  const resolveBannerText = (): string | null => {
    // Show 'Low Stock' warning if stock is between 1 and 5
    if (stockCount !== undefined && stockCount > 0 && stockCount <= 5) {
      return "TÜKENMEK ÜZERE";
    }
    // Prop explicitly provided (including null to hide)
    if (customBannerText !== undefined) return customBannerText;
    // Don't show SADECE ONLINE anymore.
    return null;
  };
  const bannerText = resolveBannerText();

  /* ── Handlers ── */
  const handleFavoriteClick = async (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    await toggleFavorite(id);
    onFavoriteToggle?.(id);
  };

  const handleCartClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    addItem({
      id,
      cartItemId: `${id}-Standart-Standart`,
      name: title,
      price: cartPrice && cartPrice > 0 ? cartPrice : discountPrice,
      quantity: 1,
      size: "Standart",
      color: "Standart",
      image: imageUrl,
    });
    onAddToCart?.(id);
  };

  /* ── Discount percentage ── */
  const discountPercent =
    originalPrice > discountPrice
      ? Math.round(((originalPrice - discountPrice) / originalPrice) * 100)
      : 0;

  return (
    <div className="group relative flex flex-col bg-white overflow-hidden transition-shadow duration-300 hover:shadow-xl rounded-sm">
      {/* ═══════════ IMAGE WRAPPER ═══════════ */}
      <div className="block relative w-full aspect-[3/4] overflow-hidden bg-neutral-100">
        {/* Product image link */}
        <Link href={productHref || routes.product(id)} className="absolute inset-0 z-0 block">
          <Image
            src={imageUrl}
            alt={title}
            fill
            quality={75}
            className="object-cover transition-transform duration-700 group-hover:scale-105"
            sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
          />
        </Link>

        {/* ── Favorite icon (top-right) ── */}
        <button
          onClick={handleFavoriteClick}
          aria-label={favorite ? "Favorilerden çıkar" : "Favorilere ekle"}
          className="absolute top-3 right-3 z-20 w-9 h-9 flex items-center justify-center rounded-full bg-white/90 backdrop-blur-sm shadow-md hover:bg-white transition-colors duration-200 touch-manipulation"
        >
          <Heart
            className={`w-[18px] h-[18px] transition-colors duration-200 ${
              favorite
                ? "fill-red-500 text-red-500"
                : "fill-none text-neutral-500 hover:text-red-400"
            }`}
          />
        </button>

        {/* ── Discount badge (top-left) ── */}
        {discountPercent > 0 && (
          <span className="absolute top-3 left-3 z-20 bg-red-600 text-white text-[10px] font-bold px-2 py-1 rounded-sm tracking-wide pointer-events-none">
            %{discountPercent}
          </span>
        )}

        {/* ── Bottom overlay area (color badge + cart icon + external platforms) ── */}
        <div 
          className="absolute inset-x-0 bottom-0 z-10 flex items-center justify-between px-2 pointer-events-none" 
          style={{ paddingBottom: bannerText ? "40px" : "8px" }}
        >
          {/* Left side: External Platforms + Colors inside a pill */}
          <div className="flex items-center gap-1.5 bg-white/95 backdrop-blur-sm rounded-full p-1 shadow-md pointer-events-auto">
            {trendyolUrl && (
              <button
                onClick={(e) => {
                  e.preventDefault();
                  e.stopPropagation();
                  setActiveExternalPlatform("trendyol");
                  setExternalModalOpen(true);
                }}
                className="w-7 h-7 flex items-center justify-center rounded-full bg-[#F27A1A] hover:bg-[#d66a15] transition-colors"
                title="Trendyol'da Gör"
              >
                <span className="text-[10px] font-bold text-white tracking-tighter">TY</span>
              </button>
            )}
            
            {shopierUrl && (
              <button
                onClick={(e) => {
                  e.preventDefault();
                  e.stopPropagation();
                  setActiveExternalPlatform("shopier");
                  setExternalModalOpen(true);
                }}
                className="w-7 h-7 flex items-center justify-center rounded-full bg-[#1A8B9D] hover:bg-[#146c7a] transition-colors"
                title="Shopier'de Gör"
              >
                <span className="text-[10px] font-bold text-white tracking-tighter">SH</span>
              </button>
            )}

            {colorCount && colorCount > 0 && (
              <div className="flex items-center gap-1.5 px-2">
                <span
                  className="w-3.5 h-3.5 rounded-full shrink-0"
                  style={{
                    background:
                      "conic-gradient(#e74c3c, #f39c12, #2ecc71, #3498db, #9b59b6, #e74c3c)",
                  }}
                />
                <span className="text-[10px] font-medium text-neutral-700 whitespace-nowrap">
                  {colorCount} Renk
                </span>
              </div>
            )}
            {/* If no items to show, provide some width to maintain the pill shape slightly, or don't render it. */}
            {!trendyolUrl && !shopierUrl && (!colorCount || colorCount === 0) && (
              <div className="hidden" />
            )}
          </div>

          {/* Right side: Cart icon */}
          <button
            onClick={handleCartClick}
            aria-label="Sepete ekle"
            className="w-9 h-9 flex shrink-0 items-center justify-center rounded-full bg-white/95 backdrop-blur-sm shadow-md hover:bg-white transition-colors duration-200 pointer-events-auto touch-manipulation"
          >
            <ShoppingBag className="w-[18px] h-[18px] text-neutral-700" />
          </button>
        </div>

        {/* ── Banner (bottom edge of image) ── */}
        {bannerText && (
          <div 
            className={`absolute inset-x-0 bottom-0 z-10 py-2 pointer-events-none ${
              bannerText === "TÜKENMEK ÜZERE" 
                ? "bg-gradient-to-r from-neutral-300 via-neutral-100 to-neutral-300 shadow-[0_-2px_10px_rgba(0,0,0,0.1)]" 
                : "bg-[#1a1a2e]"
            }`}
          >
            <p className={`text-center text-[11px] font-bold tracking-[0.15em] uppercase ${
              bannerText === "TÜKENMEK ÜZERE" ? "text-neutral-900" : "text-white"
            }`}>
              {bannerText}
            </p>
          </div>
        )}
      </div>

      {/* ═══════════ PRODUCT DETAILS ═══════════ */}
      <div className="flex flex-col items-center px-3 pt-3 pb-2 space-y-1.5">
        {/* Title */}
        <Link
          href={productHref || routes.product(id)}
          className="text-sm font-bold text-neutral-800 text-center leading-tight line-clamp-2 hover:text-neutral-600 transition-colors"
        >
          {title}
        </Link>

        {/* Pricing row */}
        <div className="flex items-center justify-center gap-2.5">
          {originalPrice > discountPrice && (
            <span className="text-sm text-neutral-400 line-through">
              {formatPrice(originalPrice)} {storeConfig.currency.symbol}
            </span>
          )}
          <span className="text-base font-bold text-[#8b1a1a]">
            {formatPrice(discountPrice)} {storeConfig.currency.symbol}
          </span>
        </div>
      </div>

      {/* ── Cart price banner (red) ── */}
      <div className="w-full bg-[#8b0000] py-2 mt-auto">
        <p className="text-center text-[11px] font-semibold text-white tracking-wide">
          Sepetteki Fiyatı{" "}
          <span className="font-bold text-xs">
            {formatPrice(cartPrice && cartPrice > 0 ? cartPrice : discountPrice)} {storeConfig.currency.symbol}
          </span>
        </p>
      </div>

      {/* ── External Platform Modal ── */}
      <Dialog open={externalModalOpen} onOpenChange={setExternalModalOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Ürünü Platformda Görüntüle</DialogTitle>
            <DialogDescription>
              Bu ürünü seçtiğiniz platform üzerinden detaylı inceleyebilir ve satın alabilirsiniz.
            </DialogDescription>
          </DialogHeader>
          <div className="flex flex-col gap-4 py-4">
            <div className="bg-neutral-50 p-4 rounded-lg flex flex-col gap-1 border border-neutral-100">
              <p className="text-sm text-neutral-500 font-medium">Ürün Kodu</p>
              <p className="font-bold text-neutral-900 font-mono tracking-wide">
                {productCode || "HN-XXXX"}
              </p>
            </div>
            <div className="bg-neutral-50 p-4 rounded-lg flex flex-col gap-1 border border-neutral-100">
              <p className="text-sm text-neutral-500 font-medium">Ürün Adı</p>
              <p className="font-bold text-neutral-900 line-clamp-2">
                {title}
              </p>
            </div>
          </div>
          <div className="flex flex-col sm:flex-row gap-2 w-full mt-2">
            <Button
              variant="outline"
              className="flex-1"
              onClick={() => setExternalModalOpen(false)}
            >
              İptal
            </Button>
            <Button
              className={`flex-1 text-white ${
                activeExternalPlatform === "trendyol" 
                  ? "bg-[#F27A1A] hover:bg-[#d66a15]" 
                  : "bg-[#1A8B9D] hover:bg-[#146c7a]"
              }`}
              onClick={() => {
                const url = activeExternalPlatform === "trendyol" ? trendyolUrl : shopierUrl;
                if (url) {
                  window.open(url, "_blank", "noopener,noreferrer");
                  setExternalModalOpen(false);
                }
              }}
            >
              {activeExternalPlatform === "trendyol" ? "Trendyol'a Git" : "Shopier'e Git"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
});
