//SystemVerilog
module matrix_transpose #(parameter DW=8, ROWS=4, COLS=4) (
    input clk,
    input en,
    input [DW*ROWS-1:0] row_in,
    output reg [DW*COLS-1:0] col_out
);
    reg [DW-1:0] matrix_reg [0:ROWS-1][0:COLS-1];
    reg [$clog2(COLS)-1:0] col_index_reg;

    integer i, j;

    // Optimized combinational logic for matrix update and column index
    wire col_index_last = (col_index_reg == (COLS[$clog2(COLS)-1:0] - 1'b1));
    wire [$clog2(COLS)-1:0] col_index_next = en ? (col_index_last ? {$clog2(COLS){1'b0}} : (col_index_reg + 1'b1)) : col_index_reg;

    // Create a mask for the current column to be updated
    wire [COLS-1:0] col_mask;
    genvar gv_j;
    generate
        for (gv_j = 0; gv_j < COLS; gv_j = gv_j + 1) begin : col_mask_gen
            assign col_mask[gv_j] = (col_index_reg == gv_j);
        end
    endgenerate

    // Sequential logic for matrix and column index
    always @(posedge clk) begin
        col_index_reg <= col_index_next;
        for (i = 0; i < ROWS; i = i + 1) begin
            for (j = 0; j < COLS; j = j + 1) begin
                if (en && col_mask[j]) begin
                    matrix_reg[i][j] <= row_in[i*DW +: DW];
                end else begin
                    matrix_reg[i][j] <= matrix_reg[i][j];
                end
            end
        end
    end

    // Register output to move output register before combinational logic
    reg [DW*COLS-1:0] col_out_reg;
    always @(posedge clk) begin
        for (j = 0; j < COLS; j = j + 1) begin
            col_out_reg[j*DW +: DW] <= matrix_reg[0][j];
        end
        col_out <= col_out_reg;
    end

endmodule