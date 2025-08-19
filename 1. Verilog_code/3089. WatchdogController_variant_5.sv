//SystemVerilog
module WatchdogController #(
    parameter TIMEOUT = 16'hFFFF
)(
    input clk, rst_n,
    input refresh,
    output reg system_reset
);
    reg [15:0] wdt_counter;
    reg [1:0] refresh_sync;
    
    // 2位状态编码
    localparam [1:0] 
        REFRESH = 2'b01,
        COUNTING = 2'b10,
        TIMEOUT_STATE = 2'b11;
    
    // 流水线寄存器，用于分割关键路径
    reg [1:0] wdt_state_reg;
    reg [15:0] wdt_counter_next;
    reg system_reset_next;
    
    // 定义状态逻辑 - 提取共同条件变量
    wire [1:0] wdt_state_next;
    assign wdt_state_next = refresh_sync[1] ? REFRESH :
                           (wdt_counter != 0) ? COUNTING : 
                           TIMEOUT_STATE;
    
    // 输入同步
    always @(posedge clk) begin
        refresh_sync <= {refresh_sync[0], refresh};
    end
    
    // 第一级流水线：状态计算和下一状态逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wdt_state_reg <= REFRESH;
            wdt_counter_next <= TIMEOUT;
            system_reset_next <= 0;
        end else begin
            wdt_state_reg <= wdt_state_next;
            
            // 预计算下一状态值
            case (wdt_state_next)
                REFRESH: begin
                    wdt_counter_next <= TIMEOUT;
                    system_reset_next <= 0;
                end
                
                COUNTING: begin
                    wdt_counter_next <= wdt_counter - 1;
                    system_reset_next <= 0;
                end
                
                TIMEOUT_STATE: begin
                    system_reset_next <= 1;
                end
                
                default: begin
                    wdt_counter_next <= TIMEOUT;
                    system_reset_next <= 0;
                end
            endcase
        end
    end
    
    // 第二级流水线：输出更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wdt_counter <= TIMEOUT;
            system_reset <= 0;
        end else begin
            wdt_counter <= wdt_counter_next;
            system_reset <= system_reset_next;
        end
    end
endmodule