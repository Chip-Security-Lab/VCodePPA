//SystemVerilog
module dram_ctrl_multi_bank #(
    parameter NUM_BANKS = 8,
    parameter ADDR_WIDTH = 24
)(
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    input cmd_en,
    output reg [NUM_BANKS-1:0] bank_active
);

    // 组合逻辑部分
    wire [NUM_BANKS-1:0] bank_decode;
    wire precharge_condition;
    wire [7:0] next_precharge_timer;
    
    // 组合逻辑模块
    assign bank_decode = (cmd_en) ? (1'b1 << addr[22:20]) : {NUM_BANKS{1'b0}};
    assign precharge_condition = (|bank_active) && (precharge_timer == 0);
    assign next_precharge_timer = (precharge_condition) ? 8'd15 : 
                                (precharge_timer > 0) ? (precharge_timer - 1) : precharge_timer;

    // 时序逻辑部分
    reg [7:0] precharge_timer;
    always @(posedge clk) begin
        bank_active <= (precharge_condition) ? {NUM_BANKS{1'b0}} : bank_decode;
        precharge_timer <= next_precharge_timer;
    end

endmodule