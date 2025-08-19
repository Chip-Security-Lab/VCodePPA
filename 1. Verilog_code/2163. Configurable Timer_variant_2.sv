//SystemVerilog
module config_timer #(
    parameter DATA_WIDTH = 24,
    parameter PRESCALE_WIDTH = 8
)(
    input clk_i, rst_i, enable_i,
    input [DATA_WIDTH-1:0] period_i,
    input [PRESCALE_WIDTH-1:0] prescaler_i,
    output reg [DATA_WIDTH-1:0] value_o,
    output reg expired_o
);
    reg [PRESCALE_WIDTH-1:0] prescale_counter;
    wire prescale_tick;
    wire period_match;
    
    // 优化的比较逻辑 - 使用直接比较
    assign prescale_tick = (prescale_counter >= prescaler_i);
    assign period_match = (value_o >= period_i);
    
    // 重构的时序逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            prescale_counter <= {PRESCALE_WIDTH{1'b0}};
            value_o <= {DATA_WIDTH{1'b0}};
            expired_o <= 1'b0;
        end else if (enable_i) begin
            // 优化的分频计数器逻辑
            if (prescale_tick) begin
                prescale_counter <= {PRESCALE_WIDTH{1'b0}};
                
                // 优化的周期计数和过期判断
                if (period_match) begin
                    value_o <= {DATA_WIDTH{1'b0}};
                    expired_o <= 1'b1;
                end else begin
                    value_o <= value_o + 1'b1;
                    expired_o <= 1'b0;
                end
            end else begin
                prescale_counter <= prescale_counter + 1'b1;
                expired_o <= 1'b0;
            end
        end else begin
            expired_o <= 1'b0;
        end
    end
endmodule