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
            counter <= 8'b0;
            addr_out <= 32'b0;
            sub_burst <= 4'b0;
        end else begin
            if (burst_len > MAX_BURST) begin
                sub_burst <= MAX_BURST;
                addr_out <= addr_in + (counter * 4);
                
                if (counter < (burst_len/MAX_BURST)) begin
                    counter <= counter + 1;
                end else begin
                    counter <= 0;
                end
            end else begin
                sub_burst <= burst_len;
                addr_out <= addr_in;
            end
        end
    end
endmodule