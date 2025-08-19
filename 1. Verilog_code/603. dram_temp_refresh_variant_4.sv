//SystemVerilog
module dram_temp_refresh #(
    parameter BASE_CYCLES = 7800,
    parameter TEMP_COEFF = 50
)(
    input clk,
    input [7:0] temperature,
    output reg refresh_req
);

    // Internal signals
    reg [31:0] counter;
    reg [31:0] threshold_reg;
    wire [31:0] threshold;
    
    // Calculate refresh threshold based on temperature
    assign threshold = BASE_CYCLES + (temperature * TEMP_COEFF);
    
    // Register threshold calculation
    always @(posedge clk) begin
        threshold_reg <= threshold;
    end
    
    // Counter logic with registered comparison
    always @(posedge clk) begin
        if (counter >= threshold_reg) begin
            counter <= 0;
            refresh_req <= 1'b1;
        end else begin
            counter <= counter + 1;
            refresh_req <= 1'b0;
        end
    end

endmodule