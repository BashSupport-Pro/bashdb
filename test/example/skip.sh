#!../../bash
# Note: no CVS Id line since it would mess up regression testing.
# This code is used for various debugger testing.

fn1() {
    echo "fn1 here"
    x=5
    fn3
}    

fn2() {
    name="fn2"
    echo "$name here"
    x=6
}    

fn3() {
    name="fn3"
    x=$1
}    

x=22
x=23
for i in 1 ; do
  ((x += i))
done
x=27
echo $(fn3 30)
fn3 29
fn1;
fn3 31
case x in 
 * ) x = 33
esac
[[ -z "x" ]] && x=35
((x += 1))
source dbg-test1.sub
exit 0;
#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; End: ***
