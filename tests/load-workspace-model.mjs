import { readFileSync } from "node:fs";
import vm from "node:vm";

export function loadWorkspaceModel() {
  const source = readFileSync(new URL("../WorkspaceModel.js", import.meta.url), "utf8");
  const context = {};
  vm.createContext(context);
  vm.runInContext(source, context, { filename: "WorkspaceModel.js" });
  return context;
}
