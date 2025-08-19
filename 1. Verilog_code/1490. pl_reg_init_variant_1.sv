//SystemVerilog
// Top-level module that instantiates the submodules
module pl_reg_init #(
    parameter W = 8,
    parameter INIT = 0
) (
    input wire clk,
    input wire init,
    input wire [W-1:0] data_in,
    output wire [W-1:0] data_out
);
    // Register data_in and init directly at the inputs
    reg [W-1:0] data_in_reg;
    reg init_reg;
    
    // Register the inputs on the clock edge
    always @(posedge clk) begin
        data_in_reg <= data_in;
        init_reg <= init;
    end
    
    // Implement the mux logic after the registers
    wire [W-1:0] mux_out;
    
    // Optimized input multiplexer - moved after register
    input_mux #(
        .W(W),
        .INIT(INIT)
    ) u_input_mux (
        .init(init_reg),
        .data_in(data_in_reg),
        .mux_out(mux_out)
    );
    
    // Output combinational assignment
    assign data_out = mux_out;
    
endmodule

// Submodule for input multiplexing logic
module input_mux #(
    parameter W = 8,
    parameter INIT = 0
) (
    input wire init,
    input wire [W-1:0] data_in,
    output wire [W-1:0] mux_out
);
    // Select between initialization value and data input
    assign mux_out = init ? INIT : data_in;
endmodule