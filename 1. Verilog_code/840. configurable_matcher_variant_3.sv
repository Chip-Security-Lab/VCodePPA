//SystemVerilog
module configurable_matcher #(parameter DW = 8) (
    input clk, rst_n,
    input [DW-1:0] data, pattern,
    input [1:0] mode,
    output reg result
);
    // 中间比较结果信号
    wire [DW-1:0] diff;
    wire [DW:0] borrow;
    wire is_equal, is_greater, is_less;
    reg [1:0] mode_reg;
    
    // 模式寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mode_reg <= 2'b0;
        else
            mode_reg <= mode;
    end
    
    // 减法器实现
    assign borrow[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < DW; i = i + 1) begin: borrow_subtractor
            assign diff[i] = data[i] ^ pattern[i] ^ borrow[i];
            assign borrow[i+1] = (~data[i] & pattern[i]) | (~data[i] & borrow[i]) | (pattern[i] & borrow[i]);
        end
    endgenerate
    
    // 比较逻辑
    assign is_equal = (diff == {DW{1'b0}});
    assign is_greater = ~is_equal & ~borrow[DW];
    assign is_less = borrow[DW];
    
    // 结果选择逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 1'b0;
        end else begin
            case (mode_reg)
                2'b00: result <= is_equal;
                2'b01: result <= is_greater;
                2'b10: result <= is_less;
                2'b11: result <= ~is_equal;
                default: result <= 1'b0;
            endcase
        end
    end
endmodule