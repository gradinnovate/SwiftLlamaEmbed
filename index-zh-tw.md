---
layout: modular
title: CodeFolio Demo
lang: zh-TW

# 模組配置 - 繁體中文版本
modules:
  # Hero 模組
  hero:
    enabled: true
    title: "CodeFlow Pro"
    subtitle: "藝術家 • 設計師 • 思想家"
    description: "使用 AI 產生的內容做展示"
    cta_text: "開始使用"
    cta_link: "#project"
    hero_image: "/assets/images/hero-avatar.jpg"

  # Project 模組
  project:
    enabled: true
    title: "專案概覽"
    subtitle: "為解決現實問題而設計的綜合解決方案"
    description: "這個軟體專案代表了數月的精心規劃、開發和測試。採用現代技術和以用戶為中心的設計原則構建，提供卓越的性能和用戶體驗。"
    promo_video: "/assets/videos/codeflow-promo.mp4"
    main_image: "/assets/images/project/main-preview.jpg"
    demo_url: "https://gradinnovate.github.io/CodeFolio"
    github_url: "https://github.com/gradinnovate/CodeFolio"
    download_url: "https://github.com/gradinnovate/CodeFolio"
    technologies:
      - "React"
      - "Node.js"
      - "TypeScript"
      - "PostgreSQL"
      - "Docker"
      - "AWS"
    screenshots:
      - title: "儀表板概覽"
        image: "/assets/images/screenshots/dashboard.jpg"
      - title: "程式碼編輯器"
        image: "/assets/images/screenshots/code-editor.jpg"
      - title: "數據分析"
        image: "/assets/images/screenshots/analytics.jpg"

  # About 模組
  about:
    enabled: true
    title: "關於我"
    description: "我是一名充滿熱情的開發者，致力於創建創新的軟體解決方案，幫助企業成長和成功。憑藉多年現代網頁技術經驗，我專注於構建解決現實問題的用戶友好應用程式。"
    about_image: "/assets/images/about-image.jpg"
    stats:
      projects: "50+"
      clients: "30+"
      experience: "5+"
    skills:
      - name: "前端開發"
        icon: "fas fa-code"
        description: "創建響應式和互動式用戶界面"
      - name: "後端開發"
        icon: "fas fa-server"
        description: "構建強大且可擴展的伺服器端應用程式"
      - name: "資料庫設計"
        icon: "fas fa-database"
        description: "設計高效且優化的資料庫結構"

  # Features 模組
  features:
    enabled: true
    title: "為什麼選擇我們的解決方案"
    subtitle: "我們透過尖端技術提供卓越成果"
    features_list:
      - title: "現代技術"
        icon: "fas fa-rocket"
        description: "採用最新框架和最佳實踐構建"
      - title: "可擴展架構"
        icon: "fas fa-expand-arrows-alt"
        description: "設計為隨著業務需求成長"
      - title: "用戶友好設計"
        icon: "fas fa-users"
        description: "用戶喜愛互動的直觀界面"

  # Video Demo 模組
  video_demo:
    enabled: true
    title: "實際操作演示"
    description: "觀看我們軟體主要功能和能力的全面演練。了解它如何轉換您的工作流程並提升生產力。"
    demo_video: "/assets/videos/codeflow-demo.mp4"
    demo_url: "https://example.com/demo"

  # Testimonials 模組
  testimonials:
    enabled: true
    title: "客戶評價"
    testimonials_list:
      - content: "這個軟體完全改變了我們的開發流程。團隊提供了我們真正需要的東西。"
        author: "Sarah Johnson"
        position: "技術總監"
        company: "創新科技有限公司"
        avatar: "/assets/images/testimonials/sarah.jpg"
      - content: "出色的工作！對細節的關注和用戶體驗都非常出色。"
        author: "Jane Chen"
        position: "產品經理"
        company: "數位解決方案有限公司"
        avatar: "/assets/images/testimonials/jane.jpg"

  # Contact 模組
  contact:
    enabled: true
    title: "聯絡我們"
    subtitle: "準備開始您的專案？讓我們討論如何幫助您實現目標。"
    contact_form_enabled: true
    # contact_email: 將自動使用 _config.yml 中的 email 設定
    show_social: true

# SEO 設定
description: "CodeFlow Pro - 強大的程式碼協作平台，優化開發工作流程"
keywords: "軟體開發, 協作, 生產力, 網頁開發"
---

<!-- 所有內容都由模組根據上面的設定動態生成 -->
