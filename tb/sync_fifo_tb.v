`timescale 1ns/1ps

module sync_fifo_tb;

    parameter DATA_WIDTH = 8;
    parameter DEPTH = 8;

    reg clk;
    reg rst;

    reg wr_en;
    reg rd_en;

    reg [DATA_WIDTH-1:0] data_in;

    wire [DATA_WIDTH-1:0] data_out;

    wire full;
    wire empty;
    sync_fifo
#(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
)
dut
(
    .clk(clk),
    .rst(rst),

    .wr_en(wr_en),
    .rd_en(rd_en),

    .data_in(data_in),

    .data_out(data_out),

    .full(full),
    .empty(empty)
);

always #5 clk = ~clk;

initial begin

    clk = 0;
    rst = 1;

    wr_en = 0;
    rd_en = 0;

    data_in = 0;

    // Release reset
#20;
rst = 0;

@(posedge clk);
wr_en = 1;
data_in = 10;
@(posedge clk);

data_in = 20;
@(posedge clk);

data_in = 30;
@(posedge clk);

wr_en = 0;
    
    @(posedge clk);
    rd_en = 1;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    
    rd_en = 0;

    #20;
    
    $finish;
end
always @(posedge clk) begin
    #1;
    $display("--------------------------------");

    $display("Time = %0t", $time);

    $display("wr_en = %0b", wr_en);
    $display("rd_en = %0b", rd_en);

    $display("data_in  = %0d", data_in);
    $display("data_out = %0d", data_out);

    $display("full = %0b", full);
    $display("empty = %0b", empty);

end

endmodule