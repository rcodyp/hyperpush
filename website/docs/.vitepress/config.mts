import { defineConfig } from 'vitepress'
import tailwindcss from '@tailwindcss/vite'
import path from 'node:path'
import meshGrammar from '../../../tools/editors/vscode-mesh/syntaxes/mesh.tmLanguage.json'
import meshLight from './theme/shiki/mesh-light.json'
import meshDark from './theme/shiki/mesh-dark.json'

export default defineConfig({
  title: 'Mesh',
  description: 'The Mesh Programming Language',

  // Respect system preference by default; user can override via toggle
  appearance: 'auto',

  // Enable clean URLs
  cleanUrls: true,

  // Enable git-based last-updated timestamps
  lastUpdated: true,

  // Generate sitemap
  sitemap: {
    hostname: 'https://meshlang.dev',
  },

  // Site-wide SEO defaults
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/logo-icon-black.svg', media: '(prefers-color-scheme: light)' }],
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/logo-icon-white.svg', media: '(prefers-color-scheme: dark)' }],
    ['meta', { name: 'theme-color', content: '#ffffff', media: '(prefers-color-scheme: light)' }],
    ['meta', { name: 'theme-color', content: '#0d0d0d', media: '(prefers-color-scheme: dark)' }],
    ['meta', { property: 'og:site_name', content: 'Mesh Programming Language' }],
    ['meta', { property: 'og:image', content: 'https://meshlang.dev/og-image.png' }],
    ['meta', { property: 'og:image:width', content: '1200' }],
    ['meta', { property: 'og:image:height', content: '630' }],
    ['meta', { property: 'og:image:alt', content: 'Mesh — Built for distributed systems. One annotation, native speed, auto-failover.' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:image', content: 'https://meshlang.dev/og-image.png' }],
    ['meta', { name: 'twitter:site', content: '@meshlang' }],
  ],

  // Per-page dynamic SEO meta tags
  transformPageData(pageData) {
    const canonicalUrl = `https://meshlang.dev/${pageData.relativePath}`
      .replace(/index\.md$/, '')
      .replace(/\.md$/, '.html')

    const isHome = pageData.relativePath === 'index.md'
    const title = isHome
      ? 'Mesh Programming Language'
      : (pageData.title ? `${pageData.title} | Mesh` : 'Mesh Programming Language')
    const description = pageData.description
      || (isHome
        ? 'One annotation to distribute work across a fleet. Built-in failover, load balancing, and exactly-once semantics — no orchestration layer required.'
        : 'A language built for distributed systems and servers.')

    pageData.frontmatter.head ??= []
    pageData.frontmatter.head.push(
      ['link', { rel: 'canonical', href: canonicalUrl }],
      ['meta', { name: 'description', content: description }],
      ['meta', { property: 'og:title', content: title }],
      ['meta', { property: 'og:description', content: description }],
      ['meta', { property: 'og:url', content: canonicalUrl }],
      ['meta', { property: 'og:type', content: isHome ? 'website' : 'article' }],
      ['meta', { name: 'twitter:title', content: title }],
      ['meta', { name: 'twitter:description', content: description }],
    )
  },

  markdown: {
    languages: [
      {
        ...(meshGrammar as any),
        name: 'mesh',
      },
    ],
    theme: {
      light: meshLight as any,
      dark: meshDark as any,
    },
  },

  themeConfig: {
    nav: [
      { text: 'Docs', link: '/docs/' },
      { text: 'Packages', link: '/packages/' },
    ],
    search: { provider: 'local' },
    editLink: {
      pattern: 'https://github.com/snowdamiz/mesh-lang/edit/main/website/docs/:path',
      text: 'Edit this page on GitHub',
    },
    meshVersion: '14.0',
    sidebar: {
      '/docs/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Introduction', link: '/docs/getting-started/', icon: 'BookOpen' } as any,
            { text: 'Clustered Example', link: '/docs/getting-started/clustered-example/', icon: 'Network' } as any,
          ],
        },
        {
          text: 'Language Guide',
          collapsed: false,
          items: [
            { text: 'Language Basics', link: '/docs/language-basics/', icon: 'Code2' } as any,
            { text: 'Type System', link: '/docs/type-system/', icon: 'Shapes' } as any,
            { text: 'Iterators', link: '/docs/iterators/', icon: 'Repeat' } as any,
            { text: 'Concurrency', link: '/docs/concurrency/', icon: 'Workflow' } as any,
          ],
        },
        {
          text: 'Web & Networking',
          collapsed: false,
          items: [
            { text: 'Web', link: '/docs/web/', icon: 'Globe' } as any,
          ],
        },
        {
          text: 'Data',
          collapsed: false,
          items: [
            { text: 'Databases', link: '/docs/databases/', icon: 'Database' } as any,
          ],
        },
        {
          text: 'Distribution',
          collapsed: false,
          items: [
            { text: 'Distributed Actors', link: '/docs/distributed/', icon: 'Network' } as any,
          ],
        },
        {
          text: 'Tooling',
          collapsed: false,
          items: [
            { text: 'Developer Tools', link: '/docs/tooling/', icon: 'Wrench' } as any,
          ],
        },
        {
          text: 'Standard Library',
          collapsed: false,
          items: [
            { text: 'Standard Library', link: '/docs/stdlib/', icon: 'Library' } as any,
            { text: 'Testing', link: '/docs/testing/', icon: 'FlaskConical' } as any,
          ],
        },
        {
          text: 'Reference',
          collapsed: false,
          items: [
            { text: 'Syntax Cheatsheet', link: '/docs/cheatsheet/', icon: 'ClipboardList' } as any,
          ],
        },
        {
          text: 'Proof Surfaces',
          collapsed: false,
          items: [
            {
              text: 'Distributed Proof',
              link: '/docs/distributed-proof/',
              icon: 'ShieldCheck',
              includeInFooter: false,
            } as any,
            {
              text: 'Production Backend Proof',
              link: '/docs/production-backend-proof/',
              icon: 'ShieldCheck',
              includeInFooter: false,
            } as any,
          ],
        },
      ],
    },
    outline: { level: [2, 3], label: 'On this page' },
  },

  vite: {
    plugins: [
      tailwindcss(),
    ],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './theme'),
      },
    },
  },
})
