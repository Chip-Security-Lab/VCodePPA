//SystemVerilog
module shadow_reg_sync #(parameter WIDTH=8) (
    input clk, 
    input rst_n, 
    input en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

    // Intermediate register to hold shadow data
    reg [WIDTH-1:0] shadow_reg;

    // Sequential logic for shadow register and output data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
            shadow_reg <= 0;
        end else if (en) begin
            shadow_reg <= data_in; // Capture input data when enabled
        end
        // Output the shadow register value
        data_out <= shadow_reg; 
    end
endmodule