package ludi.mind.util;

import haxe.macro.Context;
import haxe.macro.Expr;

class LudiMindUtils {

    
    public static function getTargetTag(exprArg: Expr): String {
        #if macro
        var typedExpr = haxe.macro.Context.typeExpr(exprArg);
        var exprType = typedExpr.t;

        switch (exprType) {
            case TInst(c, params): {
                if (c.get().name == "String") {
                    return haxe.macro.ExprTools.toString(exprArg);
                } else {
                    return  haxe.macro.ExprTools.toString(exprArg);
                }
            }
            case TEnum(e, params): {
                var eiName = e.get().name;
                switch(exprArg.expr){
                    case EField(_, field, _): {
                        eiName = eiName + "." + field;
                    }
                    case EConst(CIdent(field)): {
                        eiName = eiName + "." + field;
                    }
                    default:
                }
    
                return eiName;
            }
            default:
                return haxe.macro.ExprTools.toString(exprArg);
        }
        #end
        return null;
    }
    

    public static function getComponentTag(expr: Expr): String {
        switch expr.expr {
            case EConst(CIdent(clazzName)): {
                return clazzName;
            }
            default: {
                #if macro
                Context.error("Expected a class identifier", expr.pos);
                #end
                return null;
            }
        }
    }

    #if macro
    public static function getComponentType(expr: Expr): ComplexType {

        switch expr.expr {
            case EConst(CIdent(clazzName)): {
                return haxe.macro.TypeTools.toComplexType(Context.getType(clazzName));
            }
            default:
        }

        var typedExpr = haxe.macro.Context.typeExpr(expr);
        var exprType = typedExpr.t;
        
        switch(typedExpr.t) {
            case TInst(c, params):
                var className = c.get().name;

                if (className == "String") {
                    return macro: Dynamic;
                }

                return haxe.macro.TypeTools.toComplexType(typedExpr.t);

            case TEnum(e, params):{
                if (params.length > 0) {
                    var tparam = params[0];
                    return haxe.macro.TypeTools.toComplexType(tparam);
                } else {
                    return haxe.macro.TypeTools.toComplexType(typedExpr.t);
                }
            }

            case TFun(args, retType):
                switch (retType) {
                    case TEnum(e, params):
                        if (params.length > 0) {
                            var tparam = params[0];
                            return haxe.macro.TypeTools.toComplexType(tparam);
                        } else {
                            return haxe.macro.TypeTools.toComplexType(retType);
                        }
                    default:
                        return haxe.macro.TypeTools.toComplexType(retType);
                }

            default:{
                return macro: Dynamic;
            }
                
        }
    }
    #end
}