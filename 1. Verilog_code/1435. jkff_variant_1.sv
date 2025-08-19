//SystemVerilog
module jkff #(parameter W=1) (
    input clk, rstn,
    input [W-1:0] j, k,
    output reg [W-1:0] q
);
    // Registered input signals to reduce input-to-register delay
    reg [W-1:0] j_reg, k_reg;
    
    // Register the inputs first
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            j_reg <= {W{1'b0}};
            k_reg <= {W{1'b0}};
        end
        else begin
            j_reg <= j;
            k_reg <= k;
        end
    end
    
    // Logic using registered inputs
    always @(posedge clk or negedge rstn) begin
        if (!rstn) 
            q <= {W{1'b0}}; // Parameter-aware reset
        else 
            case ({j_reg, k_reg})
                {1'b0, 1'b0}: q <= q;       // No change
                {1'b0, 1'b1}: q <= {W{1'b0}}; // Reset
                {1'b1, 1'b0}: q <= {W{1'b1}}; // Set
                {1'b1, 1'b1}: q <= ~q;      // Toggle
                default:      q <= q;       // Handle undefined inputs
            endcase
    end
endmodule