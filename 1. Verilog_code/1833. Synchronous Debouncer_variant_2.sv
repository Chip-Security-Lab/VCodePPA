//SystemVerilog
module switch_debouncer #(parameter DEBOUNCE_COUNT = 1000) (
    input  wire clk,
    input  wire reset,
    input  wire switch_in,
    output reg  clean_out
);
    localparam CNT_WIDTH = $clog2(DEBOUNCE_COUNT);
    reg [CNT_WIDTH-1:0] counter;
    reg switch_ff1, switch_ff2;
    wire counter_reached_threshold;
    
    // 条件求和减法算法相关信号
    wire [CNT_WIDTH-1:0] target_value;
    wire [CNT_WIDTH-1:0] complement_threshold;
    wire [CNT_WIDTH:0] sum_result;  // 额外位用于进位
    
    // Double-flop synchronizer for metastability prevention
    always @(posedge clk) begin
        switch_ff1 <= switch_in;
        switch_ff2 <= switch_ff1;
    end
    
    // 使用条件求和减法算法实现计数器阈值检测
    // 通过计算 counter + ~threshold + 1 来判断是否达到阈值
    // 如果最高位为1，表示 counter >= threshold
    assign target_value = DEBOUNCE_COUNT - 1;
    assign complement_threshold = ~target_value;
    assign sum_result = {1'b0, counter} + {1'b0, complement_threshold} + 1'b1;
    assign counter_reached_threshold = sum_result[CNT_WIDTH];
    
    // Counter-based debouncer with conditional sum subtraction algorithm
    always @(posedge clk) begin
        if (reset) begin
            counter <= {CNT_WIDTH{1'b0}};
            clean_out <= 1'b0;
        end else begin
            // Input state differs from output state
            if (switch_ff2 != clean_out) begin
                if (counter_reached_threshold) begin
                    clean_out <= switch_ff2;
                    counter <= {CNT_WIDTH{1'b0}};
                end else begin
                    counter <= counter + 1'b1;
                end
            end else begin
                // Reset counter when input matches output
                counter <= {CNT_WIDTH{1'b0}};
            end
        end
    end
endmodule