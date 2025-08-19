//SystemVerilog
module BurstConvBridge #(
    parameter MAX_BURST = 16
)(
    input clk, rst_n,
    input [31:0] addr_in,
    input [7:0] burst_len,
    output reg [31:0] addr_out,
    output reg [3:0] sub_burst
);
    reg [7:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            addr_out <= 0;
            sub_burst <= 0;
        end else begin
            // Optimize comparison logic
            if (burst_len > MAX_BURST) begin
                sub_burst <= MAX_BURST;
                addr_out <= addr_in + (counter * 4);
                counter <= (counter < (burst_len >> 2)) ? counter + 1 : 0; // Use bit-shifting for division by 4
            end else begin
                sub_burst <= burst_len;
                addr_out <= addr_in;
                counter <= 0; // Reset counter when burst_len is less than or equal to MAX_BURST
            end
        end
    end
endmodule