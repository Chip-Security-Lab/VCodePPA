//SystemVerilog
module clk_gate_shift_en #(
    parameter DEPTH = 3
) (
    input  wire            clk,
    input  wire            en,
    input  wire            in,
    output wire [DEPTH-1:0] out
);

    wire [DEPTH-1:0] shift_data;
    
    // 实例化时钟门控模块
    clock_gating_control u_clock_gating (
        .clk        (clk),
        .enable     (en),
        .gated_clk  (gated_clk)
    );
    
    // 实例化移位寄存器模块
    shift_register #(
        .WIDTH      (DEPTH)
    ) u_shift_register (
        .clk        (gated_clk),
        .data_in    (in),
        .data_out   (shift_data)
    );
    
    // 输出赋值
    assign out = shift_data;

endmodule

module clock_gating_control (
    input  wire clk,
    input  wire enable,
    output wire gated_clk
);
    
    reg latch_en;
    
    // 改进的时钟门控实现，使用锁存器避免毛刺
    always @(*) begin
        if (!clk)
            latch_en = enable;
    end
    
    // 门控时钟输出
    assign gated_clk = clk & latch_en;
    
endmodule

module shift_register #(
    parameter WIDTH = 3
) (
    input  wire             clk,
    input  wire             data_in,
    output reg  [WIDTH-1:0] data_out
);
    
    // 8位借位减法器实现
    wire [7:0] operand_a;
    wire [7:0] operand_b;
    wire [7:0] result;
    wire [8:0] borrow;
    
    // 生成8位操作数（用于演示）
    assign operand_a = {5'b0, data_out[WIDTH-1:WIDTH-3]};
    assign operand_b = {5'b0, data_in, data_out[1:0]};
    
    // 借位减法器实现
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: borrow_subtractor
            assign result[i] = operand_a[i] ^ operand_b[i] ^ borrow[i];
            assign borrow[i+1] = (~operand_a[i] & operand_b[i]) | 
                                (~operand_a[i] & borrow[i]) | 
                                (operand_b[i] & borrow[i]);
        end
    endgenerate
    
    // 移位寄存器实现
    always @(posedge clk) begin
        data_out <= {data_out[WIDTH-2:0], result[0]};
    end
    
endmodule