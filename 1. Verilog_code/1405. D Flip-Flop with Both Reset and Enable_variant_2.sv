//SystemVerilog
module d_ff_reset_enable (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire d,
    output reg q
);
    // Combinational logic for control signals
    wire [1:0] ctrl;
    
    // Use assign statement for combinational logic instead of always block
    assign ctrl = {rst_n, en};
    
    // Next state combinational logic
    wire q_next;
    
    // Determine next state based on control signals
    assign q_next = (ctrl == 2'b11) ? d : q;
    
    // Sequential logic in a separate always block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic
            q <= 1'b0;
        end else if (en) begin
            // Enable logic
            q <= q_next;
        end
    end
endmodule