`timescale 1ns/1ps

interface fifo_if;

    logic wr_clk;
	logic rd_clk;
  
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

    // 5 Writes
    repeat(5) begin
        tr = new();
        tr.wr_en = 1;
        tr.rd_en = 0;
        assert(tr.randomize() with {data_in inside {[1:255]};});
        tr.display("Generator");
        mbx.put(tr);
    end

    // 5 Reads
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
        assert(tr.randomize() with {data_in inside {[1:255]};});
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

        if(tr.wr_en) begin

   @(negedge intf.wr_clk);

while(intf.full)
    @(posedge intf.wr_clk);

@(negedge intf.wr_clk);

intf.wr_en   <= 1;
intf.rd_en   <= 0;
intf.data_in <= tr.data_in;

@(negedge intf.wr_clk);

intf.wr_en <= 0;

end

else begin
@(negedge intf.rd_clk);

while(intf.empty)
    @(posedge intf.rd_clk);

@(negedge intf.rd_clk);

intf.rd_en <= 1;
intf.wr_en <= 0;

@(negedge intf.rd_clk);

intf.rd_en <= 0;

end

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

    fork

        // Monitor writes
        forever begin

    @(posedge intf.wr_clk);

    if(intf.wr_en && !intf.full) begin

        tr = new();

        tr.wr_en   = 1;
        tr.rd_en   = 0;
        tr.data_in = intf.data_in;
        tr.full    = intf.full;

        mon_mbx.put(tr);

    end

end

        // Monitor reads
forever begin

    @(posedge intf.rd_clk);

    if(intf.rd_en && !intf.empty) begin

        tr = new();

        tr.wr_en    = 0;
        tr.rd_en    = 1;
      // Read expected FIFO memory location before pointer advances
       tr.data_out = testbench.dut.mem[testbench.dut.rptr_bin[2:0]];
        tr.empty    = intf.empty;

        tr.display("Monitor");

        mon_mbx.put(tr);

    end

end

    join

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

    forever begin

        mon_mbx.get(tr);

        // WRITE
        if(tr.wr_en && !tr.full) begin

            expected_queue.push_back(tr.data_in);

            $display("[Scoreboard] Stored %0d", tr.data_in);

        end

        // READ
        if(tr.rd_en) begin

            if(expected_queue.size()==0) begin

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
  
    async_fifo dut(

    .wr_clk(intf.wr_clk),
    .rd_clk(intf.rd_clk),
    .rst(intf.rst),

    .wr_en(intf.wr_en),
    .rd_en(intf.rd_en),

    .data_in(intf.data_in),
    .data_out(intf.data_out),

    .full(intf.full),
    .empty(intf.empty)

	);
  
	always #5 intf.wr_clk = ~intf.wr_clk;
	always #7 intf.rd_clk = ~intf.rd_clk;
  
  initial begin

    intf.wr_clk = 0;
	intf.rd_clk = 0;
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
    join_none

    #3000;

    $finish;

	end
  

endmodule