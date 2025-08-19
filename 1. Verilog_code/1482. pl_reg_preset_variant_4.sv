//SystemVerilog
// Top-level module
module pl_reg_preset #(
    parameter W = 8,
    parameter PRESET = 8'hFF
)(
    input  wire clk,
    input  wire load,
    input  wire shift_in,
    output wire [W-1:0] q
);
    // Internal registered signals
    reg [W-1:0] reg_q;
    reg load_r;
    reg shift_in_r;
    
    // Register the inputs for timing improvement
    always @(posedge clk) begin
        load_r <= load;
        shift_in_r <= shift_in;
    end
    
    // Pre-registered output assignment
    assign q = reg_q;
    
    // Combined shift and selection logic with retimed register
    always @(posedge clk) begin
        if (load_r)
            reg_q <= PRESET;
        else
            reg_q <= {reg_q[W-2:0], shift_in_r};
    end
    
endmodule