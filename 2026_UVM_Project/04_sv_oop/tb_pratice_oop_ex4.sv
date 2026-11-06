`timescale 1ns / 1ps

package my_package;

    class bus_txn;
        typedef enum {READ,WRITE} kind_e;
        static int count = 0;
        kind_e kind;
        int id;

        function new(kind_e k, int id);
            this.kind = k;
            this.id   = id;
            count++;
        endfunction

        extern function string info();

    endclass

    function string bus_txn::info();
        return $sformatf("txn#%0d %s", id, kind.name());
    endfunction

endpackage : my_package


module tb_pratice_oop_ex4 ();

    import my_package::*;

    my_package::bus_txn t1;
    bus_txn t2;

    initial begin
        $display(" [ex4] the four places :: is used");
        t1 = new(bus_txn::READ, 1);
        t2 = new(bus_txn::WRITE, 1);

        $display(" 1) package       my_package::bus_txn");
        $display(" 2) static member bus_txn::count ", bus_txn::count);
        $display(" 3) nested type bus_txn::READ = %d, bus_txn::WRITE = %d ",
                 bus_txn::READ, bus_txn::WRITE);
        $display(" 4) outofbocy t1:info = %s, t2.info = %s", t1.info(),
                 t2.info());
        $finish;
    end


endmodule
