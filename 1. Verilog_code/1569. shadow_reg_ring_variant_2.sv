//SystemVerilog
module shadow_reg_ring #(parameter DW=8, DEPTH=4) (
    input clk, shift,
    input [DW-1:0] new_data,
    output [DW-1:0] oldest_data
);
    reg [DW-1:0] ring_reg [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr;
    reg [$clog2(DEPTH)-1:0] rd_ptr;
    
    // 使用条件反相减法器算法计算读指针
    wire subtract_enable;
    wire [$clog2(DEPTH)-1:0] rd_ptr_next;
    wire [$clog2(DEPTH)-1:0] wr_ptr_plus_one;
    wire [$clog2(DEPTH):0] subtraction_result;
    wire [$clog2(DEPTH)-1:0] wr_ptr_minus_one;
    
    // 确定是否需要反相减法
    assign subtract_enable = (wr_ptr == 0);
    
    // 计算wr_ptr+1用于索引
    assign wr_ptr_plus_one = (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
    
    // 条件反相减法器实现
    assign wr_ptr_minus_one = subtract_enable ? (DEPTH-1) : (wr_ptr - 1);
    assign rd_ptr_next = wr_ptr_minus_one;
    
    initial begin
        wr_ptr = 0;
        rd_ptr = DEPTH-1;
    end
    
    always @(posedge clk) begin
        if(shift) begin
            ring_reg[wr_ptr] <= new_data;
            wr_ptr <= wr_ptr_plus_one;
            rd_ptr <= rd_ptr_next;
        end
    end
    
    assign oldest_data = ring_reg[rd_ptr];
endmodule