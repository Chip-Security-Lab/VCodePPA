//SystemVerilog
/////////////////////////////////////////////////////////////////////
// Crossbar Asynchronous Top Module with Hierarchical Architecture
/////////////////////////////////////////////////////////////////////
module crossbar_async #(
    parameter WIDTH = 16,
    parameter INPUTS = 3,
    parameter OUTPUTS = 3
) (
    input  [(WIDTH*INPUTS)-1:0]  in_data,
    input  [(OUTPUTS*INPUTS)-1:0] req,
    output [(WIDTH*OUTPUTS)-1:0] out_data
);

    // Internal signals for connections between modules
    wire [INPUTS-1:0] req_vec [0:OUTPUTS-1];
    wire [OUTPUTS-1:0] any_req;
    wire [WIDTH-1:0] out_temp [0:OUTPUTS-1];
    
    // Subtractor signals (8-bit operations)
    wire [7:0] subtract_result;
    wire [7:0] operand_a, operand_b;
    
    // Extract 8-bit operands from first input port (for demonstration)
    assign operand_a = in_data[7:0];
    assign operand_b = in_data[15:8];

    // Instantiate the lookahead borrow subtractor
    lookahead_borrow_subtractor #(
        .WIDTH(8)
    ) lbsub_inst (
        .a(operand_a),
        .b(operand_b),
        .diff(subtract_result)
    );

    // Instantiate request extractor modules for each output
    genvar o, i;
    generate
        for (o = 0; o < OUTPUTS; o = o + 1) begin : gen_request_extractors
            request_extractor #(
                .INPUTS(INPUTS)
            ) req_extract_inst (
                .req_full(req),
                .output_index(o),
                .req_vec(req_vec[o]),
                .any_req(any_req[o])
            );
        end
    endgenerate

    // Instantiate priority encoders for each output
    generate
        for (o = 0; o < OUTPUTS; o = o + 1) begin : gen_priority_encoders
            // Use subtraction result in the first output's lowest 8 bits (for demonstration)
            if (o == 0) begin
                priority_encoder_with_sub #(
                    .WIDTH(WIDTH),
                    .INPUTS(INPUTS)
                ) pri_encode_inst (
                    .in_data(in_data),
                    .req_vec(req_vec[o]),
                    .sub_result(subtract_result),
                    .out_temp(out_temp[o])
                );
            end else begin
                priority_encoder #(
                    .WIDTH(WIDTH),
                    .INPUTS(INPUTS)
                ) pri_encode_inst (
                    .in_data(in_data),
                    .req_vec(req_vec[o]),
                    .out_temp(out_temp[o])
                );
            end
        end
    endgenerate

    // Instantiate output multiplexers for each output
    generate
        for (o = 0; o < OUTPUTS; o = o + 1) begin : gen_output_muxes
            output_mux #(
                .WIDTH(WIDTH)
            ) out_mux_inst (
                .out_temp(out_temp[o]),
                .any_req(any_req[o]),
                .out_data(out_data[(o+1)*WIDTH-1:o*WIDTH])
            );
        end
    endgenerate

endmodule

///////////////////////////////////////////////////////////////////////////
// Lookahead Borrow Subtractor Module - Implementing lookahead borrow algorithm
///////////////////////////////////////////////////////////////////////////
module lookahead_borrow_subtractor #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);
    // Generate (G) signals indicate if a bit position generates a borrow
    wire [WIDTH-1:0] gen_borrow;
    // Propagate (P) signals indicate if a bit position propagates a borrow
    wire [WIDTH-1:0] prop_borrow;
    // Borrow signals for each bit position
    wire [WIDTH:0] borrow;
    
    // Initial borrow is 0
    assign borrow[0] = 1'b0;
    
    // Generate generate and propagate signals
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_prop_signals
            // Generate borrow when a[i] < b[i]
            assign gen_borrow[i] = ~a[i] & b[i];
            // Propagate borrow when a[i] = b[i]
            assign prop_borrow[i] = ~(a[i] ^ b[i]);
        end
    endgenerate
    
    // Calculate lookahead borrows
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_lookahead
            assign borrow[i+1] = gen_borrow[i] | (prop_borrow[i] & borrow[i]);
        end
    endgenerate
    
    // Calculate difference bits
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_diff
            assign diff[i] = a[i] ^ b[i] ^ borrow[i];
        end
    endgenerate
    
endmodule

///////////////////////////////////////////////////////////////////////////
// Request Extractor Module
// Extracts request signals for a specific output from the full request matrix
///////////////////////////////////////////////////////////////////////////
module request_extractor #(
    parameter INPUTS = 3
) (
    input [(INPUTS*OUTPUTS)-1:0] req_full,
    input [$clog2(OUTPUTS)-1:0] output_index,
    output [INPUTS-1:0] req_vec,
    output any_req
);
    parameter OUTPUTS = 3; // Match with top module

    genvar i;
    generate
        for (i = 0; i < INPUTS; i = i + 1) begin : gen_req
            assign req_vec[i] = req_full[i*OUTPUTS + output_index];
        end
    endgenerate

    // OR reduction to determine if any request is active
    assign any_req = |req_vec;

endmodule

///////////////////////////////////////////////////////////////////////////
// Priority Encoder Module
// Implements priority encoding logic to select input based on request vector
///////////////////////////////////////////////////////////////////////////
module priority_encoder #(
    parameter WIDTH = 16,
    parameter INPUTS = 3
) (
    input [(WIDTH*INPUTS)-1:0] in_data,
    input [INPUTS-1:0] req_vec,
    output reg [WIDTH-1:0] out_temp
);

    // Priority encoder implementation
    always @(*) begin
        out_temp = {WIDTH{1'b0}};
        casez(req_vec)
            3'b??1: out_temp = in_data[WIDTH-1:0];
            3'b?10: out_temp = in_data[2*WIDTH-1:WIDTH];
            3'b100: out_temp = in_data[3*WIDTH-1:2*WIDTH];
            default: out_temp = {WIDTH{1'b0}};
        endcase
    end

endmodule

///////////////////////////////////////////////////////////////////////////
// Modified Priority Encoder with Subtraction Result
///////////////////////////////////////////////////////////////////////////
module priority_encoder_with_sub #(
    parameter WIDTH = 16,
    parameter INPUTS = 3
) (
    input [(WIDTH*INPUTS)-1:0] in_data,
    input [INPUTS-1:0] req_vec,
    input [7:0] sub_result,
    output reg [WIDTH-1:0] out_temp
);

    // Priority encoder implementation with subtraction
    always @(*) begin
        out_temp = {WIDTH{1'b0}};
        casez(req_vec)
            3'b??1: begin
                out_temp = in_data[WIDTH-1:0];
                // Replace lower 8 bits with subtraction result
                out_temp[7:0] = sub_result;
            end
            3'b?10: out_temp = in_data[2*WIDTH-1:WIDTH];
            3'b100: out_temp = in_data[3*WIDTH-1:2*WIDTH];
            default: out_temp = {WIDTH{1'b0}};
        endcase
    end

endmodule

///////////////////////////////////////////////////////////////////////////
// Output Multiplexer Module
// Selects between prioritized data and zero based on request status
///////////////////////////////////////////////////////////////////////////
module output_mux #(
    parameter WIDTH = 16
) (
    input [WIDTH-1:0] out_temp,
    input any_req,
    output [WIDTH-1:0] out_data
);

    // Output multiplexer
    assign out_data = any_req ? out_temp : {WIDTH{1'b0}};

endmodule