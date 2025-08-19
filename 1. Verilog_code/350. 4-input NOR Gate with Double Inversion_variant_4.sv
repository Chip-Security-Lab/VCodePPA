//SystemVerilog
module nor4_double_invert (
    input wire A,
    input wire B,
    input wire C,
    input wire D,
    output wire Y
);

    // Buffer registers for high fanout signals
    reg A_buf1, A_buf2;
    reg B_buf1, B_buf2;
    reg C_buf1, C_buf2;

    // Clock generation for pipelining (assuming all inputs are asynchronous, derive a global clock)
    wire clk;
    assign clk = A | B | C | D;

    // Stage 1: Buffering high fanout signals
    always @(posedge clk) begin
        A_buf1 <= A;
        A_buf2 <= A_buf1;
        B_buf1 <= B;
        B_buf2 <= B_buf1;
        C_buf1 <= C;
        C_buf2 <= C_buf1;
    end

    // Stage 2: Input aggregation using buffered signals
    wire stage1_or_ab;
    wire stage1_or_cd;

    assign stage1_or_ab = A_buf2 | B_buf2;
    assign stage1_or_cd = C_buf2 | D;

    // Stage 3: Intermediate OR combination
    wire stage2_or_abcd;
    assign stage2_or_abcd = stage1_or_ab | stage1_or_cd;

    // Stage 4: Pipeline register (cuts long path, improves timing)
    reg stage3_or_abcd_reg;
    always @(posedge clk) begin
        stage3_or_abcd_reg <= stage2_or_abcd;
    end

    // Stage 5: NOR operation and output register for clean output path
    reg stage4_nor_result;
    always @(posedge clk) begin
        stage4_nor_result <= ~stage3_or_abcd_reg;
    end

    assign Y = stage4_nor_result;

endmodule