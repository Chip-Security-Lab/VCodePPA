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

    // Bank解码
    wire [2:0] bank_sel = addr[22:20];
    wire [NUM_BANKS-1:0] bank_sel_onehot;
    
    // Bank选择信号生成
    assign bank_sel_onehot = (1 << bank_sel);
    
    // 预充电计时器
    reg [7:0] precharge_timer;
    wire precharge_ready;
    wire any_bank_active;
    
    // 状态信号
    assign any_bank_active = |bank_active;
    assign precharge_ready = (any_bank_active && precharge_timer == 0);
    
    // 控制状态编码
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] ACTIVATE = 2'b01;
    localparam [1:0] PRECHARGE = 2'b10;
    
    reg [1:0] ctrl_state, next_state;
    
    // 状态转换逻辑
    always @(*) begin
        case (ctrl_state)
            IDLE: begin
                if (cmd_en)
                    next_state = ACTIVATE;
                else if (precharge_ready)
                    next_state = PRECHARGE;
                else
                    next_state = IDLE;
            end
            ACTIVATE: begin
                if (precharge_ready)
                    next_state = PRECHARGE;
                else
                    next_state = IDLE;
            end
            PRECHARGE: begin
                if (precharge_timer == 0)
                    next_state = IDLE;
                else
                    next_state = PRECHARGE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // 状态寄存器
    always @(posedge clk) begin
        ctrl_state <= next_state;
    end
    
    // Bank激活控制
    always @(posedge clk) begin
        case (ctrl_state)
            ACTIVATE: bank_active <= bank_sel_onehot;
            PRECHARGE: bank_active <= 0;
            default: bank_active <= bank_active;
        endcase
    end
    
    // 预充电计时器控制
    always @(posedge clk) begin
        case (ctrl_state)
            PRECHARGE: begin
                if (precharge_timer > 0)
                    precharge_timer <= precharge_timer - 1;
            end
            ACTIVATE: precharge_timer <= 15; // tRP=15
            default: precharge_timer <= precharge_timer;
        endcase
    end

endmodule