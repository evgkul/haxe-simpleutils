package simpleutils;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

class EnumBuilder {
	public var fields:Array<Field> = [];
    public var type:TypeDefinition;
    static var enumid = 0;
	function getName(c:Constant) {
		return switch (c) {
			case CIdent(s): s;
			case CString(s): s;
			default: throw 'Invalid enum field';
		}
	}

	public function new(exprs:Array<Expr>,src:ClassType) {
        //var fields:Array<Field> = [];
		for (expr in exprs) {
			//trace('expr', expr);
			var name:String = '';
			var ftype:FieldType = null;
			switch (expr.expr) {
				case EConst(c): {
                    name = getName(c);
                    ftype = FVar(null,null);
                }
				case ECall(e, params):
					{
                        switch(e.expr){
                            case EConst(c):{
                                name = getName(c);
                            }
                            default: throw 'Invalid enum field name';
                        }
                        var args:Array<FunctionArg> = [];
                        for(i in 0...params.length){
                            var p = params[i];
							var name = 'p'+i;
                            //trace('param',p);
							switch(p) {
								case macro @n($str) $e: {
									switch(str.expr){
										case EConst(c): name = getName(c);
										default:
									}
									p = e;
								}
								default:
							}
                            var ptype = switch(p.expr) {
                                case EConst(c): getName(c);
                                default: throw 'Invalid enum parameter';
                            }
                            args.push({
                                name: name,
                                type: Context.toComplexType(Context.getType(ptype))
                            });
                        }
                        var fdef:Function = {
                            args: args,
                            expr: null,
                            ret: null
                        }
                        ftype = FFun(fdef);
                    }
				default:
					throw 'Invalid enum field';
			}
            fields.push({
                name: name,
                doc: null,
                meta: [],
                access: [],
                kind: ftype,
                pos: expr.pos
            });
		}
        type = {
            fields: fields,
            kind: TDEnum,
            name: src.name+(enumid+=1),
            pack: [],
            pos: Context.currentPos()
        }
		
		#if simpleutils_ienum_name
		var printer = new haxe.macro.Printer();
		type.name = printer.printTypeDefinition(type,false);
		#end
		type.pack = src.pack;
	}
}
#end

/**
 * Inline enum definition
 */
#if !macro
@:genericBuild(simpleutils.IEnum.build())
#end
class IEnum<Const> {
	#if macro
	static function toField(e:Expr) {}

	public static function build() {
		var type = Context.getLocalType();
		var cl = null;
		var arg = null;
		switch (type) {
			case TInst(t, a):
				{
					cl = t.get();
					arg = a[0];
				};
			default:
				null;
		}
		/*var body = switch(arg){
			case TAnonymous(a): a.get();
			default: throw 'Invalid argument!';
		}*/
		var aexpr = switch (arg) {
			case TInst(a, b): a.get();
			default: throw('Invalid type');
		}
		var defs = switch (aexpr.kind) {
			case KExpr(expr): switch (expr.expr) {
					case EArrayDecl(vals): vals;
					default: throw('Invalid type');
				}
			default: throw('Invalid type');
		}
		var builder = new EnumBuilder(defs,cl);
        Context.defineType(builder.type);
        var ctype:ComplexType = TPath({
            pack: builder.type.pack,
            name: builder.type.name
        });
		#if simpleutils_print_code
		trace('IEnum', (new haxe.macro.Printer()).printTypeDefinition(builder.type));
		#end
		return ctype;
	}
	#end
}
