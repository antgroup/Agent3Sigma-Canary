export const escape = value => String(value).replace(/[&<>"\']/g, char => ({"&":"&amp;", "<":"&lt;", ">":"&gt;", '"':"&quot;", "\'":"&#39;"}[char]));
