//SystemVerilog
module mwc_random_gen_pipeline_valid_ready (
    input  wire        clock,
    input  wire        reset,
    input  wire        valid_in,
    output wire        ready_in,
    input  wire        start,
    output wire [31:0] random_data,
    output wire        valid_out,
    input  wire        ready_out
);

    // Stage 1: Latch seeds and valid with valid-ready handshake
    reg  [31:0] m_w_stage1, m_z_stage1;
    reg         valid_stage1;
    wire        stage1_ready;
    wire        stage1_fire = valid_in && stage1_ready;

    always @(posedge clock) begin
        if (reset) begin
            m_w_stage1   <= 32'h12345678;
            m_z_stage1   <= 32'h87654321;
            valid_stage1 <= 1'b0;
        end else if (stage1_fire) begin
            m_w_stage1   <= m_w_stage1;
            m_z_stage1   <= m_z_stage1;
            valid_stage1 <= 1'b1;
        end else if (stage2_ready && valid_stage1) begin
            m_w_stage1   <= m_w_next;
            m_z_stage1   <= m_z_next;
            valid_stage1 <= 1'b1;
        end else if (stage2_ready) begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Calculate lower 16 bits and shift with valid-ready handshake
    wire [15:0] m_w_stage1_low  = m_w_stage1[15:0];
    wire [15:0] m_z_stage1_low  = m_z_stage1[15:0];
    wire [15:0] m_w_stage1_high = m_w_stage1[31:16];
    wire [15:0] m_z_stage1_high = m_z_stage1[31:16];

    reg  [31:0] m_w_mult_stage2, m_z_mult_stage2;
    reg  [15:0] m_w_high_stage2, m_z_high_stage2;
    reg         valid_stage2;
    wire        stage2_ready;
    wire        stage2_fire = valid_stage1 && stage2_ready;

    always @(posedge clock) begin
        if (reset) begin
            m_w_mult_stage2  <= 32'b0;
            m_z_mult_stage2  <= 32'b0;
            m_w_high_stage2  <= 16'b0;
            m_z_high_stage2  <= 16'b0;
            valid_stage2     <= 1'b0;
        end else if (stage2_fire) begin
            m_w_mult_stage2  <= 18000 * m_w_stage1_low;
            m_z_mult_stage2  <= 36969 * m_z_stage1_low;
            m_w_high_stage2  <= m_w_stage1_high;
            m_z_high_stage2  <= m_z_stage1_high;
            valid_stage2     <= 1'b1;
        end else if (stage3_ready) begin
            valid_stage2     <= 1'b0;
        end
    end

    // Stage 3: Add shifted high part with valid-ready handshake
    reg [31:0] m_w_next, m_z_next;
    reg        valid_stage3;
    wire       stage3_ready;
    wire       stage3_fire = valid_stage2 && stage3_ready;

    always @(posedge clock) begin
        if (reset) begin
            m_w_next     <= 32'b0;
            m_z_next     <= 32'b0;
            valid_stage3 <= 1'b0;
        end else if (stage3_fire) begin
            m_w_next     <= m_w_mult_stage2 + m_w_high_stage2;
            m_z_next     <= m_z_mult_stage2 + m_z_high_stage2;
            valid_stage3 <= 1'b1;
        end else if (stage4_ready) begin
            valid_stage3 <= 1'b0;
        end
    end

    // Stage 4: Output random data with valid-ready handshake
    reg [31:0] random_data_stage4;
    reg        valid_stage4;
    wire       stage4_ready;
    wire       stage4_fire = valid_stage3 && stage4_ready;

    always @(posedge clock) begin
        if (reset) begin
            random_data_stage4 <= 32'b0;
            valid_stage4       <= 1'b0;
        end else if (stage4_fire) begin
            random_data_stage4 <= (m_z_next << 16) + m_w_next;
            valid_stage4       <= 1'b1;
        end else if (ready_out) begin
            valid_stage4       <= 1'b0;
        end
    end

    // Ready signal generation for each stage
    assign stage4_ready = ~valid_stage4 || ready_out;
    assign stage3_ready = ~valid_stage3 || stage4_fire;
    assign stage2_ready = ~valid_stage2 || stage3_fire;
    assign stage1_ready = ~valid_stage1 || stage2_fire;

    // Top-level interface signals
    assign ready_in     = stage1_ready && start;
    assign random_data  = random_data_stage4;
    assign valid_out    = valid_stage4;

endmodule