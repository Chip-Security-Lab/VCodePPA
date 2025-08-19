//SystemVerilog
//IEEE 1364-2005 Verilog
module matrix_transpose_pipeline #(
    parameter DW = 8,
    parameter ROWS = 4,
    parameter COLS = 4
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  en,
    input  wire [DW*ROWS-1:0]    row_in,
    output wire [DW*COLS-1:0]    col_out,
    output wire                  valid_out
);

    // Pipeline Stage 1: Unpack input, move register after combination logic (forward retiming)
    wire [DW-1:0] unpacked_matrix_row_stage1 [0:ROWS-1];
    genvar gi;
    generate
        for (gi = 0; gi < ROWS; gi = gi + 1) begin : unpack_row
            assign unpacked_matrix_row_stage1[gi] = row_in[gi*DW +: DW];
        end
    endgenerate
    wire en_stage1_wire = en;
    wire valid_stage1_wire = en;

    // Pipeline Stage 2: Register after unpacking and enable
    reg [DW-1:0]         matrix_row_stage2 [0:ROWS-1];
    reg                  en_stage2;
    reg                  valid_stage2;
    reg [$clog2(COLS):0] col_idx_stage2;

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ROWS; i = i + 1) begin
                matrix_row_stage2[i] <= {DW{1'b0}};
            end
            en_stage2     <= 1'b0;
            valid_stage2  <= 1'b0;
            col_idx_stage2 <= 0;
        end else begin
            for (i = 0; i < ROWS; i = i + 1) begin
                matrix_row_stage2[i] <= unpacked_matrix_row_stage1[i];
            end
            en_stage2     <= en_stage1_wire;
            valid_stage2  <= valid_stage1_wire;
            if (en_stage1_wire) begin
                col_idx_stage2 <= (col_idx_stage2 == COLS-1) ? 0 : manchester_carry_add(col_idx_stage2, 1'b1, 1'b0);
            end
        end
    end

    // Pipeline Stage 3: Write into matrix storage
    reg [DW-1:0] matrix_stage3 [0:ROWS-1][0:COLS-1];
    reg [$clog2(COLS):0] col_idx_stage3;
    reg                  valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ROWS; i = i + 1) begin
                for (integer j = 0; j < COLS; j = j + 1) begin
                    matrix_stage3[i][j] <= {DW{1'b0}};
                end
            end
            col_idx_stage3 <= 0;
            valid_stage3   <= 1'b0;
        end else begin
            if (valid_stage2) begin
                for (i = 0; i < ROWS; i = i + 1) begin
                    matrix_stage3[i][col_idx_stage2] <= matrix_row_stage2[i];
                end
                col_idx_stage3 <= col_idx_stage2;
                valid_stage3   <= 1'b1;
            end else begin
                valid_stage3   <= 1'b0;
            end
        end
    end

    // Pipeline Stage 4: Output columns (transpose)
    reg [DW*COLS-1:0] col_out_stage4;
    reg               valid_stage4;

    genvar c;
    generate
        for (c = 0; c < COLS; c = c + 1) begin: col_assign
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    col_out_stage4[c*DW +: DW] <= {DW{1'b0}};
                end else if (valid_stage3) begin
                    col_out_stage4[c*DW +: DW] <= matrix_stage3[0][c];
                end
            end
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage4 <= 1'b0;
        end else begin
            valid_stage4 <= valid_stage3;
        end
    end

    assign col_out  = col_out_stage4;
    assign valid_out = valid_stage4;

    // 曼彻斯特进位链加法器实例
    function [($clog2(COLS)):0] manchester_carry_add;
        input [($clog2(COLS)):0] a;
        input [($clog2(COLS)):0] b;
        input                    cin;
        reg   [($clog2(COLS)):0] p;
        reg   [($clog2(COLS)):0] g;
        reg   [($clog2(COLS)):0] c;
        integer k;
        begin
            for (k = 0; k <= $clog2(COLS); k = k + 1) begin
                p[k] = a[k] ^ b[k];
                g[k] = a[k] & b[k];
            end
            c[0] = cin;
            for (k = 1; k <= $clog2(COLS); k = k + 1) begin
                c[k] = g[k-1] | (p[k-1] & c[k-1]);
            end
            for (k = 0; k <= $clog2(COLS); k = k + 1) begin
                manchester_carry_add[k] = p[k] ^ c[k];
            end
        end
    endfunction

endmodule