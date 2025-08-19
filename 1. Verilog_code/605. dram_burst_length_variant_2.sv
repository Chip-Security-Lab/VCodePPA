//SystemVerilog
module dram_burst_length #(
    parameter MAX_BURST = 8
)(
    input clk,
    input [2:0] burst_cfg,
    output reg burst_end
);
    reg [3:0] burst_counter;
    reg [3:0] burst_max_reg;
    wire [3:0] burst_max;
    wire counter_match;
    
    assign burst_max = {1'b0, burst_cfg} << 1;
    assign counter_match = (burst_counter == burst_max_reg);
    
    always @(posedge clk) begin
        burst_max_reg <= burst_max;
        burst_counter <= counter_match ? 4'd0 : burst_counter + 1'b1;
        burst_end <= counter_match;
    end
endmodule