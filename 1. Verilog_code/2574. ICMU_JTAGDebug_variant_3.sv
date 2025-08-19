//SystemVerilog
module ICMU_JTAGDebug #(
    parameter DW = 32
)(
    input tck,
    input tms,
    input tdi,
    output tdo,
    input [DW-1:0] ctx_data,
    output reg [DW-1:0] debug_out
);

    // 组合逻辑部分
    wire [DW-1:0] next_shift_reg;
    wire [2:0] next_tap_state;
    wire [DW-1:0] next_debug_out;

    // 状态寄存器
    reg [2:0] tap_state;
    reg [2:0] tap_state_buf1;
    reg [2:0] tap_state_buf2;
    
    // 移位寄存器
    reg [DW-1:0] shift_reg;
    reg [DW-1:0] shift_reg_buf1;
    reg [DW-1:0] shift_reg_buf2;

    // 组合逻辑计算
    assign next_shift_reg = (tap_state_buf2 == 3'h1) ? {tdi, shift_reg_buf2[DW-1:1]} : shift_reg_buf2;
    assign next_debug_out = (tap_state_buf2 == 3'h4) ? shift_reg_buf2 : debug_out;
    
    assign next_tap_state = 
        (tap_state == 3'h0 && !tms) ? 3'h1 :  // IDLE -> DRSHIFT
        (tap_state == 3'h1 && tms) ? 3'h4 :   // Exit
        (tap_state == 3'h4) ? 3'h0 :          // Return to IDLE
        3'h0;                                 // Default case

    // 时序逻辑部分 - 主状态寄存器
    always @(posedge tck) begin
        tap_state <= next_tap_state;
        shift_reg <= next_shift_reg;
        debug_out <= next_debug_out;
    end

    // 时序逻辑部分 - 缓冲寄存器
    always @(posedge tck) begin
        tap_state_buf1 <= tap_state;
        tap_state_buf2 <= tap_state_buf1;
        
        shift_reg_buf1 <= shift_reg;
        shift_reg_buf2 <= shift_reg_buf1;
    end

    // 输出组合逻辑
    assign tdo = shift_reg_buf2[0];

endmodule