module sync_fifo
#(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 8
)
(
    input clk,
    input rst,

    input wr_en,
    input rd_en,

    input  [DATA_WIDTH-1:0] data_in,

    output reg [DATA_WIDTH-1:0] data_out,

    output full,
    output empty
);
// -------------------------------------------------
// Internal Memory
// -------------------------------------------------
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

// -------------------------------------------------
// Pointer width
// -------------------------------------------------
localparam PTR_WIDTH = $clog2(DEPTH);

// -------------------------------------------------
// Read and Write Pointers
// Extra bit used for wrap-around detection
// -------------------------------------------------
reg [PTR_WIDTH:0] wr_ptr;
reg [PTR_WIDTH:0] rd_ptr;

always @(posedge clk) begin

    if (rst) begin

        wr_ptr   <= 0;
        rd_ptr   <= 0;
        data_out <= 0;

    end

    else begin

        if (wr_en && !full) begin

            mem[wr_ptr[PTR_WIDTH-1:0]] <= data_in;

            wr_ptr <= wr_ptr + 1;

        end
        
        if (rd_en && !empty) begin

             data_out <= mem[rd_ptr[PTR_WIDTH-1:0]];

             rd_ptr <= rd_ptr + 1;

        end

    end

end

assign empty = (wr_ptr == rd_ptr);
assign full =
    (wr_ptr[PTR_WIDTH] != rd_ptr[PTR_WIDTH]) &&
    (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]);
endmodule
