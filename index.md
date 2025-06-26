---
layout: modular
title: CodeFolio Demo
lang: en

# 模組配置 - 所有設定都在 Markdown 中定義
modules:
  # Hero 模組 - 必需模組
  hero:
    enabled: true
    title: "CodeFlow Pro"
    subtitle: "Artist • Designer • Thinker"
    description: "This demo page uses AI-generated contents."
    cta_text: "Get Started"
    cta_link: "#project"
    hero_image: "/assets/images/hero-avatar.jpg"

  # Project 模組
  project:
    enabled: true
    title: "Project Overview"
    subtitle: "A comprehensive solution designed to solve real-world problems"
    description: "This software project represents months of careful planning, development, and testing. Built with modern technologies and user-centered design principles, it delivers exceptional performance and user experience."
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
      - title: "Dashboard Overview"
        image: "/assets/images/screenshots/dashboard.jpg"
      - title: "Code Editor"
        image: "/assets/images/screenshots/code-editor.jpg"
      - title: "Analytics"
        image: "/assets/images/screenshots/analytics.jpg"

  # About 模組
  about:
    enabled: true
    title: "About Me"
    description: "I'm a passionate developer who creates innovative software solutions that help businesses grow and succeed. With years of experience in modern web technologies, I focus on building user-friendly applications that solve real-world problems."
    about_image: "/assets/images/about-image.jpg"
    stats:
      projects: "50+"
      clients: "30+"
      experience: "5+"
    skills:
      - name: "Frontend Development"
        icon: "fas fa-code"
        description: "Creating responsive and interactive user interfaces"
      - name: "Backend Development"
        icon: "fas fa-server"
        description: "Building robust and scalable server-side applications"
      - name: "Database Design"
        icon: "fas fa-database"
        description: "Designing efficient and optimized database structures"

  # Features 模組
  features:
    enabled: true
    title: "Why Choose Our Solutions"
    subtitle: "We deliver exceptional results through cutting-edge technology"
    features_list:
      - title: "Modern Technology"
        icon: "fas fa-rocket"
        description: "Built with the latest frameworks and best practices"
      - title: "Scalable Architecture"
        icon: "fas fa-expand-arrows-alt"
        description: "Designed to grow with your business needs"
      - title: "User-Friendly Design"
        icon: "fas fa-users"
        description: "Intuitive interfaces that users love to interact with"

  # Video Demo 模組
  video_demo:
    enabled: true
    title: "See It In Action"
    description: "Watch a comprehensive walkthrough of our software's key features and capabilities. See how it can transform your workflow and boost productivity."
    demo_video: "/assets/videos/codeflow-demo.mp4"
    demo_url: "https://example.com/demo"

  # Testimonials 模組
  testimonials:
    enabled: true
    title: "What Clients Say"
    testimonials_list:
      - content: "This software has completely transformed our development process. The team delivered exactly what we needed."
        author: "Sarah Johnson"
        position: "CTO"
        company: "Tech Innovations Inc."
        avatar: "/assets/images/testimonials/sarah.jpg"
      - content: "Outstanding work! The attention to detail and user experience is exceptional."
        author: "Jane Chen"
        position: "Product Manager"
        company: "Digital Solutions Ltd."
        avatar: "/assets/images/testimonials/jane.jpeg"

  # Contact 模組
  contact:
    enabled: true
    title: "Get In Touch"
    subtitle: "Ready to start your project? Let's discuss how we can help you achieve your goals."
    contact_form_enabled: true
    # contact_email: 將自動使用 _config.yml 中的 email 設定
    show_social: true

# SEO 設定
description: "CodeFlow Pro - A powerful code collaboration platform that streamlines development workflows"
keywords: "software development, collaboration, productivity, web development"
---

<!-- 所有內容都由模組根據上面的設定動態生成 -->
