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

    // 数据通路信号定义
    reg [2:0] bank_sel_reg;
    reg bank_activation_valid_reg;
    reg precharge_condition_reg;
    reg [7:0] precharge_timer_reg;
    reg [7:0] next_timer_value_reg;
    
    // 流水线级1: 地址解码和命令验证
    always @(posedge clk) begin
        bank_sel_reg <= addr[22:20];
        bank_activation_valid_reg <= cmd_en;
    end
    
    // 流水线级2: 预充电条件计算
    always @(posedge clk) begin
        precharge_condition_reg <= (|bank_active) && (precharge_timer_reg == 0);
        next_timer_value_reg <= (precharge_timer_reg > 0) ? (precharge_timer_reg - 1) : precharge_timer_reg;
    end
    
    // 流水线级3: 定时器更新
    always @(posedge clk) begin
        if (precharge_condition_reg) begin
            precharge_timer_reg <= 15;
        end else if (precharge_timer_reg > 0) begin
            precharge_timer_reg <= next_timer_value_reg;
        end
    end
    
    // 流水线级4: Bank状态更新
    always @(posedge clk) begin
        if (bank_activation_valid_reg) begin
            bank_active <= (1 << bank_sel_reg);
        end else if (precharge_condition_reg) begin
            bank_active <= 0;
        end
    end

endmodule