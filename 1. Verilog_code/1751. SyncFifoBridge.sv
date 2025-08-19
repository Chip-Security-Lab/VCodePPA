module SyncFifoBridge #(
    parameter DATA_W = 32,
    parameter ADDR_W = 8,
    parameter DEPTH = 16
)(
    input clk, rst_n,
    input [DATA_W-1:0] data_in,
    input wr_en, rd_en,
    output [DATA_W-1:0] data_out,
    output full, empty
);
    reg [DATA_W-1:0] mem [0:DEPTH-1];
    reg [ADDR_W:0] wr_ptr = 0, rd_ptr = 0;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) {wr_ptr, rd_ptr} <= 0;
        else begin
            if (wr_en && !full) mem[wr_ptr[ADDR_W-1:0]] <= data_in;
            wr_ptr <= wr_ptr + wr_en;
            rd_ptr <= rd_ptr + rd_en;
        end
    end
    assign data_out = mem[rd_ptr[ADDR_W-1:0]];
    assign full = (wr_ptr - rd_ptr) == DEPTH;
    assign empty = wr_ptr == rd_ptr;
endmodule