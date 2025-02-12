package ludi.mind.util;

import haxe.macro.Context;
import haxe.macro.Expr;

#if macro
class ExprAsArg {
    public static function parse(exprArg: Expr): ParsedExprArg {
        
        var t: haxe.macro.Type;
        var name: String;

        switch(exprArg.expr){
            case EConst(CIdent(ident)): {
                t = Context.getType(ident);
                name = ident;
            }
            default: {
                var typedExpr = haxe.macro.Context.typeExpr(exprArg);
                t = typedExpr.t;
                name = haxe.macro.ExprTools.toString(exprArg);
            }
        }
        
        switch(t) {
            case TInst(c, params): {
                var className = c.get().name;

                if (className == "String") {
                    return ParsedExprArg.String(name);
                }

                return Clazz({typeName: className, pack: c.get().pack, type: t, complexType: haxe.macro.TypeTools.toComplexType(t), typeParams: [
                    for (tparam in params) TPType(haxe.macro.TypeTools.toComplexType(tparam))
                ]});
            }
            case TEnum(e, params): {
                return EnumInst({enumName: e.get().name, enumInstanceName: name, enumInstanceTypeParams: [
                    for(tparam in params) TPType(haxe.macro.TypeTools.toComplexType(tparam))
                ]});
            }
            case TType(t_, params): {
                return Type({typeName: t_.get().name, pack: t_.get().pack, type: t, complexType: haxe.macro.TypeTools.toComplexType(t), typeParams: [
                    for (tparam in params) TPType(haxe.macro.TypeTools.toComplexType(tparam))
                ]});
            }
            case TFun(args, retType): {
                switch (retType) {
                    case TEnum(e, params): {
                        return EnumInst({enumName: e.get().name, enumInstanceName: name, enumInstanceTypeParams: [
                            for(tparam in params) TPType(haxe.macro.TypeTools.toComplexType(tparam))
                        ]});
                    }
                    default:    
                }
            }
            default:
        }
        return Unimplemented(exprArg);
        
    }

    public static function getField(exprArg: Expr, fieldName: String): Expr {
        return expr(EField(exprArg, fieldName));
    }

    public static function withPrivateAccess(exprArg: Expr): Expr {
        return expr(EMeta({pos: Context.currentPos(), name: ":privateAccess"}, exprArg));
    }

    static function expr(e:ExprDef): Expr{ 
        return {pos: Context.currentPos(), expr: e};
    }

    public static function extractTypeParams(underlyingType:haxe.macro.Type):Array<TypeParam> {
        var types: Array<haxe.macro.Type> = [];
        switch underlyingType {
            case TEnum(t, params): {
                types = params;
            }
            case TInst(t, params): {
                types = params;
            }
            case TType(t, params): {
                types = params;
            }
            case TAbstract(t, params): {
                types = params;
            }
            default: return [];
        }
        return [for (eachType in types) {
            TypeParam.TPType(haxe.macro.TypeTools.toComplexType(eachType));
        }];
    }

    public static function createConstructorExpr(ct: ComplexType, tparams:Array<TypeParam>, constructorArgs:Array<Expr>): Expr {
        switch ct {
            case TPath(tPath): {
                tPath.params = tparams;
                return {
                    pos: Context.currentPos(),
                    expr: ENew(tPath, constructorArgs),
                }
            }
            default:
        }
        throw "Complex type should be in form (macro: path.to.MyType)";
    }
}

enum ParsedExprArg {
    String(str: String);
    Type(info: TypeInfo);
    Clazz(info: TypeInfo);
    EnumInst(info: EnumInstInfo);
    Unimplemented(exprArg: Expr);
}

typedef TypeInfo = {typeName: String, pack: Array<String>, type: haxe.macro.Type, complexType: ComplexType, typeParams: Array<TypeParam>};
typedef EnumInstInfo = {enumName: String, enumInstanceName: String, enumInstanceTypeParams: Array<TypeParam>};

#end