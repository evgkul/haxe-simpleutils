import simpleutils.*;
class Test {
    public static function main(){
        iabstracttest(function(){
            trace('Hello from callback!');
        });
        trace('It works!');
    }
    static function iabstracttest(arg:IAbstract<Float->Void,[function(e) this(), @:to {callback: this}]>) {
        arg.value(0.123);
    }
    public static function testenum(arg:IEnum<[Name,Name2(@n(str) String)]>,arg2:IEnum<[Name,N2,N3,Name2(String,Int)]>){
        return arg;
    }
    public static function testenum2(arg:IEnum<[Name,N2,N3,Name2(String,Int)]>){
        trace('testenum');
    }
}