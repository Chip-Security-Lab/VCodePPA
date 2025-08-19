//SystemVerilog
module matrix_transpose #(parameter DW=8, ROWS=4, COLS=4) (
    input clk,
    input en,
    input [DW*ROWS-1:0] row_in,
    output reg [DW*COLS-1:0] col_out
);

    reg [DW-1:0] matrix_storage [0:ROWS-1][0:COLS-1];
    reg [$clog2(COLS):0] current_col_idx;
    reg [DW-1:0] output_buffer [0:COLS-1];

    integer i;

    // Column index update
    always @(posedge clk) begin
        if (en) begin
            if (current_col_idx == COLS-1)
                current_col_idx <= 0;
            else
                current_col_idx <= current_col_idx + 1;
        end
    end

    // Matrix storage update
    always @(posedge clk) begin
        if (en) begin
            for (i = 0; i < ROWS; i = i + 1) begin
                matrix_storage[i][current_col_idx] <= row_in[i*DW +: DW];
            end
        end
    end

    // Output buffer update
    always @(posedge clk) begin
        for (i = 0; i < COLS; i = i + 1) begin
            output_buffer[i] <= matrix_storage[0][i];
        end
    end

    // Output assignment
    always @(*) begin
        for (i = 0; i < COLS; i = i + 1) begin
            col_out[i*DW +: DW] = output_buffer[i];
        end
    end

endmodule