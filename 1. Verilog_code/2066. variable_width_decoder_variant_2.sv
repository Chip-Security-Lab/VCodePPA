//SystemVerilog
// Top-level variable width decoder module with barrel shifter-based decoders
module variable_width_decoder #(
    parameter IN_WIDTH = 3,
    parameter OUT_SEL = 2
) (
    input  wire [IN_WIDTH-1:0] encoded_in,
    input  wire [OUT_SEL-1:0]  width_sel,
    output wire [(2**IN_WIDTH)-1:0] decoded_out
);

    wire [(2**IN_WIDTH)-1:0] decoded_2way;
    wire [(2**IN_WIDTH)-1:0] decoded_4way;
    wire [(2**IN_WIDTH)-1:0] decoded_8way;
    wire [(2**IN_WIDTH)-1:0] decoded_full;

    // 2-way decoder instance
    decoder_2way #(
        .OUT_WIDTH(2**IN_WIDTH)
    ) u_decoder_2way (
        .sel(encoded_in[0:0]),
        .decoded(decoded_2way)
    );

    // 4-way decoder instance
    decoder_4way #(
        .OUT_WIDTH(2**IN_WIDTH)
    ) u_decoder_4way (
        .sel(encoded_in[1:0]),
        .decoded(decoded_4way)
    );

    // 8-way decoder instance
    decoder_8way #(
        .OUT_WIDTH(2**IN_WIDTH)
    ) u_decoder_8way (
        .sel(encoded_in[2:0]),
        .decoded(decoded_8way)
    );

    // Full-width decoder instance
    decoder_full #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(2**IN_WIDTH)
    ) u_decoder_full (
        .sel(encoded_in[IN_WIDTH-1:0]),
        .decoded(decoded_full)
    );

    // Output multiplexer
    decoder_output_mux #(
        .OUT_WIDTH(2**IN_WIDTH)
    ) u_decoder_output_mux (
        .width_sel(width_sel),
        .decoded_2way(decoded_2way),
        .decoded_4way(decoded_4way),
        .decoded_8way(decoded_8way),
        .decoded_full(decoded_full),
        .decoded_out(decoded_out)
    );

endmodule

