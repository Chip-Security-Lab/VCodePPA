//SystemVerilog
///////////////////////////////////////////////////////////
// Module: xor2_4_top
// Description: Top level module for 2-input XOR gate with registered output
// Design features: Parameterized bit width, clock synchronization
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module xor2_4_top #(
    parameter BIT_WIDTH = 1
)(
    input  wire                 clk,    // Clock input
    input  wire                 rst_n,  // Active low reset
    input  wire [BIT_WIDTH-1:0] A,      // Input operand A
    input  wire [BIT_WIDTH-1:0] B,      // Input operand B
    output wire [BIT_WIDTH-1:0] Y       // Registered XOR result
);
    // Internal signals
    wire [BIT_WIDTH-1:0] xor_result;
    wire [BIT_WIDTH-1:0] preprocessed_a;
    wire [BIT_WIDTH-1:0] preprocessed_b;
    
    // Instantiate input preprocessing module
    xor2_4_input_preprocess #(
        .BIT_WIDTH(BIT_WIDTH)
    ) u_input_preprocess (
        .raw_a(A),
        .raw_b(B),
        .processed_a(preprocessed_a),
        .processed_b(preprocessed_b)
    );
    
    // Instantiate computational logic module
    xor2_4_compute_unit #(
        .BIT_WIDTH(BIT_WIDTH)
    ) u_compute (
        .in_a(preprocessed_a),
        .in_b(preprocessed_b),
        .xor_out(xor_result)
    );
    
    // Instantiate output interface module
    xor2_4_output_interface #(
        .BIT_WIDTH(BIT_WIDTH)
    ) u_output_interface (
        .clk(clk),
        .rst_n(rst_n),
        .result_in(xor_result),
        .result_out(Y)
    );
endmodule

///////////////////////////////////////////////////////////
// Module: xor2_4_input_preprocess
// Description: Preprocesses input signals for optimization
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module xor2_4_input_preprocess #(
    parameter BIT_WIDTH = 1
)(
    input  wire [BIT_WIDTH-1:0] raw_a,
    input  wire [BIT_WIDTH-1:0] raw_b,
    output wire [BIT_WIDTH-1:0] processed_a,
    output wire [BIT_WIDTH-1:0] processed_b
);
    // In this simple design, preprocessing just passes through
    // But could be expanded to include input buffering, noise filtering, etc.
    assign processed_a = raw_a;
    assign processed_b = raw_b;
endmodule

///////////////////////////////////////////////////////////
// Module: xor2_4_compute_unit
// Description: Core computational logic for XOR operation
// Performance optimized for minimum propagation delay
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module xor2_4_compute_unit #(
    parameter BIT_WIDTH = 1
)(
    input  wire [BIT_WIDTH-1:0] in_a,
    input  wire [BIT_WIDTH-1:0] in_b,
    output wire [BIT_WIDTH-1:0] xor_out
);
    // Optimized XOR implementation for better PPA metrics
    genvar i;
    generate
        for (i = 0; i < BIT_WIDTH; i = i + 1) begin : xor_gen
            // Individual XOR gates for better timing
            assign xor_out[i] = in_a[i] ^ in_b[i];
        end
    endgenerate
endmodule

///////////////////////////////////////////////////////////
// Module: xor2_4_output_interface
// Description: Output interface with synchronization and reset control
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module xor2_4_output_interface #(
    parameter BIT_WIDTH = 1
)(
    input  wire                 clk,        // Clock input
    input  wire                 rst_n,      // Active low reset
    input  wire [BIT_WIDTH-1:0] result_in,  // Computation result input
    output reg  [BIT_WIDTH-1:0] result_out  // Registered output
);
    // Two-stage registered output for better timing closure
    reg [BIT_WIDTH-1:0] result_stage;
    
    // First register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage <= {BIT_WIDTH{1'b0}};
        end else begin
            result_stage <= result_in;
        end
    end
    
    // Output register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_out <= {BIT_WIDTH{1'b0}};
        end else begin
            result_out <= result_stage;
        end
    end
endmodule