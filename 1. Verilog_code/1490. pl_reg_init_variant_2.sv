//SystemVerilog
//=====================================================================
// Top-level module: pl_reg_init
// Description: Parameterized register with initialization capability
//=====================================================================
module pl_reg_init #(parameter W=8, INIT=0) (
    input clk, init,
    input [W-1:0] data_in,
    output [W-1:0] data_out
);

    // Internal connections
    wire [W-1:0] mux_out;

    // Instantiate control logic module
    control_logic #(
        .W(W),
        .INIT(INIT)
    ) ctrl_inst (
        .init(init),
        .data_in(data_in),
        .mux_out(mux_out)
    );

    // Instantiate register module
    register_stage #(
        .W(W)
    ) reg_inst (
        .clk(clk),
        .data_in(mux_out),
        .data_out(data_out)
    );

endmodule

//=====================================================================
// Control Logic Module
// Description: Handles initialization logic and input selection
//=====================================================================
module control_logic #(parameter W=8, INIT=0) (
    input init,
    input [W-1:0] data_in,
    output [W-1:0] mux_out
);
    // Constant for subtraction
    localparam [W-1:0] SUBTRACT_VALUE = 8'd5;
    
    // Internal signals for borrow-based subtraction
    wire [W:0] borrow;
    wire [W-1:0] subtraction_result;
    
    // Implement borrow-based subtraction algorithm
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : borrow_subtractor
            assign subtraction_result[i] = data_in[i] ^ SUBTRACT_VALUE[i] ^ borrow[i];
            assign borrow[i+1] = (~data_in[i] & SUBTRACT_VALUE[i]) | 
                                (borrow[i] & (~(data_in[i] ^ SUBTRACT_VALUE[i])));
        end
    endgenerate
    
    // Select between initialization value and subtraction result
    assign mux_out = init ? INIT : subtraction_result;

endmodule

//=====================================================================
// Register Stage Module
// Description: Handles clock-synchronized data capture
//=====================================================================
module register_stage #(parameter W=8) (
    input clk,
    input [W-1:0] data_in,
    output reg [W-1:0] data_out
);

    // Clock synchronized register
    always @(posedge clk) begin
        data_out <= data_in;
    end

endmodule