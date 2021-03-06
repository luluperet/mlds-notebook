#
# By asdasd
#
import sys
import re
import _thread
try:
    import thread
except ImportError:
    import _thread
from functools import partial
try:
    from StringIO import StringIO
except ImportError:
    from io import StringIO

#
# From: http://code.activestate.com/recipes/384122-infix-operators/
#
class Infix:
    def __init__(self, function):
        self.function = function
    def __ror__(self, other):
        return Infix(lambda x, self=self, other=other: self.function(other, x))
    def __or__(self, other):
        return self.function(other)
    #def __rlshift__(self, other):
    #    return Infix(lambda x, self=self, other=other: self.function(other, x))
    #def __rshift__(self, other):
    #    return self.function(other)
    def __call__(self, value1, value2):
        print('v1',  value1)
        print('v2',  value2)
        return self.function(value1, value2)



class ReOperator(Infix):

    data = {}

    match_type = type(re.match("asd",  "asd"))

    def __init__(self, opname):
        self.opname = opname
        op = self.build_re_op(opname)
        Infix.__init__(self, op)

    def __call__(self, *args,  **kw):
        store = self.get_store()
        store["args"] = args
        store["kw"] = kw
        return self

    def get_identifier(self):
        return (self.opname,  thread.get_ident())

    def get_store(self):
        id = self.get_identifier()
        default = {"args":[],  "kw":{}}
        store = self.data.setdefault(id, default)
        return store

    def build_re_op(self, methodname):
        def op(subject, prog):
            if type(prog) is str:
                prog = re.compile(prog)
            self.re_func = getattr(prog, methodname)

            store = self.get_store()
            args = store["args"]
            kw = store["kw"]

            #@localize('self', 'subject',  ...)
            if type(subject) is file or isinstance(subject, StringIO):
                def itr(self=self, subject=subject, prog=prog, args=args, kw=kw):
                    for line in subject:
                        yield self.re_func(line, *args, **kw)
                return itr()

            self.result = self.re_func(subject, *args,  **kw)
            return self.result
        return op

    def __getitem__(self, id):
        "Handles regexp match objects and indexable results"
        if type(self.result) is self.match_type:
            return self.result.group(id)
        return self.result[id]

    def __iter__(self):
        return self.result

    def __len__(self):
        return len(self.result)


match    = ReOperator("match")
search   = ReOperator("search")
split    = ReOperator("split")
findall  = ReOperator("findall")
finditer = ReOperator("finditer")

__all__ = [
    "match", 
    "search", 
    "split",
    "findall", 
    "finditer", 
]

