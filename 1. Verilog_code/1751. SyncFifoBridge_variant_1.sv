//SystemVerilog
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
    reg [ADDR_W:0] wr_ptr_next, rd_ptr_next;
    
    // 补码表示的DEPTH值
    wire [ADDR_W:0] neg_depth;
    assign neg_depth = (~DEPTH) + 1'b1;
    
    // 补码表示的rd_ptr值
    wire [ADDR_W:0] neg_rd_ptr;
    assign neg_rd_ptr = (~rd_ptr) + 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {wr_ptr, rd_ptr} <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr[ADDR_W-1:0]] <= data_in;
            end
            wr_ptr <= wr_ptr_next;
            rd_ptr <= rd_ptr_next;
        end
    end

    always @(*) begin
        wr_ptr_next = wr_ptr + wr_en; // Next write pointer
        rd_ptr_next = rd_ptr + rd_en; // Next read pointer
    end

    assign data_out = mem[rd_ptr[ADDR_W-1:0]];
    
    // 使用补码加法实现减法：wr_ptr - rd_ptr = wr_ptr + (-rd_ptr)
    assign full = (wr_ptr + neg_rd_ptr) == DEPTH;
    assign empty = wr_ptr == rd_ptr;
endmodule