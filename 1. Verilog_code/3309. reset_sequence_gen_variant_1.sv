//SystemVerilog
module reset_sequence_gen(
    input  wire        clk,
    input  wire        trigger_reset,
    input  wire        config_mode,
    input  wire [1:0]  sequence_select,
    output reg         core_rst,
    output reg         periph_rst,
    output reg         mem_rst,
    output reg         io_rst,
    output reg         sequence_done
);

    // Main state registers
    reg  [2:0] seq_counter_reg      = 3'd0;
    reg        seq_active_reg       = 1'b0;
    reg        sequence_done_reg    = 1'b0;

    // Buffer registers for high fanout signals (1st level)
    reg  [2:0] seq_counter_buf1;
    reg  [2:0] seq_counter_buf2;
    reg        seq_active_buf1;
    reg        seq_active_buf2;
    reg        advance_seq_buf1;
    reg        advance_seq_buf2;
    reg  [2:0] seq_counter_next_buf1;
    reg  [2:0] seq_counter_next_buf2;
    reg        b0000_buf1;
    reg        b0000_buf2;

    // Combinational signals
    wire       start_seq_int;
    wire       advance_seq_int;
    wire [2:0] seq_counter_next_int;
    wire       seq_active_next_int;
    wire       sequence_done_next_int;

    assign start_seq_int   = trigger_reset & ~seq_active_reg;
    assign advance_seq_int = seq_active_reg;

    // Expand conditional operators to if-else structures
    reg [2:0] seq_counter_next_int_r;
    always @(*) begin
        if (start_seq_int) begin
            seq_counter_next_int_r = 3'd0;
        end else if (advance_seq_int) begin
            seq_counter_next_int_r = seq_counter_reg + 3'd1;
        end else begin
            seq_counter_next_int_r = seq_counter_reg;
        end
    end
    assign seq_counter_next_int = seq_counter_next_int_r;

    reg seq_active_next_int_r;
    always @(*) begin
        if (start_seq_int) begin
            seq_active_next_int_r = 1'b1;
        end else if (advance_seq_int && (seq_counter_reg == 3'd7)) begin
            seq_active_next_int_r = 1'b0;
        end else begin
            seq_active_next_int_r = seq_active_reg;
        end
    end
    assign seq_active_next_int = seq_active_next_int_r;

    reg sequence_done_next_int_r;
    always @(*) begin
        if (start_seq_int) begin
            sequence_done_next_int_r = 1'b0;
        end else if (advance_seq_int && (seq_counter_reg == 3'd7)) begin
            sequence_done_next_int_r = 1'b1;
        end else begin
            sequence_done_next_int_r = sequence_done_reg;
        end
    end
    assign sequence_done_next_int = sequence_done_next_int_r;

    // Buffering high fanout signals (1st level)
    always @(posedge clk) begin
        seq_counter_buf1    <= seq_counter_reg;
        seq_counter_buf2    <= seq_counter_buf1;
        seq_active_buf1     <= seq_active_reg;
        seq_active_buf2     <= seq_active_buf1;
        advance_seq_buf1    <= advance_seq_int;
        advance_seq_buf2    <= advance_seq_buf1;
        seq_counter_next_buf1 <= seq_counter_next_int;
        seq_counter_next_buf2 <= seq_counter_next_buf1;
        b0000_buf1          <= 1'b0;
        b0000_buf2          <= b0000_buf1;
    end

    // Precompute all reset patterns for all sequence_select and seq_counter
    wire [3:0] rst_pattern_00_stage0 = 4'b1111;
    wire [3:0] rst_pattern_00_stage1 = 4'b0111;
    wire [3:0] rst_pattern_00_stage2 = 4'b0011;
    wire [3:0] rst_pattern_00_stage3 = 4'b0000;
    wire [3:0] rst_pattern_01_stage0 = 4'b1111;
    wire [3:0] rst_pattern_01_stage1 = 4'b0101;
    wire [3:0] rst_pattern_01_stage2 = 4'b0000;
    wire [3:0] rst_pattern_default   = {4{seq_active_next_int}};

    wire [3:0] rst_pattern_00_int, rst_pattern_01_int, rst_pattern_sel_int;

    // Buffer for b0000 constant (to reduce fanout)
    wire [3:0] b0000_buf = {b0000_buf2, b0000_buf2, b0000_buf2, b0000_buf2};

    // Expanded combinational logic for pattern selection using if-else
    reg [3:0] rst_pattern_00_int_r;
    always @(*) begin
        if (~seq_active_next_int) begin
            rst_pattern_00_int_r = b0000_buf;
        end else if (seq_counter_next_int < 3'd2) begin
            rst_pattern_00_int_r = rst_pattern_00_stage0;
        end else if (seq_counter_next_int < 3'd4) begin
            rst_pattern_00_int_r = rst_pattern_00_stage1;
        end else if (seq_counter_next_int < 3'd6) begin
            rst_pattern_00_int_r = rst_pattern_00_stage2;
        end else begin
            rst_pattern_00_int_r = rst_pattern_00_stage3;
        end
    end
    assign rst_pattern_00_int = rst_pattern_00_int_r;

    reg [3:0] rst_pattern_01_int_r;
    always @(*) begin
        if (~seq_active_next_int) begin
            rst_pattern_01_int_r = b0000_buf;
        end else if (seq_counter_next_int < 3'd3) begin
            rst_pattern_01_int_r = rst_pattern_01_stage0;
        end else if (seq_counter_next_int < 3'd5) begin
            rst_pattern_01_int_r = rst_pattern_01_stage1;
        end else begin
            rst_pattern_01_int_r = rst_pattern_01_stage2;
        end
    end
    assign rst_pattern_01_int = rst_pattern_01_int_r;

    reg [3:0] rst_pattern_sel_int_r;
    always @(*) begin
        if (sequence_select == 2'b00) begin
            rst_pattern_sel_int_r = rst_pattern_00_int;
        end else if (sequence_select == 2'b01) begin
            rst_pattern_sel_int_r = rst_pattern_01_int;
        end else begin
            rst_pattern_sel_int_r = rst_pattern_default;
        end
    end
    assign rst_pattern_sel_int = rst_pattern_sel_int_r;

    // Output buffer registers (2nd level buffers for high fanout nets)
    reg  [2:0] seq_counter_out_buf;
    reg        seq_active_out_buf;
    reg        advance_seq_out_buf;
    reg  [2:0] seq_counter_next_out_buf;
    reg  [3:0] rst_pattern_sel_buf;
    reg        sequence_done_out_buf;

    always @(posedge clk) begin
        // Main state update
        seq_counter_reg      <= seq_counter_next_int;
        seq_active_reg       <= seq_active_next_int;
        sequence_done_reg    <= sequence_done_next_int;

        // 2nd level output buffer
        seq_counter_out_buf      <= seq_counter_next_buf2;
        seq_active_out_buf       <= seq_active_buf2;
        advance_seq_out_buf      <= advance_seq_buf2;
        seq_counter_next_out_buf <= seq_counter_next_buf2;
        rst_pattern_sel_buf      <= rst_pattern_sel_int;
        sequence_done_out_buf    <= sequence_done_next_int;

        // Output assignments
        {core_rst, periph_rst, mem_rst, io_rst} <= rst_pattern_sel_buf;
        sequence_done                           <= sequence_done_out_buf;
    end

endmodule