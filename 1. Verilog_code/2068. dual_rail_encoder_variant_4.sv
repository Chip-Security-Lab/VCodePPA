//SystemVerilog
// Hierarchical dual-rail encoder with modular structure and improved PPA

//------------------------------------------------------------------------------
// Submodule: dual_rail_bit_encoder
// Function: Encodes a single bit into a dual-rail representation
// Inputs:  bit_in    - data bit to encode
//          valid_in  - enables output, otherwise outputs are 0
// Outputs: dual_rail_out_0 - dual-rail output for '1'
//          dual_rail_out_1 - dual-rail output for '0'
//------------------------------------------------------------------------------
module dual_rail_bit_encoder (
    input  wire bit_in,
    input  wire valid_in,
    output wire dual_rail_out_0,
    output wire dual_rail_out_1
);
    assign dual_rail_out_0 = bit_in  & valid_in;
    assign dual_rail_out_1 = ~bit_in & valid_in;
endmodule

//------------------------------------------------------------------------------
// Submodule: dual_rail_vector_encoder
// Function: Encodes a vector of bits into dual-rail representation using
//           dual_rail_bit_encoder submodules
// Parameters:
//   DATA_WIDTH - Width of input data vector
// Inputs:
//   data_vec_in  - Input data vector
//   valid_vec_in - Valid signal for data vector
// Outputs:
//   dual_rail_vec_out - Dual-rail encoded output vector
//------------------------------------------------------------------------------
module dual_rail_vector_encoder #(
    parameter DATA_WIDTH = 4
)(
    input  wire [DATA_WIDTH-1:0]   data_vec_in,
    input  wire                    valid_vec_in,
    output wire [2*DATA_WIDTH-1:0] dual_rail_vec_out
);
    genvar j;
    generate
        for (j = 0; j < DATA_WIDTH; j = j + 1) begin : gen_vector_bit
            dual_rail_bit_encoder u_bit_enc (
                .bit_in         (data_vec_in[j]),
                .valid_in       (valid_vec_in),
                .dual_rail_out_0(dual_rail_vec_out[2*j]),
                .dual_rail_out_1(dual_rail_vec_out[2*j+1])
            );
        end
    endgenerate
endmodule

//------------------------------------------------------------------------------
// Top-level module: dual_rail_encoder
// Function: Encodes input data vector into dual-rail representation
//           using modular submodules for improved clarity and PPA
// Parameters:
//   WIDTH - Width of input data vector
// Inputs:
//   data_in    - Input data vector
//   valid_in   - Valid signal for input data
// Outputs:
//   dual_rail_out - Dual-rail encoded output vector
//------------------------------------------------------------------------------
module dual_rail_encoder #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0]       data_in,
    input  wire                   valid_in,
    output wire [2*WIDTH-1:0]     dual_rail_out
);

    // Instance of dual_rail_vector_encoder for vector encoding
    dual_rail_vector_encoder #(
        .DATA_WIDTH(WIDTH)
    ) u_vector_encoder (
        .data_vec_in      (data_in),
        .valid_vec_in     (valid_in),
        .dual_rail_vec_out(dual_rail_out)
    );

endmodule