//SystemVerilog
module pl_reg_parity #(parameter W=8) (
    input clk, load,
    input [W-1:0] data_in,
    output reg [W:0] data_out
);
    // Register the output with parity bit
    always @(posedge clk) begin
        if (load) begin
            // Calculate parity bit inline
            reg parity;
            parity = data_in[0];
            
            // Conditional sum algorithm for parity calculation
            for (integer i = 1; i < W; i = i + 1) begin
                parity = parity ^ data_in[i];
            end
            
            // Assign data with parity in one operation
            data_out <= {parity, data_in};
        end
    end
endmodule