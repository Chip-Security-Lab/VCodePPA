//SystemVerilog
//===========================================================================
// Top-level module: param_jk_register
//===========================================================================
module param_jk_register #(
    parameter WIDTH = 4
) (
    input  wire clk,
    input  wire [WIDTH-1:0] j,
    input  wire [WIDTH-1:0] k,
    output wire [WIDTH-1:0] q
);
    // Instantiate the JK register controller
    jk_register_controller #(
        .WIDTH(WIDTH)
    ) jk_controller_inst (
        .clk(clk),
        .j(j),
        .k(k),
        .q(q)
    );
endmodule

//===========================================================================
// Sub-module: JK Register Controller
// Handles multiple JK flip-flops as a register
//===========================================================================
module jk_register_controller #(
    parameter WIDTH = 4
) (
    input  wire clk,
    input  wire [WIDTH-1:0] j,
    input  wire [WIDTH-1:0] k,
    output wire [WIDTH-1:0] q
);
    // Internal wires to connect individual flip-flops
    wire [WIDTH-1:0] q_int;
    
    // Generate block to instantiate multiple JK flip-flops
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : jk_bit_instances
            jk_flip_flop jk_bit_inst (
                .clk(clk),
                .j(j[i]),
                .k(k[i]),
                .q(q_int[i])
            );
        end
    endgenerate
    
    // Connect internal signals to output
    assign q = q_int;
endmodule

//===========================================================================
// Sub-module: JK Flip-Flop
// Implements a single JK flip-flop with set, reset, toggle functionality
//===========================================================================
module jk_flip_flop (
    input  wire clk,
    input  wire j,
    input  wire k,
    output reg  q
);
    // JK flip-flop state transition logic
    always @(posedge clk) begin
        q <= jk_state_calculator(j, k, q);
    end
    
    // Function module to calculate next state based on JK inputs
    function jk_state_calculator;
        input j_in, k_in, q_current;
        begin
            case ({j_in, k_in})
                2'b00: jk_state_calculator = q_current;  // Hold state
                2'b01: jk_state_calculator = 1'b0;       // Reset
                2'b10: jk_state_calculator = 1'b1;       // Set
                2'b11: jk_state_calculator = ~q_current; // Toggle
            endcase
        end
    endfunction
endmodule