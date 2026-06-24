module async_fifo(

    input wr_clk,
    input rd_clk,
    input rst,

    input wr_en,
    input rd_en,

    input [7:0] data_in,
    output reg [7:0] data_out,

    output full,
    output empty

);

parameter DEPTH = 8;
parameter ADDR_WIDTH = 3;

reg [7:0] mem [0:DEPTH-1];

reg [ADDR_WIDTH:0] wptr_bin;
reg [ADDR_WIDTH:0] rptr_bin;

reg [ADDR_WIDTH:0] wptr_gray;
reg [ADDR_WIDTH:0] rptr_gray;

reg [ADDR_WIDTH:0] wptr_gray_sync1;
reg [ADDR_WIDTH:0] wptr_gray_sync2;

reg [ADDR_WIDTH:0] rptr_gray_sync1;
reg [ADDR_WIDTH:0] rptr_gray_sync2;

wire [ADDR_WIDTH:0] wptr_bin_next;
wire [ADDR_WIDTH:0] wptr_gray_next;

wire [ADDR_WIDTH:0] rptr_bin_next;
wire [ADDR_WIDTH:0] rptr_gray_next;

assign wptr_bin_next  = wptr_bin + 1;
assign wptr_gray_next = wptr_bin_next ^ (wptr_bin_next >> 1);

assign rptr_bin_next  = rptr_bin + 1;
assign rptr_gray_next = rptr_bin_next ^ (rptr_bin_next >> 1);

always @(posedge wr_clk or posedge rst)
begin
    if (rst)
    begin
        wptr_bin  <= 0;
        wptr_gray <= 0;
    end

    else if (wr_en && !full)
    begin
        mem[wptr_bin[ADDR_WIDTH-1:0]] <= data_in;

        wptr_bin  <= wptr_bin_next;
        wptr_gray <= wptr_gray_next;
    end
end
always @(posedge rd_clk or posedge rst)
begin

    if(rst)
    begin
        rptr_bin  <= 0;
        rptr_gray <= 0;
        data_out  <= 0;
    end

    else if(rd_en && !empty)
    begin

        data_out <= mem[rptr_bin[ADDR_WIDTH-1:0]];

        rptr_bin  <= rptr_bin_next;
        rptr_gray <= rptr_gray_next;

    end

end
always @(posedge wr_clk or posedge rst)
begin

    if(rst)
    begin
        rptr_gray_sync1 <= 0;
        rptr_gray_sync2 <= 0;
    end

    else
    begin
        rptr_gray_sync1 <= rptr_gray;
        rptr_gray_sync2 <= rptr_gray_sync1;
    end

end
always @(posedge rd_clk or posedge rst)
begin
    if(rst)
    begin
        wptr_gray_sync1 <= 0;
        wptr_gray_sync2 <= 0;
    end

    else
    begin
        wptr_gray_sync1 <= wptr_gray;
        wptr_gray_sync2 <= wptr_gray_sync1;
    end
end

assign empty = (rptr_gray == wptr_gray_sync2);
assign full =
    (wptr_gray_next ==
     {~rptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
       rptr_gray_sync2[ADDR_WIDTH-2:0]});

endmodule