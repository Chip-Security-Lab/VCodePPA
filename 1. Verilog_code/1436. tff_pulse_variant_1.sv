//SystemVerilog
module tff_pulse #(
    parameter RESET_VALUE = 1'b0  // Parameterized reset value
)(
    input  wire clk,              // Clock input
    input  wire rstn,             // Active-low reset
    input  wire t,                // Toggle control
    output wire q                 // Output state
);
    
    // Internal toggle state register
    reg q_int;
    
    // Assign output from internal register
    assign q = q_int;
    
    // Pre-compute next state logic
    wire next_q = t ? ~q_int : q_int;
    
    // Registered toggle logic with asynchronous reset
    always @(posedge clk or negedge rstn) begin
        if (!rstn) 
            q_int <= RESET_VALUE;
        else
            q_int <= next_q;
    end

endmodule