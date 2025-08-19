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
    wire [NUM_BANKS-1:0] bank_sel_onehot = (1 << bank_sel);
    
    // 预充电状态控制优化
    reg precharge_pending;
    reg [7:0] precharge_timer;
    wire precharge_condition = (|bank_active) & ~(|precharge_timer);
    wire timer_expired = |precharge_timer;
    
    // Bank激活管理优化
    always @(posedge clk) begin
        if(cmd_en) begin
            bank_active <= bank_sel_onehot;
            precharge_pending <= 1'b0;
        end else if(precharge_condition) begin
            bank_active <= {NUM_BANKS{1'b0}};
            precharge_timer <= 8'd15;
            precharge_pending <= 1'b1;
        end else if(timer_expired) begin
            precharge_timer <= precharge_timer - 1'b1;
        end
    end

endmodule