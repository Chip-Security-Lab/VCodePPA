//SystemVerilog
module cascaded_reset_dist(
    input wire clk,
    input wire rst_in,
    output wire [3:0] rst_cascade
);
    // Use a single register array for the entire reset cascade
    reg [3:0] rst_cascade_reg;
    
    // Single always block for better synthesis
    always @(posedge clk) begin
        // First stage directly captures the input reset
        rst_cascade_reg[0] <= rst_in;
        
        // Remaining stages are cascaded with optimized reset logic
        if (rst_cascade_reg[0])
            rst_cascade_reg[3:1] <= 3'b111;
        else
            rst_cascade_reg[3:1] <= {1'b0, rst_cascade_reg[3:2]};
    end
    
    // Direct assignment without combinational logic
    assign rst_cascade = rst_cascade_reg;
endmodule