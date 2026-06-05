import React, { useState, useEffect } from 'react';
import { motion, useScroll, useTransform, AnimatePresence } from 'framer-motion';
import { Heart, Share2, Star, ChevronLeft, Search, ShoppingBag, Check } from 'lucide-react';
import { useInfiniteQuery } from '@tanstack/react-query';

const PRODUCT = {
  name: 'Premium Classic Black Hoodie',
  brand: 'ESSENTIALS',
  rating: 4.6,
  reviewsCount: 256,
  soldCount: '15K+',
  price: 2999,
  originalPrice: 4999,
  discount: 40,
  images: [
    'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1522512115668-c09775d6f424?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?auto=format&fit=crop&q=80&w=800'
  ],
  colors: ['#000000', '#F5F5DC', '#808080'],
  sizes: ['S', 'M', 'L', 'XL', 'XXL']
};

const fetchReviews = async ({ pageParam = 1 }) => {
  return {
    data: Array.from({ length: 5 }).map((_, i) => ({
      id: pageParam * 10 + i,
      user: `User ${pageParam * 10 + i}`,
      rating: 5,
      comment: 'Absolutely love this product! The quality is amazing and it fits perfectly.',
      image: i % 2 === 0 ? 'https://images.unsplash.com/photo-1618517351616-3898bd307a52?auto=format&fit=crop&q=80&w=200' : null,
      date: '12 Oct, 2023'
    })),
    nextPage: pageParam < 5 ? pageParam + 1 : undefined,
  };
};

const fetchRecommendations = async ({ pageParam = 1 }) => {
  return {
    data: Array.from({ length: 6 }).map((_, i) => ({
      id: pageParam * 100 + i,
      name: `Related Item ${pageParam * 100 + i}`,
      price: 1999,
      image: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&q=80&w=400',
    })),
    nextPage: pageParam < 5 ? pageParam + 1 : undefined,
  };
};

