//SystemVerilog
module d_flip_flop (
    input wire clk,
    input wire d,
    output wire q
);
    // Direct connection from input to output register
    // This eliminates the intermediate register and potential
    // combinational logic delay between registers
    reg q_out;
    
    always @(posedge clk) begin
        q_out <= d;
    end
    
    // Direct output assignment
    assign q = q_out;
    
endmodule