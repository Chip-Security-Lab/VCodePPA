//SystemVerilog
// Top-level module: array_flattener
// Function: Flattens a 2D array (matrix) into a 1D vector (flat_vector) using hierarchical and further modularized submodules.

module array_flattener #(
    parameter ROWS = 4,
    parameter COLS = 4,
    parameter CELL_WIDTH = 8
)(
    input  [ROWS*COLS*CELL_WIDTH-1:0] matrix_flat,
    output [ROWS*COLS*CELL_WIDTH-1:0] flat_vector
);
    // Internal wires for structured signals between submodules
    wire [ROWS-1:0][COLS-1:0][CELL_WIDTH-1:0] matrix_structured;
    wire [ROWS-1:0][COLS*CELL_WIDTH-1:0]      row_flattened;

    // Unpack the flat matrix input to a 2D array for processing
    matrix_unpacker #(
        .ROWS(ROWS),
        .COLS(COLS),
        .CELL_WIDTH(CELL_WIDTH)
    ) u_matrix_unpacker (
        .flat_in(matrix_flat),
        .matrix_out(matrix_structured)
    );

    // Flatten each row using row_flattener_array
    row_flattener_array #(
        .ROWS(ROWS),
        .COLS(COLS),
        .CELL_WIDTH(CELL_WIDTH)
    ) u_row_flattener_array (
        .rows_in(matrix_structured),
        .rows_flat(row_flattened)
    );

    // Assemble the final flat_vector from all row_flattened outputs
    flat_vector_assembler #(
        .ROWS(ROWS),
        .COLS(COLS),
        .CELL_WIDTH(CELL_WIDTH)
    ) u_flat_vector_assembler (
        .rows_in(row_flattened),
        .flat_out(flat_vector)
    );

endmodule

//------------------------------------------------------------------------------
// Submodule: matrix_unpacker
// Function: Converts a flat 1D input into a 2D array for structured processing
//------------------------------------------------------------------------------
module matrix_unpacker #(
    parameter ROWS = 4,
    parameter COLS = 4,
    parameter CELL_WIDTH = 8
)(
    input  [ROWS*COLS*CELL_WIDTH-1:0] flat_in,
    output [ROWS-1:0][COLS-1:0][CELL_WIDTH-1:0] matrix_out
);
    genvar r;
    generate
        for (r = 0; r < ROWS; r = r + 1) begin : g_unpack_rows
            row_unpacker #(
                .COLS(COLS),
                .CELL_WIDTH(CELL_WIDTH)
            ) u_row_unpacker (
                .row_flat_in(flat_in[(r*COLS*CELL_WIDTH) +: COLS*CELL_WIDTH]),
                .row_struct_out(matrix_out[r])
            );
        end
    endgenerate
endmodule

//------------------------------------------------------------------------------
// Submodule: row_unpacker
// Function: Converts a flat 1D input row into a structured 2D row array
//------------------------------------------------------------------------------
module row_unpacker #(
    parameter COLS = 4,
    parameter CELL_WIDTH = 8
)(
    input  [COLS*CELL_WIDTH-1:0] row_flat_in,
    output [COLS-1:0][CELL_WIDTH-1:0] row_struct_out
);
    genvar c;
    generate
        for (c = 0; c < COLS; c = c + 1) begin : g_unpack_cols
            assign row_struct_out[c] = row_flat_in[c*CELL_WIDTH +: CELL_WIDTH];
        end
    endgenerate
endmodule

//------------------------------------------------------------------------------
// Submodule: row_flattener_array
// Function: Applies row_flattener to each row in the matrix
//------------------------------------------------------------------------------
module row_flattener_array #(
    parameter ROWS = 4,
    parameter COLS = 4,
    parameter CELL_WIDTH = 8
)(
    input  [ROWS-1:0][COLS-1:0][CELL_WIDTH-1:0] rows_in,
    output [ROWS-1:0][COLS*CELL_WIDTH-1:0]      rows_flat
);
    genvar r;
    generate
        for (r = 0; r < ROWS; r = r + 1) begin : g_row_flatten_array
            row_flattener #(
                .COLS(COLS),
                .CELL_WIDTH(CELL_WIDTH)
            ) u_row_flattener (
                .row_in(rows_in[r]),
                .row_flat(rows_flat[r])
            );
        end
    endgenerate
endmodule

//------------------------------------------------------------------------------
// Submodule: row_flattener
// Function: Flattens a single row of the matrix into a 1D vector
//------------------------------------------------------------------------------
module row_flattener #(
    parameter COLS = 4,
    parameter CELL_WIDTH = 8
)(
    input  [COLS-1:0][CELL_WIDTH-1:0] row_in,
    output [COLS*CELL_WIDTH-1:0]      row_flat
);
    genvar c;
    generate
        for (c = 0; c < COLS; c = c + 1) begin : g_col_flatten
            cell_flattener #(
                .CELL_WIDTH(CELL_WIDTH)
            ) u_cell_flattener (
                .cell_in(row_in[c]),
                .cell_flat(row_flat[c*CELL_WIDTH +: CELL_WIDTH])
            );
        end
    endgenerate
endmodule

//------------------------------------------------------------------------------
// Submodule: cell_flattener
// Function: Passes through the cell data from structured to flat vector
//------------------------------------------------------------------------------
module cell_flattener #(
    parameter CELL_WIDTH = 8
)(
    input  [CELL_WIDTH-1:0] cell_in,
    output [CELL_WIDTH-1:0] cell_flat
);
    // Simple wire-through for cell
    assign cell_flat = cell_in;
endmodule

//------------------------------------------------------------------------------
// Submodule: flat_vector_assembler
// Function: Concatenates all flattened rows into the final 1D flat_vector
//------------------------------------------------------------------------------
module flat_vector_assembler #(
    parameter ROWS = 4,
    parameter COLS = 4,
    parameter CELL_WIDTH = 8
)(
    input  [ROWS-1:0][COLS*CELL_WIDTH-1:0] rows_in,
    output [ROWS*COLS*CELL_WIDTH-1:0]      flat_out
);
    genvar r;
    generate
        for (r = 0; r < ROWS; r = r + 1) begin : g_row_concat
            assign flat_out[r*COLS*CELL_WIDTH +: COLS*CELL_WIDTH] = rows_in[r];
        end
    endgenerate
endmodule