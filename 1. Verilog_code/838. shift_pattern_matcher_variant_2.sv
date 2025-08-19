//SystemVerilog
module shift_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n, data_in,
    input [WIDTH-1:0] pattern,
    output reg match_out
);
    reg [WIDTH-1:0] shift_reg;
    reg [WIDTH-1:0] next_shift_reg;
    reg next_match_out;
    
    // 使用显式多路复用器结构替换三元运算符
    always @(*) begin
        case (rst_n)
            1'b0: next_shift_reg = {WIDTH{1'b0}};
            1'b1: next_shift_reg = {shift_reg[WIDTH-2:0], data_in};
            default: next_shift_reg = {WIDTH{1'b0}}; // 处理未定义情况
        endcase
    end
    
    always @(*) begin
        case (rst_n)
            1'b0: next_match_out = 1'b0;
            1'b1: begin
                case (shift_reg == pattern)
                    1'b0: next_match_out = 1'b0;
                    1'b1: next_match_out = 1'b1;
                    default: next_match_out = 1'b0; // 处理未定义情况
                endcase
            end
            default: next_match_out = 1'b0; // 处理未定义情况
        endcase
    end
    
    // 寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= {WIDTH{1'b0}};
        end else begin
            shift_reg <= next_shift_reg;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_out <= 1'b0;
        end else begin
            match_out <= next_match_out;
        end
    end
endmodule