//-----------------------------------------------------------------------------
// 2-way decoder module: Decodes 1-bit input to 2-way output, expanded to OUT_WIDTH
// Barrel shifter structure
//-----------------------------------------------------------------------------
module decoder_2way #(
    parameter OUT_WIDTH = 8
) (
    input  wire [0:0] sel,
    output wire [OUT_WIDTH-1:0] decoded
);
    wire [OUT_WIDTH-1:0] stage0;

    // Initial bit
    assign stage0 = { {OUT_WIDTH-1{1'b0}}, 1'b1 };

    // Barrel shifter - 1 stage for 1 bit shift
    genvar i;
    generate
        for (i = 0; i < OUT_WIDTH; i = i + 1) begin : gen_2way_shift
            assign decoded[i] = (sel[0] == 1'b0) ? stage0[i] :
                                ((i >= 1) ? stage0[i-1] : 1'b0);
        end
    endgenerate
endmodule

//-----------------------------------------------------------------------------
// 4-way decoder module: Decodes 2-bit input to 4-way output, expanded to OUT_WIDTH
// Barrel shifter structure
//-----------------------------------------------------------------------------
module decoder_4way #(
    parameter OUT_WIDTH = 8
) (
    input  wire [1:0] sel,
    output wire [OUT_WIDTH-1:0] decoded
);
    wire [OUT_WIDTH-1:0] stage0;
    wire [OUT_WIDTH-1:0] stage1;

    // Initial bit
    assign stage0 = { {OUT_WIDTH-1{1'b0}}, 1'b1 };

    // Barrel shifter - stage 0: shift by sel[0]
    genvar i0;
    generate
        for (i0 = 0; i0 < OUT_WIDTH; i0 = i0 + 1) begin : gen_4way_stage0
            assign stage1[i0] = (sel[0] == 1'b0) ? stage0[i0] :
                                ((i0 >= 1) ? stage0[i0-1] : 1'b0);
        end
    endgenerate

    // Barrel shifter - stage 1: shift by 2*sel[1]
    genvar i1;
    generate
        for (i1 = 0; i1 < OUT_WIDTH; i1 = i1 + 1) begin : gen_4way_stage1
            assign decoded[i1] = (sel[1] == 1'b0) ? stage1[i1] :
                                 ((i1 >= 2) ? stage1[i1-2] : 1'b0);
        end
    endgenerate
endmodule

//-----------------------------------------------------------------------------
// 8-way decoder module: Decodes 3-bit input to 8-way output, expanded to OUT_WIDTH
// Barrel shifter structure
//-----------------------------------------------------------------------------
module decoder_8way #(
    parameter OUT_WIDTH = 8
) (
    input  wire [2:0] sel,
    output wire [OUT_WIDTH-1:0] decoded
);
    wire [OUT_WIDTH-1:0] stage0;
    wire [OUT_WIDTH-1:0] stage1;
    wire [OUT_WIDTH-1:0] stage2;

    // Initial bit
    assign stage0 = { {OUT_WIDTH-1{1'b0}}, 1'b1 };

    // Barrel shifter - stage 0: shift by sel[0]
    genvar i0;
    generate
        for (i0 = 0; i0 < OUT_WIDTH; i0 = i0 + 1) begin : gen_8way_stage0
            assign stage1[i0] = (sel[0] == 1'b0) ? stage0[i0] :
                                ((i0 >= 1) ? stage0[i0-1] : 1'b0);
        end
    endgenerate

    // Barrel shifter - stage 1: shift by 2*sel[1]
    genvar i1;
    generate
        for (i1 = 0; i1 < OUT_WIDTH; i1 = i1 + 1) begin : gen_8way_stage1
            assign stage2[i1] = (sel[1] == 1'b0) ? stage1[i1] :
                                ((i1 >= 2) ? stage1[i1-2] : 1'b0);
        end
    endgenerate

    // Barrel shifter - stage 2: shift by 4*sel[2]
    genvar i2;
    generate
        for (i2 = 0; i2 < OUT_WIDTH; i2 = i2 + 1) begin : gen_8way_stage2
            assign decoded[i2] = (sel[2] == 1'b0) ? stage2[i2] :
                                 ((i2 >= 4) ? stage2[i2-4] : 1'b0);
        end
    endgenerate
endmodule

//-----------------------------------------------------------------------------
// Full-width decoder module: Decodes IN_WIDTH input to OUT_WIDTH output
// Barrel shifter structure (parameterized)
//-----------------------------------------------------------------------------
module decoder_full #(
    parameter IN_WIDTH = 3,
    parameter OUT_WIDTH = 8
) (
    input  wire [IN_WIDTH-1:0] sel,
    output wire [OUT_WIDTH-1:0] decoded
);
    wire [OUT_WIDTH-1:0] stage [0:IN_WIDTH];

    assign stage[0] = { {OUT_WIDTH-1{1'b0}}, 1'b1 };

    genvar s, i;
    generate
        for (s = 0; s < IN_WIDTH; s = s + 1) begin : gen_full_stages
            for (i = 0; i < OUT_WIDTH; i = i + 1) begin : gen_full_bits
                assign stage[s+1][i] = (sel[s] == 1'b0) ? stage[s][i] :
                                       ((i >= (1<<s)) ? stage[s][i-(1<<s)] : 1'b0);
            end
        end
    endgenerate

    assign decoded = stage[IN_WIDTH];
endmodule

//-----------------------------------------------------------------------------
// Decoder output multiplexer: Selects decoded output based on width_sel
//-----------------------------------------------------------------------------
module decoder_output_mux #(
    parameter OUT_WIDTH = 8
) (
    input  wire [1:0] width_sel,
    input  wire [OUT_WIDTH-1:0] decoded_2way,
    input  wire [OUT_WIDTH-1:0] decoded_4way,
    input  wire [OUT_WIDTH-1:0] decoded_8way,
    input  wire [OUT_WIDTH-1:0] decoded_full,
    output reg  [OUT_WIDTH-1:0] decoded_out
);
    always @(*) begin
        case (width_sel)
            2'd0: decoded_out = decoded_2way;
            2'd1: decoded_out = decoded_4way;
            2'd2: decoded_out = decoded_8way;
            2'd3: decoded_out = decoded_full;
            default: decoded_out = {OUT_WIDTH{1'b0}};
        endcase
    end
endmodule