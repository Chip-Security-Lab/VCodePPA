//SystemVerilog
module switch_debouncer #(parameter DEBOUNCE_COUNT = 1000) (
    input  wire clk,
    input  wire reset,
    input  wire switch_in,
    output reg  clean_out
);
    localparam CNT_WIDTH = $clog2(DEBOUNCE_COUNT);
    
    // 使用更少位宽的计数器 - 只需要足够计到DEBOUNCE_COUNT
    reg [CNT_WIDTH-1:0] counter;
    reg switch_ff1, switch_ff2;
    wire count_max = (counter == DEBOUNCE_COUNT-1);
    wire input_diff = (switch_ff2 != clean_out);
    
    // Double-flop synchronizer - 保持原样以确保消除亚稳态
    always @(posedge clk) begin
        switch_ff1 <= switch_in;
        switch_ff2 <= switch_ff1;
    end
    
    // 优化后的去抖逻辑 - 分离控制和数据路径
    always @(posedge clk) begin
        if (reset) begin
            counter <= {CNT_WIDTH{1'b0}};
        end else if (input_diff) begin
            counter <= count_max ? {CNT_WIDTH{1'b0}} : counter + 1'b1;
        end else begin
            counter <= {CNT_WIDTH{1'b0}};
        end
    end
    
    // 独立的输出逻辑 - 提高可综合性
    always @(posedge clk) begin
        if (reset) begin
            clean_out <= 1'b0;
        end else if (input_diff && count_max) begin
            clean_out <= switch_ff2;
        end
    end
endmodule