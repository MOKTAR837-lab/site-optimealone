/// <reference types="astro/client" />
interface ImportMetaEnv {
  readonly SITE: string;
  readonly PUBLIC_BACKEND_URL: string;
  readonly PUBLIC_API_BASE: string;
}
interface ImportMeta { env: ImportMetaEnv }