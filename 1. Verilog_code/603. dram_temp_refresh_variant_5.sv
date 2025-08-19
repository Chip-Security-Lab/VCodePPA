//SystemVerilog
module dram_temp_refresh #(
    parameter BASE_CYCLES = 7800,
    parameter TEMP_COEFF = 50
)(
    input clk,
    input rst_n,
    input [7:0] temperature,
    output reg refresh_req
);

    // Combined pipeline stage 1: Temperature coefficient and threshold calculation
    reg [31:0] temp_coeff;
    reg [31:0] threshold;
    reg [31:0] counter;
    
    // Stage 1: Combined temperature coefficient and threshold calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            temp_coeff <= 32'd0;
            threshold <= BASE_CYCLES;
            counter <= 32'd0;
            refresh_req <= 1'b0;
        end else begin
            temp_coeff <= temperature * TEMP_COEFF;
            threshold <= BASE_CYCLES + temp_coeff;
            
            if (counter >= threshold) begin
                counter <= 32'd0;
                refresh_req <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                refresh_req <= 1'b0;
            end
        end
    end

endmodule