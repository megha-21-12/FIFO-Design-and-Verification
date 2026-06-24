`timescale 1ns/1ps

interface fifo_if;

    logic clk;
    logic rst;

    logic wr_en;
    logic rd_en;

    logic [7:0] data_in;
    logic [7:0] data_out;

    logic full;
    logic empty;

endinterface

class transaction;

    rand bit wr_en;
    rand bit rd_en;

    rand bit [7:0] data_in;

    bit [7:0] data_out;
	
  	bit full;
	bit empty;
  
    constraint valid_operation {

    wr_en != rd_en;

}

    function void display(string name);

        $display("\n[%s]", name);
        $display("--------------------------");
        $display("wr_en    = %0b", wr_en);
        $display("rd_en    = %0b", rd_en);
        $display("data_in  = %0d", data_in);
        $display("data_out = %0d", data_out);
        $display("--------------------------");

    endfunction

endclass

class generator;

    transaction tr;

    mailbox mbx;

    function new(mailbox mbx);
        this.mbx = mbx;
    endfunction
task run();

    transaction tr;

    // Burst of writes
    repeat(5) begin
        tr = new();
        tr.wr_en = 1;
        tr.rd_en = 0;
        assert(tr.randomize() with { data_in inside {[0:255]}; });
        tr.display("Generator");
        mbx.put(tr);
    end

    // Burst of reads
    repeat(5) begin
        tr = new();
        tr.wr_en = 0;
        tr.rd_en = 1;
        tr.display("Generator");
        mbx.put(tr);
    end

    // Random traffic
    repeat(20) begin
        tr = new();
        assert(tr.randomize());
        tr.display("Generator");
        mbx.put(tr);
    end

endtask
 

endclass

class driver;

    transaction tr;

    mailbox mbx;

    virtual fifo_if intf;

    function new(mailbox mbx, virtual fifo_if intf);

        this.mbx  = mbx;
        this.intf = intf;

    endfunction

    task run();

      repeat(30) begin

        mbx.get(tr);
@(negedge intf.clk);

intf.wr_en   <= tr.wr_en;
intf.rd_en   <= tr.rd_en;
intf.data_in <= tr.data_in;

@(posedge intf.clk);

// allow monitor to sample

@(negedge intf.clk);

intf.wr_en <= 0;
intf.rd_en <= 0;

    end


    endtask

endclass

class monitor;

    transaction tr;

    mailbox mon_mbx;

    virtual fifo_if intf;

    function new(mailbox mon_mbx, virtual fifo_if intf);

        this.mon_mbx = mon_mbx;
        this.intf    = intf;

    endfunction

    task run();

      repeat(30) begin

            tr = new();

            @(posedge intf.clk);
			#1;
            tr.wr_en    = intf.wr_en;
            tr.rd_en    = intf.rd_en;
            tr.data_in  = intf.data_in;
            tr.data_out = intf.data_out;
			tr.full  = intf.full;
			tr.empty = intf.empty;
            tr.display("Monitor");

            mon_mbx.put(tr);

        end

    endtask

endclass

class scoreboard;

    transaction tr;

    mailbox mon_mbx;

    bit [7:0] expected_queue[$];

    function new(mailbox mon_mbx);

        this.mon_mbx = mon_mbx;

    endfunction

  task run();
    repeat(30) begin

            mon_mbx.get(tr);

            if (tr.wr_en && !tr.full) begin

                expected_queue.push_back(tr.data_in);

                $display("[Scoreboard] Stored %0d", tr.data_in);

            end

            if (tr.rd_en) begin

    if (expected_queue.size() == 0) begin

        $display("[Scoreboard] Read ignored (Queue Empty)");

    end
    else begin

        bit [7:0] expected;

        expected = expected_queue.pop_front();

        if(expected == tr.data_out)
            $display("[Scoreboard] PASS Expected=%0d Actual=%0d",
                     expected, tr.data_out);
        else
            $display("[Scoreboard] FAIL Expected=%0d Actual=%0d",
                     expected, tr.data_out);

    end

end
        end

    endtask

endclass

module testbench;

    fifo_if intf();
	
    mailbox mbx;

    generator gen;
  
  	driver drv;
  	
    mailbox mon_mbx;

  	monitor mon;
  
  	scoreboard sb;
  
    sync_fifo dut (
        .clk     (intf.clk),
        .rst     (intf.rst),

        .wr_en   (intf.wr_en),
        .rd_en   (intf.rd_en),

        .data_in (intf.data_in),
        .data_out(intf.data_out),

        .full    (intf.full),
        .empty   (intf.empty)
    );
  
  always #5 intf.clk = ~intf.clk;
  
  initial begin

     intf.clk = 0;
    intf.rst = 1;

    intf.wr_en = 0;
    intf.rd_en = 0;
    intf.data_in = 0;

    #20;
    intf.rst = 0;

    mbx = new();
    mon_mbx = new();

    gen = new(mbx);

    drv = new(mbx, intf);

    mon = new(mon_mbx, intf);

    sb = new(mon_mbx);
    
    fork
        gen.run();
        drv.run();
      	mon.run();
      	sb.run();
    join

    #20;

    $finish;

	end
  

endmodule