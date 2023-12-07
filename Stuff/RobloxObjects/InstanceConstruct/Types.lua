--// TYPES
type __instance = {
	className: string;
	id: string?;
	children: {__instance}?;
	properties: {[string]: any?}?;
}
export type instance = __instance;

type __postAppliedProperty = {
	instance: Instance;
	property: string;
	value: any;
}
export type postAppliedProperty = __postAppliedProperty

type __resultStruct = {
	instances: {[string]: __instance};
	root: {Instance};
	postAppliedProperties: {__postAppliedProperty};
}
export type resultStruct = __resultStruct

type __inputCompileVersion = 'base' | 'all_modules'
export type inputCompileVersion = __inputCompileVersion

type __inputStruct = {
	root: {__instance};
	inputCompileVersion: __inputCompileVersion?;
}
export type inputStruct = __inputStruct

return true
