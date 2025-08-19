module dram_temp_refresh #(
    parameter BASE_CYCLES = 7800,
    parameter TEMP_COEFF = 50
)(
    input clk,
    input [7:0] temperature,
    output reg refresh_req
);
    reg [31:0] counter;
    wire [31:0] threshold = BASE_CYCLES + (temperature * TEMP_COEFF);
    
    always @(posedge clk) begin
        if(counter >= threshold) begin
            refresh_req <= 1'b1;
            counter <= 0;
        end else begin
            refresh_req <= 1'b0;
            counter <= counter + 1;
        end
    end
endmodule
