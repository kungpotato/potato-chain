/// <reference types="vite/client" />
interface ImportMetaEnv {
  readonly VITE_RPC_URL?: string;
  readonly VITE_INDEXER_URL?: string;
  readonly VITE_DEV_BURNER?: string;
  readonly VITE_COMET_RPC_URL?: string;
  readonly VITE_REST_URL?: string;
}
