package ludi.mind;

import haxe.macro.Expr;

abstract class View<T> {
    public function new() {}
    public abstract function yields(comp: Component): T;
}