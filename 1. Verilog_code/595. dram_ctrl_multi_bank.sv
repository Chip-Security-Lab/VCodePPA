module dram_ctrl_multi_bank #(
    parameter NUM_BANKS = 8,
    parameter ADDR_WIDTH = 24
)(
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    input cmd_en,
    output reg [NUM_BANKS-1:0] bank_active
);
    // Bank解码
    wire [2:0] bank_sel = addr[22:20];
    
    // Bank激活管理
    always @(posedge clk) begin
        if(cmd_en) begin
            bank_active <= (1 << bank_sel);
        end
    end
    
    // 预充电控制
    reg [7:0] precharge_timer;
    always @(posedge clk) begin
        if(|bank_active && precharge_timer == 0) begin
            bank_active <= 0;
            precharge_timer <= 15; // tRP=15
        end else if(precharge_timer > 0) begin
            precharge_timer <= precharge_timer - 1;
        end
    end
endmodule
