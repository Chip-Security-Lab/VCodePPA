//SystemVerilog
module pulse_swallow_div (
    input clk_in, reset, swallow_en,
    input [3:0] swallow_val,
    output reg clk_out
);
    reg [3:0] counter;
    reg swallow;
    
    // 预计算下一个状态，减少关键路径深度
    wire counter_at_max = (counter == 4'd7);
    wire counter_at_swallow = (counter == swallow_val);
    wire will_swallow = swallow_en && counter_at_swallow && !swallow;
    wire will_reset_counter = counter_at_max || will_swallow;
    wire will_increment = !swallow && !will_reset_counter;
    
    always @(posedge clk_in) begin
        if (reset) begin
            counter <= 4'd0;
            clk_out <= 1'b0;
            swallow <= 1'b0;
        end else begin
            // 并行处理计数器、时钟输出和吞噬标志，减少逻辑链
            if (will_reset_counter)
                counter <= 4'd0;
            else if (will_increment)
                counter <= counter + 1'b1;
                
            if (counter_at_max)
                clk_out <= ~clk_out;
                
            if (will_swallow)
                swallow <= 1'b1;
            else if (counter_at_max)
                swallow <= 1'b0;
        end
    end
endmodule