//SystemVerilog
module data_scrambler #(parameter POLY_WIDTH = 7) (
    input  wire clk,
    input  wire reset,
    input  wire data_in,
    input  wire [POLY_WIDTH-1:0] polynomial,
    input  wire [POLY_WIDTH-1:0] initial_state,
    input  wire load_init,
    output wire data_out
);
    reg [POLY_WIDTH-1:0] lfsr_reg;
    wire feedback;
    
    // 并行前缀减法器信号
    wire [1:0] a, b;
    wire [1:0] p, g;
    wire [1:0] c;
    wire [1:0] sum;
    
    assign a = {1'b0, reset};
    assign b = {1'b0, load_init};
    
    // 生成和传播信号
    assign p = a ^ b;
    assign g = a & ~b;
    
    // 并行前缀树 (2位宽)
    assign c[0] = 1'b0;  // 无进位输入
    assign c[1] = g[0] | (p[0] & c[0]);
    
    // 计算最终结果
    assign sum = p ^ c;
    
    assign feedback = ^(lfsr_reg & polynomial);
    assign data_out = data_in ^ lfsr_reg[0];
    
    always @(posedge clk) begin
        case (sum)
            2'b10: lfsr_reg <= {POLY_WIDTH{1'b1}};
            2'b01: lfsr_reg <= initial_state;
            default: lfsr_reg <= {feedback, lfsr_reg[POLY_WIDTH-1:1]};
        endcase
    end
endmodule