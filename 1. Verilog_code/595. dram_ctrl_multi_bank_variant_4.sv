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
    // Bank解码优化
    wire [2:0] bank_sel = addr[22:20];
    wire [NUM_BANKS-1:0] bank_mask = (1 << bank_sel);
    
    // 预充电控制优化
    reg [3:0] precharge_timer;
    wire precharge_trigger = |bank_active && (precharge_timer == 0);
    wire timer_active = precharge_timer > 0;
    
    // 时序逻辑优化
    always @(posedge clk) begin
        if (cmd_en) begin
            bank_active <= bank_mask;
        end else if (precharge_trigger) begin
            bank_active <= {NUM_BANKS{1'b0}};
            precharge_timer <= 4'd15;
        end else if (timer_active) begin
            precharge_timer <= precharge_timer - 1'b1;
        end
    end
endmodule