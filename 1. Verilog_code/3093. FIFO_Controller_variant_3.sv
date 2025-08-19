//SystemVerilog
module FIFO_Controller #(
    parameter DEPTH = 16,
    parameter DATA_WIDTH = 8,
    parameter AF_THRESH = 12,
    parameter AE_THRESH = 4
)(
    input clk, rst_n,
    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out,
    output full,
    output empty,
    output almost_full,
    output almost_empty
);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [4:0] wr_ptr_reg, rd_ptr_reg;
    reg [4:0] count_reg;
    reg [DATA_WIDTH-1:0] data_out_reg;
    
    wire valid_write, valid_read;
    wire [4:0] next_wr_ptr, next_rd_ptr;
    wire [4:0] next_count;
    wire [DATA_WIDTH-1:0] next_data_out;
    
    // 条件求和减法器实现
    wire [4:0] count_inc = count_reg + 1'b1;
    wire [4:0] count_dec = count_reg - 1'b1;
    wire [4:0] count_inc_dec = count_reg;
    
    assign full = (count_reg == DEPTH);
    assign empty = (count_reg == 0);
    assign almost_full = (count_reg >= AF_THRESH);
    assign almost_empty = (count_reg <= AE_THRESH);
    
    assign valid_write = wr_en && !full;
    assign valid_read = rd_en && !empty;
    
    assign next_wr_ptr = valid_write ? wr_ptr_reg + 1'b1 : wr_ptr_reg;
    assign next_rd_ptr = valid_read ? rd_ptr_reg + 1'b1 : rd_ptr_reg;
    
    // 使用条件求和实现计数器更新
    assign next_count = (valid_write && valid_read) ? count_inc_dec :
                       (valid_write) ? count_inc :
                       (valid_read) ? count_dec :
                       count_reg;
    
    assign next_data_out = valid_read ? mem[rd_ptr_reg] : data_out_reg;
    assign data_out = data_out_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_reg <= 5'b0;
            rd_ptr_reg <= 5'b0;
            count_reg <= 5'b0;
            data_out_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            wr_ptr_reg <= next_wr_ptr;
            rd_ptr_reg <= next_rd_ptr;
            count_reg <= next_count;
            data_out_reg <= next_data_out;
        end
    end
    
    always @(posedge clk) begin
        if (valid_write) begin
            mem[wr_ptr_reg] <= data_in;
        end
    end
endmodule