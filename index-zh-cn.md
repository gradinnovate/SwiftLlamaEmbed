---
layout: modular
title: CodeFolio Demo
lang: zh-CN

# 模块配置 - 简体中文版本
modules:
  # Hero 模块
  hero:
    enabled: true
    title: "CodeFlow Pro"
    subtitle: "艺术家 • 设计师 • 思想家"
    description: "使用 AI 生成的内容做展示"
    cta_text: "开始使用"
    cta_link: "#project"
    hero_image: "/assets/images/hero-avatar.jpg"

  # Project 模块
  project:
    enabled: true
    title: "项目概览"
    subtitle: "为解决现实问题而设计的综合解决方案"
    description: "这个软件项目代表了数月的精心规划、开发和测试。采用现代技术和以用户为中心的设计原则构建，提供卓越的性能和用户体验。"
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
      - title: "仪表板概览"
        image: "/assets/images/screenshots/dashboard.jpg"
      - title: "代码编辑器"
        image: "/assets/images/screenshots/code-editor.jpg"
      - title: "数据分析"
        image: "/assets/images/screenshots/analytics.jpg"

  # About 模块
  about:
    enabled: true
    title: "关于我"
    description: "我是一名充满热情的开发者，致力于创建创新的软件解决方案，帮助企业成长和成功。凭借多年现代网页技术经验，我专注于构建解决现实问题的用户友好应用程序。"
    about_image: "/assets/images/about-image.jpg"
    stats:
      projects: "50+"
      clients: "30+"
      experience: "5+"
    skills:
      - name: "前端开发"
        icon: "fas fa-code"
        description: "创建响应式和交互式用户界面"
      - name: "后端开发"
        icon: "fas fa-server"
        description: "构建强大且可扩展的服务器端应用程序"
      - name: "数据库设计"
        icon: "fas fa-database"
        description: "设计高效且优化的数据库结构"

  # Features 模块
  features:
    enabled: true
    title: "为什么选择我们的解决方案"
    subtitle: "我们通过尖端技术提供卓越成果"
    features_list:
      - title: "现代技术"
        icon: "fas fa-rocket"
        description: "采用最新框架和最佳实践构建"
      - title: "可扩展架构"
        icon: "fas fa-expand-arrows-alt"
        description: "设计为随着业务需求增长"
      - title: "用户友好设计"
        icon: "fas fa-users"
        description: "用户喜爱交互的直观界面"

  # Video Demo 模块
  video_demo:
    enabled: true
    title: "实际操作演示"
    description: "观看我们软件主要功能和能力的全面演练。了解它如何转换您的工作流程并提升生产力。"
    demo_video: "/assets/videos/codeflow-demo.mp4"
    demo_url: "https://example.com/demo"

  # Testimonials 模块
  testimonials:
    enabled: true
    title: "客户评价"
    testimonials_list:
      - content: "这个软件完全改变了我们的开发流程。团队提供了我们真正需要的东西。"
        author: "Sarah Johnson"
        position: "技术总监"
        company: "创新科技有限公司"
        avatar: "/assets/images/testimonials/sarah.jpg"
      - content: "出色的工作！对细节的关注和用户体验都非常出色。"
        author: "Jane Chen"
        position: "产品经理"
        company: "数字解决方案有限公司"
        avatar: "/assets/images/testimonials/jane.jpg"

  # Contact 模块
  contact:
    enabled: true
    title: "联系我们"
    subtitle: "准备开始您的项目？让我们讨论如何帮助您实现目标。"
    contact_form_enabled: true
    # contact_email: 將自動使用 _config.yml 中的 email 設定
    show_social: true

# SEO 设置
description: "CodeFlow Pro - 强大的代码协作平台，优化开发工作流程"
keywords: "软件开发, 协作, 生产力, 网页开发"
---

<!-- 所有内容都由模块根据上面的设置动态生成 -->
