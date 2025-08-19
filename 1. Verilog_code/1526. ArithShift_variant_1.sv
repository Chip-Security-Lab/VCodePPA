//SystemVerilog
module ArithShift #(parameter N=8) (
    input clk, rstn, arith_shift, s_in,
    output reg [N-1:0] q,
    output reg carry_out
);
    // 定义操作类型
    localparam RESET = 2'b00;
    localparam ARITH_SHIFT_RIGHT = 2'b10;
    localparam LOGICAL_SHIFT_LEFT = 2'b11;
    
    // 先寄存输入信号，减少输入到第一级寄存器的延迟
    reg arith_shift_reg;
    reg s_in_reg;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            arith_shift_reg <= 1'b0;
            s_in_reg <= 1'b0;
        end else begin
            arith_shift_reg <= arith_shift;
            s_in_reg <= s_in;
        end
    end
    
    // 组合逻辑确定操作类型（现在基于寄存后的信号）
    reg [1:0] op_type;
    
    always @(*) begin
        if (!rstn)
            op_type = RESET;
        else if (arith_shift_reg)
            op_type = ARITH_SHIFT_RIGHT;
        else
            op_type = LOGICAL_SHIFT_LEFT;
    end
    
    // 位移操作逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q <= 0;
            carry_out <= 0;
        end else begin
            case (op_type)
                RESET: begin
                    q <= 0;
                    carry_out <= 0;
                end
                
                ARITH_SHIFT_RIGHT: begin
                    // Arithmetic right shift: sign-extend
                    carry_out <= q[0];
                    q <= {q[N-1], q[N-1:1]};
                end
                
                LOGICAL_SHIFT_LEFT: begin
                    // Logical left shift
                    carry_out <= q[N-1];
                    q <= {q[N-2:0], s_in_reg};
                end
                
                default: begin
                    // 默认情况（不应该发生）
                    q <= q;
                    carry_out <= carry_out;
                end
            endcase
        end
    end
endmodule