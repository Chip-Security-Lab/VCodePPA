//SystemVerilog
module matrix_transpose_pipelined #(
    parameter DW = 8,
    parameter ROWS = 4,
    parameter COLS = 4
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  en,
    input  wire [DW*ROWS-1:0]    row_in,
    input  wire                  flush,
    output wire [DW*COLS-1:0]    col_out,
    output wire                  valid_out
);

    // Stage 1: Combinational logic for input row and enable signals
    wire [DW*ROWS-1:0]   row_in_stage1_w;
    wire                 en_stage1_w;
    wire                 flush_stage1_w;
    wire                 valid_stage1_w;

    assign row_in_stage1_w = row_in;
    assign en_stage1_w     = en;
    assign flush_stage1_w  = flush;
    assign valid_stage1_w  = en;

    // Stage 2: Registers moved after combinational logic
    reg [DW-1:0] matrix_stage2 [0:ROWS-1][0:COLS-1];
    reg [$clog2(COLS)-1:0] col_index_stage2;
    reg                    flush_stage2;
    reg                    valid_stage2;

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ROWS; i = i + 1) begin
                matrix_stage2[i][0] <= {DW{1'b0}};
                matrix_stage2[i][1] <= {DW{1'b0}};
                matrix_stage2[i][2] <= {DW{1'b0}};
                matrix_stage2[i][3] <= {DW{1'b0}};
            end
            col_index_stage2 <= 0;
            flush_stage2     <= 1'b0;
            valid_stage2     <= 1'b0;
        end else begin
            flush_stage2 <= flush_stage1_w;
            valid_stage2 <= valid_stage1_w;
            if (flush_stage1_w) begin
                for (i = 0; i < ROWS; i = i + 1) begin
                    matrix_stage2[i][0] <= {DW{1'b0}};
                    matrix_stage2[i][1] <= {DW{1'b0}};
                    matrix_stage2[i][2] <= {DW{1'b0}};
                    matrix_stage2[i][3] <= {DW{1'b0}};
                end
                col_index_stage2 <= 0;
            end else if (en_stage1_w) begin
                for (i = 0; i < ROWS; i = i + 1) begin
                    matrix_stage2[i][col_index_stage2] <= row_in_stage1_w[i*DW +: DW];
                end
                if (col_index_stage2 == COLS-1)
                    col_index_stage2 <= 0;
                else
                    col_index_stage2 <= col_index_stage2 + 1'b1;
            end
        end
    end

    // Stage 3: Output column data (first row of each column)
    reg  [DW*COLS-1:0]   col_out_stage3;
    reg                  valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_out_stage3 <= {DW*COLS{1'b0}};
            valid_stage3   <= 1'b0;
        end else begin
            valid_stage3   <= valid_stage2;
            col_out_stage3 <= {
                matrix_stage2[0][COLS-1], 
                matrix_stage2[0][COLS-2], 
                matrix_stage2[0][COLS-3], 
                matrix_stage2[0][0]
            };
        end
    end

    // Output assignment
    assign col_out   = col_out_stage3;
    assign valid_out = valid_stage3;

endmodule