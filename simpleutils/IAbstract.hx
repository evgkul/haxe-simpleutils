package simpleutils;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.ExprTools;
#end

#if !macro
@:genericBuild(simpleutils.IAbstract.build())
#end
class IAbstract<T, Const> {
	#if macro
	static var abstracts = 0;

	static function extractFuncs(t:Type) {
		return switch (t) {
			case TInst(a, b): switch (a.get().kind) {
					case KExpr(e): switch (e.expr) {
							case EArrayDecl(vals): vals;
							default: throw 'False';
						}
					default: throw 'False';
				};
			default: throw 'False';
		}
	}

	static function toFunc(e:Expr) {
		return switch (e.expr) {
			case EFunction(name, f): f;
			default: throw 'Invalid input';
		}
	}

	static function rewriteStaticExpr(e:Expr,replacer:String) {
        var wrapper = function(e:Expr) return rewriteStaticExpr(e,replacer);
		switch (e) {
			case macro this:
				{
					e.expr = EConst(CIdent(replacer));
				}
			default:
				{
					ExprTools.iter(e, wrapper);
				}
		}
	}

	public static function build() {
		var data = Context.getLocalType();
		var self = null;
		var args = null;
		switch (data) {
			case TInst(s, a):
				{
					self = s.get();
					args = a;
				}
			default:
				throw 'False';
		}
		var name = self.name + '_' + (abstracts += 1);
		var res_path = {
			pack: self.pack,
			name: name
		}
		var res_ctype:ComplexType = TPath(res_path);
		var ctype = Context.toComplexType(args[0]);
		var procs = extractFuncs(args[1]);
		var fid = 0;
		var name_const = macro A;
		name_const.expr = EConst(CIdent(name));
		var fields:Array<Field> = procs.map(function(e) {
			var call = macro new $res_path($e);
			var is_static = true;
			switch (e) {
				case macro @:to
					$expr:
					{
						e = expr;
						is_static = false;
					};
				default:
					{};
			}
			if (is_static) {
				rewriteStaticExpr(e,'__iabstract_input');
			}
			return {
				access: is_static ? [AInline, AStatic] : [AInline],
				doc: null,
				meta: [{
					name: !is_static ? ':to' : ':from',
					pos: e.pos,
					params: null
				}],
				kind: FFun(toFunc(is_static ? macro function(__iabstract_input) {
					return $call;
				} : macro function() {
					return $e;
				})),
				name: 'func_' + (fid += 1),
				pos: e.pos
			};
		});
		var pos = Context.currentPos();
		fields.push({
			pos: pos,
			name: 'new',
			access: [AInline],
			kind: FFun(toFunc(macro function(e) {
				this = e;
			}))
		});
		fields.push({
			pos: pos,
			name: 'get_value',
			access: [AInline],
			kind: FFun(toFunc(macro function() return this))
		});
		fields.push({
			pos: pos,
			name: 'value',
			access: [APublic],
			kind: FProp('get', 'never', ctype),
		});

		var type:TypeDefinition = {
			pos: Context.currentPos(),
			pack: self.pack,
			name: name,
			kind: TDAbstract(ctype, [ctype], [ctype]),
			fields: fields
		};
		Context.defineType(type);
        #if simpleutils_print_code
		trace('IAbstract', (new haxe.macro.Printer()).printTypeDefinition(type));
        #end
		return res_ctype;
	}
	#end
}