export default function App() {
  const [selectedColor, setSelectedColor] = useState(PRODUCT.colors[0]);
  const [selectedSize, setSelectedSize] = useState('M');
  const [activeImageIndex, setActiveImageIndex] = useState(0);
  const [isWishlisted, setIsWishlisted] = useState(false);

  const { scrollY } = useScroll();
  const [isScrolled, setIsScrolled] = useState(false);

  useEffect(() => {
    return scrollY.onChange((latest) => {
      setIsScrolled(latest > 300);
    });
  }, [scrollY]);

  // Image Gallery Swipe Animation variants
  const slideVariants = {
    enter: (direction: number) => ({ x: direction > 0 ? 1000 : -1000, opacity: 0 }),
    center: { zIndex: 1, x: 0, opacity: 1 },
    exit: (direction: number) => ({ zIndex: 0, x: direction < 0 ? 1000 : -1000, opacity: 0 }),
  };

  const handleDragEnd = (e: any, { offset, velocity }: any) => {
    const swipe = Math.abs(offset.x) * velocity.x;
    if (swipe < -10000 && activeImageIndex < PRODUCT.images.length - 1) {
      setActiveImageIndex(activeImageIndex + 1);
    } else if (swipe > 10000 && activeImageIndex > 0) {
      setActiveImageIndex(activeImageIndex - 1);
    }
  };

  const { data: reviewsData, fetchNextPage: fetchNextReviews, hasNextPage: hasNextReviews } = useInfiniteQuery({
    queryKey: ['reviews'],
    queryFn: fetchReviews,
    getNextPageParam: (lastPage) => lastPage.nextPage,
    initialPageParam: 1
  });

  const { data: recData, fetchNextPage: fetchNextRecs, hasNextPage: hasNextRecs } = useInfiniteQuery({
    queryKey: ['recommendations'],
    queryFn: fetchRecommendations,
    getNextPageParam: (lastPage) => lastPage.nextPage,
    initialPageParam: 1
  });

  // Intersection Observers for infinite scroll
  useEffect(() => {
    const handleScroll = () => {
      if (window.innerHeight + window.scrollY >= document.body.offsetHeight - 500) {
        if (hasNextReviews) fetchNextReviews();
        if (hasNextRecs) fetchNextRecs();
      }
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, [hasNextReviews, hasNextRecs, fetchNextReviews, fetchNextRecs]);

  const headerY = useTransform(scrollY, [0, 300], [-100, 0]);
  const imageScale = useTransform(scrollY, [0, 300], [1, 1.1]);
  const imageOpacity = useTransform(scrollY, [0, 300], [1, 0.3]);

  return (
    <div className="min-h-screen bg-gray-50 pb-32 font-sans selection:bg-black selection:text-white">
      {/* Top Navbar (Absolute) */}
      <nav className="absolute top-0 left-0 right-0 z-50 p-4 flex justify-between items-center text-white bg-gradient-to-b from-black/50 to-transparent">
        <button className="p-2 bg-black/20 backdrop-blur-md rounded-full"><ChevronLeft size={24} /></button>
        <div className="flex gap-4">
          <button className="p-2 bg-black/20 backdrop-blur-md rounded-full"><Search size={24} /></button>
          <button className="p-2 bg-black/20 backdrop-blur-md rounded-full relative">
            <ShoppingBag size={24} />
            <span className="absolute top-0 right-0 w-4 h-4 bg-red-500 rounded-full text-[10px] flex items-center justify-center font-bold">2</span>
          </button>
        </div>
      </nav>

      {/* Sticky Floating Summary Bar */}
      <AnimatePresence>
        {isScrolled && (
          <motion.div
            initial={{ y: -100, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: -100, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            className="fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-xl border-b border-gray-200 shadow-sm"
          >
            <div className="max-w-4xl mx-auto px-4 py-3 flex items-center justify-between gap-4">
              <div className="flex items-center gap-3 overflow-hidden">
                <img src={PRODUCT.images[0]} alt="thumb" className="w-12 h-12 rounded-lg object-cover bg-gray-100" />
                <div className="flex flex-col">
                  <span className="text-sm font-bold truncate text-gray-900">{PRODUCT.name}</span>
                  <div className="flex items-center gap-2 text-xs text-gray-600 font-medium">
                    <span className="flex items-center text-black font-bold"><Star size={12} className="mr-0.5 fill-black" />{PRODUCT.rating}</span>
                    <span>•</span>
                    <span>{PRODUCT.reviewsCount} Rev</span>
                    <span>•</span>
                    <span className="text-gray-900">{PRODUCT.soldCount} Sold</span>
                  </div>
                </div>
              </div>
              
              <div className="flex items-center gap-4 whitespace-nowrap">
                <div className="hidden sm:flex flex-col items-end">
                  <span className="text-lg font-bold">₹{PRODUCT.price}</span>
                  <div className="flex gap-2 text-xs">
                    <span className="w-4 h-4 rounded-full border border-gray-200" style={{ backgroundColor: selectedColor }}></span>
                    <span className="font-semibold">{selectedSize}</span>
                  </div>
                </div>
                <button 
                  onClick={() => setIsWishlisted(!isWishlisted)}
                  className="p-2 rounded-full bg-gray-100 text-black hover:bg-gray-200 transition-colors hidden sm:block"
                >
                  <Heart size={20} className={isWishlisted ? "fill-black" : ""} />
                </button>
                <button className="bg-black text-white px-5 py-2.5 rounded-full font-semibold text-sm hover:bg-gray-900 active:scale-95 transition-all shadow-lg shadow-black/20">
                  Buy Now
                </button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <main className="max-w-4xl mx-auto bg-white min-h-screen shadow-2xl overflow-hidden relative">
        {/* Product Image Gallery */}
        <div className="relative h-[65vh] w-full bg-gray-100 overflow-hidden group">
          <motion.div 
            style={{ scale: imageScale, opacity: imageOpacity }}
            className="w-full h-full cursor-grab active:cursor-grabbing"
            drag="x"
            dragConstraints={{ left: 0, right: 0 }}
            dragElastic={1}
            onDragEnd={handleDragEnd}
          >
            <AnimatePresence initial={false} custom={1}>
              <motion.img
                key={activeImageIndex}
                src={PRODUCT.images[activeImageIndex]}
                custom={1}
                variants={slideVariants}
                initial="enter"
                animate="center"
                exit="exit"
                transition={{ x: { type: "spring", stiffness: 300, damping: 30 }, opacity: { duration: 0.2 } }}
                className="absolute w-full h-full object-cover"
                alt="Product Image"
              />
            </AnimatePresence>
          </motion.div>
          
          {/* Pagination Indicators */}
          <div className="absolute bottom-6 left-0 right-0 flex justify-center gap-2 z-10">
            {PRODUCT.images.map((_, idx) => (
              <div 
                key={idx} 
                className={`transition-all duration-300 rounded-full bg-white shadow-md ${idx === activeImageIndex ? 'w-6 h-1.5 opacity-100' : 'w-1.5 h-1.5 opacity-50'}`}
              />
            ))}
          </div>
        </div>

        {/* Product Information */}
        <div className="p-5 bg-white rounded-t-3xl -mt-6 relative z-20 shadow-[0_-10px_40px_rgba(0,0,0,0.05)]">
          <div className="flex justify-between items-start gap-4">
            <div>
              <p className="text-sm font-bold text-gray-500 uppercase tracking-widest mb-1">{PRODUCT.brand}</p>
              <h1 className="text-2xl font-black text-gray-900 leading-tight mb-3">{PRODUCT.name}</h1>
            </div>
            <div className="flex gap-2">
              <button className="p-3 bg-gray-50 rounded-full text-gray-900 hover:bg-gray-100 transition-colors">
                <Share2 size={22} />
              </button>
              <button 
                onClick={() => setIsWishlisted(!isWishlisted)}
                className="p-3 bg-gray-50 rounded-full text-gray-900 hover:bg-gray-100 transition-colors"
              >
                <Heart size={22} className={isWishlisted ? "fill-black text-black" : ""} />
              </button>
            </div>
          </div>

          <div className="flex items-center gap-3 mb-6 flex-wrap">
            <div className="flex items-center bg-black text-white px-2 py-1 rounded text-sm font-bold gap-1">
              {PRODUCT.rating} <Star size={14} className="fill-white" />
            </div>
            <span className="text-sm text-gray-500 font-medium">{PRODUCT.reviewsCount} Reviews</span>
            <div className="w-1 h-1 bg-gray-300 rounded-full" />
            <span className="text-sm text-gray-900 font-semibold bg-gray-100 px-2 py-1 rounded">{PRODUCT.soldCount} Sold</span>
          </div>

          <div className="flex items-end gap-3 mb-8">
            <span className="text-3xl font-black text-gray-900">₹{PRODUCT.price}</span>
            <span className="text-lg text-gray-400 line-through font-medium mb-1">₹{PRODUCT.originalPrice}</span>
            <span className="text-sm font-bold text-red-500 mb-1.5 bg-red-50 px-2 py-0.5 rounded">-{PRODUCT.discount}% OFF</span>
          </div>

          {/* Color Selection */}
          <div className="mb-8">
            <div className="flex justify-between items-center mb-3">
              <h3 className="text-base font-bold text-gray-900">Color</h3>
              <span className="text-sm text-gray-500 font-medium">Selected: {selectedColor}</span>
            </div>
            <div className="flex gap-3">
              {PRODUCT.colors.map(color => (
                <button
                  key={color}
                  onClick={() => setSelectedColor(color)}
                  className={`w-10 h-10 rounded-full flex items-center justify-center transition-transform ${selectedColor === color ? 'ring-2 ring-offset-2 ring-black scale-110' : 'ring-1 ring-gray-200'}`}
                  style={{ backgroundColor: color }}
                >
                  {selectedColor === color && <Check size={16} className={color === '#000000' || color === '#808080' ? 'text-white' : 'text-black'} />}
                </button>
              ))}
            </div>
          </div>

          {/* Size Selection */}
          <div className="mb-8">
            <div className="flex justify-between items-center mb-3">
              <h3 className="text-base font-bold text-gray-900">Size</h3>
              <button className="text-sm font-bold text-gray-500 underline underline-offset-4">Size Guide</button>
            </div>
            <div className="flex gap-3 overflow-x-auto no-scrollbar pb-2">
              {PRODUCT.sizes.map(size => (
                <button
                  key={size}
                  onClick={() => setSelectedSize(size)}
                  className={`min-w-[3.5rem] h-12 rounded-xl text-sm font-bold transition-all ${selectedSize === size ? 'bg-black text-white shadow-lg shadow-black/20 scale-105' : 'bg-gray-50 text-gray-900 hover:bg-gray-100 border border-gray-100'}`}
                >
                  {size}
                </button>
              ))}
            </div>
          </div>

          {/* Product Description */}
          <div className="mb-8">
            <h3 className="text-lg font-bold text-gray-900 mb-3">Product Description</h3>
            <p className="text-gray-600 text-sm leading-relaxed font-medium">
              Elevate your street style with our Premium Classic Black Hoodie. Crafted from heavyweight 400gsm French Terry cotton, it offers an oversized, relaxed fit that drapes perfectly. Features a double-lined hood, dropped shoulders, and minimalistic design for a sleek, modern aesthetic.
            </p>
          </div>

          {/* Features */}
          <div className="mb-10">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Features & Specifications</h3>
            <ul className="grid grid-cols-2 gap-y-3 gap-x-4 text-sm text-gray-700">
              <li className="flex items-center gap-2"><div className="w-1.5 h-1.5 bg-black rounded-full" /> 100% Premium Cotton</li>
              <li className="flex items-center gap-2"><div className="w-1.5 h-1.5 bg-black rounded-full" /> 400gsm Heavyweight</li>
              <li className="flex items-center gap-2"><div className="w-1.5 h-1.5 bg-black rounded-full" /> Oversized Fit</li>
              <li className="flex items-center gap-2"><div className="w-1.5 h-1.5 bg-black rounded-full" /> Machine Washable</li>
            </ul>
          </div>
        </div>

        {/* Reviews Section */}
        <div className="p-5 bg-gray-50 border-t border-gray-200">
          <div className="flex justify-between items-end mb-6">
            <div>
              <h2 className="text-xl font-black text-gray-900">Customer Reviews</h2>
              <p className="text-sm text-gray-500 font-medium mt-1">Based on {PRODUCT.reviewsCount} reviews</p>
            </div>
            <button className="text-sm font-bold text-black border-b border-black">View All</button>
          </div>

          <div className="space-y-4">
            {reviewsData?.pages.map((page, i) => (
              <React.Fragment key={i}>
                {page.data.map((review) => (
                  <motion.div 
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    key={review.id} 
                    className="bg-white p-4 rounded-2xl shadow-sm border border-gray-100"
                  >
                    <div className="flex justify-between items-start mb-3">
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 bg-black rounded-full flex items-center justify-center text-white font-bold text-xs">
                          {review.user.charAt(0)}
                        </div>
                        <div>
                          <p className="text-sm font-bold text-gray-900">{review.user}</p>
                          <div className="flex text-black mt-0.5">
                            {[...Array(review.rating)].map((_, i) => <Star key={i} size={10} className="fill-black" />)}
                          </div>
                        </div>
                      </div>
                      <span className="text-xs text-gray-400 font-medium">{review.date}</span>
                    </div>
                    <p className="text-sm text-gray-600 leading-relaxed font-medium">{review.comment}</p>
                    {review.image && (
                      <img src={review.image} alt="Review" className="w-20 h-20 object-cover rounded-xl mt-3 border border-gray-100" />
                    )}
                  </motion.div>
                ))}
              </React.Fragment>
            ))}
          </div>
        </div>

        {/* Recommendations Section */}
        <div className="p-5 bg-white pb-32 border-t border-gray-200">
          <h2 className="text-xl font-black text-gray-900 mb-6">You Might Also Like</h2>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
            {recData?.pages.map((page, i) => (
              <React.Fragment key={i}>
                {page.data.map((item) => (
                  <motion.div 
                    initial={{ opacity: 0, scale: 0.95 }}
                    whileInView={{ opacity: 1, scale: 1 }}
                    viewport={{ once: true }}
                    key={item.id} 
                    className="group"
                  >
                    <div className="relative aspect-[3/4] bg-gray-100 rounded-2xl overflow-hidden mb-3">
                      <img src={item.image} alt={item.name} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
                      <button className="absolute top-2 right-2 p-1.5 bg-white/80 backdrop-blur rounded-full text-gray-900">
                        <Heart size={16} />
                      </button>
                    </div>
                    <h3 className="text-sm font-bold text-gray-900 truncate">{item.name}</h3>
                    <p className="text-sm text-gray-500 font-semibold mt-1">₹{item.price}</p>
                  </motion.div>
                ))}
              </React.Fragment>
            ))}
          </div>
        </div>
      </main>

      {/* Fixed Bottom Action Bar (Mobile Only, or always for quick buy) */}
      <div className="fixed bottom-0 left-0 right-0 p-4 bg-white border-t border-gray-200 z-40 pb-safe pb-8 sm:hidden">
        <div className="flex gap-3 max-w-4xl mx-auto">
          <button className="flex-1 bg-gray-100 text-black py-3.5 rounded-2xl font-bold text-sm active:scale-95 transition-transform">
            Add to Cart
          </button>
          <button className="flex-1 bg-black text-white py-3.5 rounded-2xl font-bold text-sm active:scale-95 transition-transform shadow-xl shadow-black/20">
            Buy Now
          </button>
        </div>
      </div>
    </div>
  );
}
