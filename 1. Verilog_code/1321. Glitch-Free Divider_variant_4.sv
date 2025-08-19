//SystemVerilog
module glitch_free_divider (
    input wire clk_i, rst_i,
    output wire clk_o
);
    reg [2:0] count_r;
    reg clk_pos, clk_neg;
    
    wire [2:0] next_count;
    
    // Han-Carlson加法器实现
    wire [2:0] p, g; // 生成和传播信号
    wire [2:0] gc;   // 群组进位信号
    wire [2:0] c;    // 进位信号
    
    // 第一阶段：生成p和g信号
    assign p = count_r ^ 3'b001;
    assign g = count_r & 3'b001;
    
    // 第二阶段：前置处理
    assign gc[0] = g[0];
    assign gc[1] = g[1] | (p[1] & g[0]);
    assign gc[2] = g[2] | (p[2] & gc[1]);
    
    // 第三阶段：计算最终进位
    assign c[0] = 1'b0; // 初始进位为0
    assign c[1] = gc[0];
    assign c[2] = gc[1];
    
    // 第四阶段：计算和
    assign next_count = p ^ {c[2:0]};
    
    always @(posedge clk_i) begin
        case (rst_i)
            1'b1: begin
                count_r <= 3'd0;
                clk_pos <= 1'b0;
            end
            1'b0: begin
                case (count_r)
                    3'd3: begin
                        count_r <= 3'd0;
                        clk_pos <= ~clk_pos;
                    end
                    default: begin
                        count_r <= next_count;
                    end
                endcase
            end
        endcase
    end
    
    always @(negedge clk_i) begin
        case (rst_i)
            1'b1: begin
                clk_neg <= 1'b0;
            end
            1'b0: begin
                clk_neg <= clk_pos;
            end
        endcase
    end
    
    assign clk_o = clk_neg;
endmodule