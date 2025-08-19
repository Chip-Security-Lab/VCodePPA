module dram_burst_length #(
    parameter MAX_BURST = 8
)(
    input clk,
    input [2:0] burst_cfg,
    output reg burst_end
);
    reg [3:0] burst_counter;
    wire [3:0] burst_max;
    
    // 使用位移替代类型转换
    assign burst_max = {1'b0, burst_cfg} << 1;  // 乘以2
    
    always @(posedge clk) begin
        if(burst_counter == burst_max) begin
            burst_end <= 1'b1;
            burst_counter <= 0;
        end else begin
            burst_end <= 1'b0;
            burst_counter <= burst_counter + 1;
        end
    end
endmodule
