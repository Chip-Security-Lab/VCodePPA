//SystemVerilog
// SystemVerilog
// Top-level module: Pipelined hierarchical reset sequence generator
module reset_sequence_gen(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        trigger_reset,
    input  wire        config_mode,
    input  wire [1:0]  sequence_select,
    output wire        core_rst,
    output wire        periph_rst,
    output wire        mem_rst,
    output wire        io_rst,
    output wire        sequence_done
);

    // Stage 1: Input capture
    wire                trigger_reset_stage1;
    wire [1:0]          sequence_select_stage1;
    wire                config_mode_stage1;

    pipeline_reg_input_stage u_input_stage (
        .clk(clk),
        .rst_n(rst_n),
        .trigger_reset(trigger_reset),
        .sequence_select(sequence_select),
        .config_mode(config_mode),
        .trigger_reset_stage1(trigger_reset_stage1),
        .sequence_select_stage1(sequence_select_stage1),
        .config_mode_stage1(config_mode_stage1)
    );

    // Stage 2: Sequencing control
    wire                seq_active_stage2;
    wire [2:0]          seq_counter_stage2;
    wire                sequence_done_stage2;
    wire                valid_stage2;
    wire                flush_stage2;

    pipeline_reg_ctrl_stage u_ctrl_stage (
        .clk(clk),
        .rst_n(rst_n),
        .trigger_reset_stage1(trigger_reset_stage1),
        .valid_in(1'b1),
        .flush_in(1'b0),
        .seq_active_stage2(seq_active_stage2),
        .seq_counter_stage2(seq_counter_stage2),
        .sequence_done_stage2(sequence_done_stage2),
        .valid_stage2(valid_stage2),
        .flush_stage2(flush_stage2)
    );

    // Stage 3: Output logic
    wire                core_rst_stage3;
    wire                periph_rst_stage3;
    wire                mem_rst_stage3;
    wire                io_rst_stage3;
    wire                sequence_done_stage3;
    wire                valid_stage3;
    wire                flush_stage3;

    pipeline_reg_output_stage u_output_stage (
        .clk(clk),
        .rst_n(rst_n),
        .seq_active_stage2(seq_active_stage2),
        .seq_counter_stage2(seq_counter_stage2),
        .sequence_select_stage1(sequence_select_stage1),
        .sequence_done_stage2(sequence_done_stage2),
        .valid_stage2(valid_stage2),
        .flush_stage2(flush_stage2),
        .core_rst_stage3(core_rst_stage3),
        .periph_rst_stage3(periph_rst_stage3),
        .mem_rst_stage3(mem_rst_stage3),
        .io_rst_stage3(io_rst_stage3),
        .sequence_done_stage3(sequence_done_stage3),
        .valid_stage3(valid_stage3),
        .flush_stage3(flush_stage3)
    );

    // Final outputs
    assign core_rst      = core_rst_stage3;
    assign periph_rst    = periph_rst_stage3;
    assign mem_rst       = mem_rst_stage3;
    assign io_rst        = io_rst_stage3;
    assign sequence_done = sequence_done_stage3;

endmodule

//-----------------------------------------------------------------------------
// Stage 1: Input pipeline register
//-----------------------------------------------------------------------------
module pipeline_reg_input_stage(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        trigger_reset,
    input  wire [1:0]  sequence_select,
    input  wire        config_mode,
    output reg         trigger_reset_stage1,
    output reg [1:0]   sequence_select_stage1,
    output reg         config_mode_stage1
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trigger_reset_stage1   <= 1'b0;
            sequence_select_stage1 <= 2'b00;
            config_mode_stage1     <= 1'b0;
        end else begin
            trigger_reset_stage1   <= trigger_reset;
            sequence_select_stage1 <= sequence_select;
            config_mode_stage1     <= config_mode;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Stage 2: Sequencing controller with pipeline
//-----------------------------------------------------------------------------
module pipeline_reg_ctrl_stage(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        trigger_reset_stage1,
    input  wire        valid_in,
    input  wire        flush_in,
    output reg         seq_active_stage2,
    output reg [2:0]   seq_counter_stage2,
    output reg         sequence_done_stage2,
    output reg         valid_stage2,
    output reg         flush_stage2
);

    reg                seq_active_reg;
    reg [2:0]          seq_counter_reg;
    reg                sequence_done_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seq_active_reg      <= 1'b0;
            seq_counter_reg     <= 3'd0;
            sequence_done_reg   <= 1'b0;
            valid_stage2        <= 1'b0;
            flush_stage2        <= 1'b0;
        end else if (flush_in) begin
            seq_active_reg      <= 1'b0;
            seq_counter_reg     <= 3'd0;
            sequence_done_reg   <= 1'b0;
            valid_stage2        <= 1'b0;
            flush_stage2        <= 1'b1;
        end else if (valid_in) begin
            if (trigger_reset_stage1 && !seq_active_reg) begin
                seq_active_reg    <= 1'b1;
                seq_counter_reg   <= 3'd0;
                sequence_done_reg <= 1'b0;
            end else if (seq_active_reg) begin
                seq_counter_reg   <= seq_counter_reg + 3'd1;
                if (seq_counter_reg == 3'd7) begin
                    seq_active_reg    <= 1'b0;
                    sequence_done_reg <= 1'b1;
                end
            end else begin
                sequence_done_reg <= 1'b0;
            end
            valid_stage2        <= 1'b1;
            flush_stage2        <= 1'b0;
        end else begin
            valid_stage2        <= 1'b0;
            flush_stage2        <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seq_active_stage2    <= 1'b0;
            seq_counter_stage2   <= 3'd0;
            sequence_done_stage2 <= 1'b0;
        end else begin
            seq_active_stage2    <= seq_active_reg;
            seq_counter_stage2   <= seq_counter_reg;
            sequence_done_stage2 <= sequence_done_reg;
        end
    end

endmodule

//-----------------------------------------------------------------------------
// Stage 3: Output logic pipeline register
//-----------------------------------------------------------------------------
module pipeline_reg_output_stage(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        seq_active_stage2,
    input  wire [2:0]  seq_counter_stage2,
    input  wire [1:0]  sequence_select_stage1,
    input  wire        sequence_done_stage2,
    input  wire        valid_stage2,
    input  wire        flush_stage2,
    output reg         core_rst_stage3,
    output reg         periph_rst_stage3,
    output reg         mem_rst_stage3,
    output reg         io_rst_stage3,
    output reg         sequence_done_stage3,
    output reg         valid_stage3,
    output reg         flush_stage3
);

    reg         core_rst_comb;
    reg         periph_rst_comb;
    reg         mem_rst_comb;
    reg         io_rst_comb;

    always @(*) begin
        core_rst_comb   = 1'b0;
        periph_rst_comb = 1'b0;
        mem_rst_comb    = 1'b0;
        io_rst_comb     = 1'b0;
        case (sequence_select_stage1)
            2'b00: begin
                if (seq_active_stage2) begin
                    if (seq_counter_stage2 < 3'd2)
                        {core_rst_comb, periph_rst_comb, mem_rst_comb, io_rst_comb} = 4'b1111;
                    else if (seq_counter_stage2 < 3'd4)
                        {core_rst_comb, periph_rst_comb, mem_rst_comb, io_rst_comb} = 4'b0111;
                    else if (seq_counter_stage2 < 3'd6)
                        {core_rst_comb, periph_rst_comb, mem_rst_comb, io_rst_comb} = 4'b0011;
                    else
                        {core_rst_comb, periph_rst_comb, mem_rst_comb, io_rst_comb} = 4'b0000;
                end else begin
                    {core_rst_comb, periph_rst_comb, mem_rst_comb, io_rst_comb} = 4'b0000;
                end
            end
            2'b01: begin
                if (seq_active_stage2) begin
                    if (seq_counter_stage2 < 3'd3)
                        {core_rst_comb, periph_rst_comb, mem_rst_comb, io_rst_comb} = 4'b1111;
                    else if (seq_counter_stage2 < 3'd5)
                        {core_rst_comb, periph_rst_comb, mem_rst_comb, io_rst_comb} = 4'b0101;
                    else
                        {core_rst_comb, periph_rst_comb, mem_rst_comb, io_rst_comb} = 4'b0000;
                end else begin
                    {core_rst_comb, periph_rst_comb, mem_rst_comb, io_rst_comb} = 4'b0000;
                end
            end
            default: begin
                {core_rst_comb, periph_rst_comb, mem_rst_comb, io_rst_comb} = {4{seq_active_stage2}};
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            core_rst_stage3      <= 1'b0;
            periph_rst_stage3    <= 1'b0;
            mem_rst_stage3       <= 1'b0;
            io_rst_stage3        <= 1'b0;
            sequence_done_stage3 <= 1'b0;
            valid_stage3         <= 1'b0;
            flush_stage3         <= 1'b0;
        end else if (flush_stage2) begin
            core_rst_stage3      <= 1'b0;
            periph_rst_stage3    <= 1'b0;
            mem_rst_stage3       <= 1'b0;
            io_rst_stage3        <= 1'b0;
            sequence_done_stage3 <= 1'b0;
            valid_stage3         <= 1'b0;
            flush_stage3         <= 1'b1;
        end else if (valid_stage2) begin
            core_rst_stage3      <= core_rst_comb;
            periph_rst_stage3    <= periph_rst_comb;
            mem_rst_stage3       <= mem_rst_comb;
            io_rst_stage3        <= io_rst_comb;
            sequence_done_stage3 <= sequence_done_stage2;
            valid_stage3         <= 1'b1;
            flush_stage3         <= 1'b0;
        end else begin
            valid_stage3         <= 1'b0;
            flush_stage3         <= 1'b0;
        end
    end

endmodule