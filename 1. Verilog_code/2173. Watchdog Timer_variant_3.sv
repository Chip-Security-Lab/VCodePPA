//SystemVerilog
module watchdog_timer #(parameter WIDTH = 24)(
    input clk_i, rst_ni, wdt_en_i, feed_i,
    input [WIDTH-1:0] timeout_i,
    output timeout_o
);
    // 内部信号声明
    reg [WIDTH-1:0] counter_r;
    reg feed_d_r;
    reg timeout_r;
    wire feed_edge;
    wire [1:0] control_state;
    wire [WIDTH-1:0] counter_next;
    wire timeout_next;
    
    // 组合逻辑部分
    assign feed_edge = feed_i & ~feed_d_r;
    assign control_state = {rst_ni, wdt_en_i};
    
    // 组合逻辑 - 计算下一状态
    watchdog_comb_logic #(.WIDTH(WIDTH)) comb_logic_inst (
        .control_state(control_state),
        .feed_edge(feed_edge),
        .counter_r(counter_r),
        .timeout_i(timeout_i),
        .counter_next(counter_next),
        .timeout_next(timeout_next)
    );
    
    // 时序逻辑部分 - 状态更新
    always @(posedge clk_i) begin
        feed_d_r <= feed_i;
    end
    
    always @(posedge clk_i) begin
        counter_r <= counter_next;
        timeout_r <= timeout_next;
    end
    
    // 输出赋值
    assign timeout_o = timeout_r;
    
endmodule

// 组合逻辑模块
module watchdog_comb_logic #(parameter WIDTH = 24)(
    input [1:0] control_state,
    input feed_edge,
    input [WIDTH-1:0] counter_r,
    input [WIDTH-1:0] timeout_i,
    output reg [WIDTH-1:0] counter_next,
    output reg timeout_next
);
    
    always @(*) begin
        // 默认保持当前状态
        counter_next = counter_r;
        timeout_next = (counter_r >= timeout_i) ? 1'b1 : 1'b0;
        
        case (control_state)
            2'b00: begin // 复位状态
                counter_next = {WIDTH{1'b0}};
                timeout_next = 1'b0;
            end
            
            2'b01: begin // 复位状态（rst_ni=0, wdt_en_i=1）
                counter_next = {WIDTH{1'b0}};
                timeout_next = 1'b0;
            end
            
            2'b10: begin // 未启用状态（rst_ni=1, wdt_en_i=0）
                // 保持当前状态
            end
            
            2'b11: begin // 正常工作状态（rst_ni=1, wdt_en_i=1）
                if (feed_edge) begin
                    counter_next = {WIDTH{1'b0}};
                end
                else begin
                    counter_next = counter_r + 1'b1;
                end
                
                timeout_next = (counter_r >= timeout_i) ? 1'b1 : 1'b0;
            end
        endcase
    end
    
endmodule