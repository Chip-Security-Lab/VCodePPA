//SystemVerilog
module thermal_noise_rng_axi_stream (
    input  wire           aclk,
    input  wire           aresetn,
    output reg  [15:0]    m_axis_tdata,
    output reg            m_axis_tvalid,
    input  wire           m_axis_tready,
    output reg            m_axis_tlast
);

    // Stage 1 registers: LCG computation
    reg [31:0] noise_gen_x_stage1;
    reg [31:0] noise_gen_y_stage1;

    // Stage 2 registers: LCG adder output
    reg [31:0] noise_gen_x_stage2;
    reg [31:0] noise_gen_y_stage2;

    // Stage 3 registers: Byte extraction
    reg [7:0] noise_gen_x_byte_stage3;
    reg [7:0] noise_gen_y_byte_stage3;

    // Stage 4 registers: Multiplier output (final random_out)
    reg [15:0] random_out_stage4;

    // Pipeline registers for reset propagation
    reg reset_stage1, reset_stage2, reset_stage3, reset_stage4;

    // Output staging register to improve timing
    reg [15:0] tdata_next;
    reg        tvalid_next;
    reg        tlast_next;

    // Stage 1: LCG multiplication
    always @(posedge aclk) begin
        reset_stage1 <= ~aresetn;
        if (~aresetn) begin
            noise_gen_x_stage1 <= 32'h12345678;
            noise_gen_y_stage1 <= 32'h87654321;
        end else if (m_axis_tready || ~m_axis_tvalid) begin
            noise_gen_x_stage1 <= noise_gen_x_stage2;
            noise_gen_y_stage1 <= noise_gen_y_stage2;
        end
    end

    // Stage 2: LCG addition
    always @(posedge aclk) begin
        reset_stage2 <= reset_stage1;
        if (reset_stage1) begin
            noise_gen_x_stage2 <= 32'h12345678;
            noise_gen_y_stage2 <= 32'h87654321;
        end else if (m_axis_tready || ~m_axis_tvalid) begin
            noise_gen_x_stage2 <= (noise_gen_x_stage1 * 32'd1103515245) + 32'd12345;
            noise_gen_y_stage2 <= (noise_gen_y_stage1 * 32'd214013) + 32'd2531011;
        end
    end

    // Stage 3: Extract upper bytes
    always @(posedge aclk) begin
        reset_stage3 <= reset_stage2;
        if (reset_stage2) begin
            noise_gen_x_byte_stage3 <= 8'h00;
            noise_gen_y_byte_stage3 <= 8'h00;
        end else if (m_axis_tready || ~m_axis_tvalid) begin
            noise_gen_x_byte_stage3 <= noise_gen_x_stage2[31:24];
            noise_gen_y_byte_stage3 <= noise_gen_y_stage2[31:24];
        end
    end

    // Stage 4: Multiply bytes to produce output
    always @(posedge aclk) begin
        reset_stage4 <= reset_stage3;
        if (reset_stage3) begin
            random_out_stage4 <= 16'h0000;
        end else if (m_axis_tready || ~m_axis_tvalid) begin
            random_out_stage4 <= noise_gen_x_byte_stage3 * noise_gen_y_byte_stage3;
        end
    end

    // Output AXI-Stream handshake and data register
    always @(posedge aclk) begin
        if (~aresetn) begin
            m_axis_tdata  <= 16'h0000;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else begin
            if (m_axis_tready || ~m_axis_tvalid) begin
                m_axis_tdata  <= random_out_stage4;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= 1'b0; // No frame boundary, always '0'
            end
        end
    end

endmodule