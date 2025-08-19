//SystemVerilog
// Top-level Interleaver Module with Hierarchical Structure
module interleaver #(parameter DW=8, ROWS=4, COLS=4) (
    input  [ROWS*COLS*DW-1:0] data_in,
    output [ROWS*COLS*DW-1:0] data_out
);

    // Internal wires to connect submodules
    wire [DW-1:0] matrix_in   [0:ROWS-1][0:COLS-1];
    wire [DW-1:0] matrix_out  [0:ROWS-1][0:COLS-1];
    genvar i, j;

    // Input Unpack Submodule: Flattens input vector into 2D matrix
    input_unpack #(.DW(DW), .ROWS(ROWS), .COLS(COLS)) u_input_unpack (
        .data_in(data_in),
        .data_matrix(matrix_in)
    );

    // Interleaver Core Submodule: Performs interleaving operation
    interleaver_core #(.DW(DW), .ROWS(ROWS), .COLS(COLS)) u_interleaver_core (
        .data_matrix_in(matrix_in),
        .data_matrix_out(matrix_out)
    );

    // Output Pack Submodule: Packs 2D matrix into output vector
    output_pack #(.DW(DW), .ROWS(ROWS), .COLS(COLS)) u_output_pack (
        .data_matrix(matrix_out),
        .data_out(data_out)
    );

endmodule

// -------------------------------------------------------------------------
// Submodule: input_unpack
// Function: Unpacks flat input vector into 2D matrix form
// -------------------------------------------------------------------------
module input_unpack #(parameter DW=8, ROWS=4, COLS=4) (
    input  [ROWS*COLS*DW-1:0] data_in,
    output [DW-1:0] data_matrix [0:ROWS-1][0:COLS-1]
);
    genvar r, c;
    generate
        for (r = 0; r < ROWS; r = r + 1) begin: gen_rows
            for (c = 0; c < COLS; c = c + 1) begin: gen_cols
                assign data_matrix[r][c] = data_in[(r*COLS + c)*DW +: DW];
            end
        end
    endgenerate
endmodule

// -------------------------------------------------------------------------
// Submodule: interleaver_core
// Function: Performs the interleaving mapping from input matrix to output matrix
// -------------------------------------------------------------------------
module interleaver_core #(parameter DW=8, ROWS=4, COLS=4) (
    input  [DW-1:0] data_matrix_in [0:ROWS-1][0:COLS-1],
    output [DW-1:0] data_matrix_out [0:ROWS-1][0:COLS-1]
);
    genvar r, c;
    generate
        for (c = 0; c < COLS; c = c + 1) begin: gen_cols
            for (r = 0; r < ROWS; r = r + 1) begin: gen_rows
                assign data_matrix_out[r][c] = data_matrix_in[c][r];
            end
        end
    endgenerate
endmodule

// -------------------------------------------------------------------------
// Submodule: output_pack
// Function: Packs 2D output matrix into flat output vector
// -------------------------------------------------------------------------
module output_pack #(parameter DW=8, ROWS=4, COLS=4) (
    input  [DW-1:0] data_matrix [0:ROWS-1][0:COLS-1],
    output [ROWS*COLS*DW-1:0] data_out
);
    genvar r, c;
    generate
        for (c = 0; c < COLS; c = c + 1) begin: gen_cols
            for (r = 0; r < ROWS; r = r + 1) begin: gen_rows
                assign data_out[(c*ROWS + r)*DW +: DW] = data_matrix[r][c];
            end
        end
    endgenerate
endmodule