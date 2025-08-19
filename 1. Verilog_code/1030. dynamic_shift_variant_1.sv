//SystemVerilog
module dynamic_shift #(parameter W=8) (
    input wire clk,
    input wire [3:0] ctrl, // [1:0]: direction, [3:2]: type
    input wire [W-1:0] din,
    output reg [W-1:0] dout
);

    wire [W-1:0] shift_comb_result;
    reg  [W-1:0] shift_reg_stage1;
    reg  [W-1:0] shift_reg_stage2;

    // 组合逻辑：移位运算
    shift_logic #(.W(W)) u_shift_logic (
        .ctrl(ctrl),
        .din(din),
        .shift_out(shift_comb_result)
    );

    // 时序逻辑：流水线寄存器
    always @(posedge clk) begin
        shift_reg_stage1 <= shift_comb_result;
        shift_reg_stage2 <= shift_reg_stage1;
    end

    // 时序逻辑：输出寄存器
    always @(posedge clk) begin
        dout <= shift_reg_stage2;
    end

endmodule

// 组合逻辑模块
module shift_logic #(parameter W=8) (
    input  wire [3:0] ctrl,
    input  wire [W-1:0] din,
    output reg  [W-1:0] shift_out
);
    always @(*) begin
        case ({ctrl[3:2], ctrl[1:0]})
            4'b0000: shift_out = din << 1;                         // 逻辑左移
            4'b0001: shift_out = din >> 1;                         // 逻辑右移
            4'b0010: shift_out = {din[W-2:0], din[W-1]};           // 循环左移
            4'b0011: shift_out = {din[0], din[W-1:1]};             // 循环右移
            default: shift_out = {W{1'b0}};
        endcase
    end
endmodule