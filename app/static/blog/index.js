let posts;
let footer;
export function resolve(parts,config) {
  if (!parts.length) return {slug:null};
  return parts.length === 1 && config.posts.some(post => post.slug === parts[0]) ? {slug:parts[0]} : null;
}
export function title(route,{config}) { return route.slug ? config.posts.find(post => post.slug === route.slug).title : 'Blog'; }
export function render(route,context) {
  posts = context.config.posts; footer = context.footer;
  return route.slug ? article(route.slug) : blog();
}
function blog(){return `<section class="page-intro"><span class="eyebrow">NOTES FROM THE TEAM</span><h1 class="page-title">Questions worth<br><em>looking into.</em></h1><p>Perspectives on agent risk, benchmark design, and the work of turning behavior into evidence.</p></section><div class="blog-list">${posts.map(p=>`<a class="blog-row" href="/blog/${p.slug}"><time>${p.date}</time><div><h2>${p.title}</h2><p>${p.summary}</p><span class="eyebrow">${p.tag} · EDITORIAL PREVIEW</span></div><span>↗</span></a>`).join('')}</div>${footer()}`}
function article(slug){const p=posts.find(p=>p.slug===slug);if(!p)return "";return `<article class="article"><a class="text-link" href="/blog">← &nbsp; All research notes</a><span class="eyebrow">${p.tag} · EDITORIAL PREVIEW</span><h1>${p.title}</h1><p>${p.summary}</p>${p.sections.map(s=>`<h2>${s[0]}</h2><p>${s[1]}</p>`).join('')}<p class="empty-note">Illustrative editorial content for this research website preview.</p></article>${footer()}`}
