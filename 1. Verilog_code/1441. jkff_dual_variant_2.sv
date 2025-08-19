//SystemVerilog
module jkff_dual (
    input clk, rstn,
    input j, k,
    output reg q
);
    reg q_pos, q_neg;
    reg j_reg, k_reg;
    wire [1:0] jk_bus;
    
    // Register inputs to reduce input-to-register delay
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            j_reg <= 0;
            k_reg <= 0;
        end else begin
            j_reg <= j;
            k_reg <= k;
        end
    end
    
    assign jk_bus = {j_reg, k_reg};
    
    // Positive edge FF with registered inputs
    always @(posedge clk or negedge rstn) begin
        if (!rstn) 
            q_pos <= 0;
        else if (jk_bus == 2'b00)
            q_pos <= q_pos;  // No change
        else if (jk_bus == 2'b10)
            q_pos <= 1;      // Set
        else if (jk_bus == 2'b01)
            q_pos <= 0;      // Reset
        else if (jk_bus == 2'b11)
            q_pos <= ~q_pos; // Toggle
        else
            q_pos <= q_pos;  // Default case
    end
    
    // Negative edge FF with registered inputs
    always @(negedge clk or negedge rstn) begin
        if (!rstn) 
            q_neg <= 0;
        else if (jk_bus == 2'b00)
            q_neg <= q_neg;  // No change
        else if (jk_bus == 2'b10)
            q_neg <= 1;      // Set
        else if (jk_bus == 2'b01)
            q_neg <= 0;      // Reset
        else if (jk_bus == 2'b11)
            q_neg <= ~q_neg; // Toggle
        else
            q_neg <= q_neg;  // Default case
    end
    
    // Register output selection
    always @(posedge clk or negedge rstn) begin
        if (!rstn) 
            q <= 0;
        else 
            q <= clk ? q_pos : q_neg;
    end
endmodule