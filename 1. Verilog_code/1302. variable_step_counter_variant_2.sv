//SystemVerilog
module variable_step_counter #(parameter STEP=1) (
    input  wire clk, rst,
    output reg  [7:0] ring_reg
);
    // 内部信号定义
    wire [7:0] next_ring;
    wire [7:0] shift_amt;

    // 参数转换为信号
    assign shift_amt = STEP[7:0];

    // 实现基于先行借位逻辑的移位操作
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : shift_gen
            assign next_ring[i] = ring_reg[(i + 8 - shift_amt) % 8];
        end
    endgenerate

    // 寄存器复位和更新逻辑
    always @(posedge clk) begin
        if (rst)
            ring_reg <= 8'h01;
        else
            ring_reg <= next_ring;
    end
endmodule