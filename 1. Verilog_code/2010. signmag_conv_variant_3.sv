//SystemVerilog
// Top-level module for sign-magnitude conversion with AXI-Stream interface

module signmag_conv_axis (
    input               clk,
    input               rst_n,
    // AXI-Stream Slave (input) interface
    input       [15:0]  s_axis_tdata,
    input               s_axis_tvalid,
    output reg          s_axis_tready,
    // AXI-Stream Master (output) interface
    output reg  [15:0]  m_axis_tdata,
    output reg          m_axis_tvalid,
    input               m_axis_tready
);

    // Stage 1: Extract sign and raw magnitude
    reg                sign_stage1;
    reg  [14:0]        mag_raw_stage1;
    reg                valid_stage1;

    // Pipeline registers stage 1 -> stage 2
    reg                sign_stage2;
    reg  [14:0]        mag_raw_stage2;
    reg                valid_stage2;

    // Stage 2: Magnitude conversion
    reg  [14:0]        mag_conv_stage2;

    // Pipeline registers stage 2 -> stage 3
    reg                sign_stage3;
    reg  [14:0]        mag_conv_stage3;
    reg                valid_stage3;

    // Stage 3: Output combination
    wire [15:0]        out_stage3;

    // AXI-Stream handshake for input
    wire               input_ready;
    assign input_ready = s_axis_tready && s_axis_tvalid;

    // AXI-Stream handshake for output
    wire               output_ready;
    assign output_ready = m_axis_tvalid && m_axis_tready;

    // Input ready generation: accept new data if stage 1 is ready
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            s_axis_tready <= 1'b1;
        else if (input_ready)
            s_axis_tready <= 1'b0;
        else if (!valid_stage1)
            s_axis_tready <= 1'b1;
    end

    // Stage 1: Latch input when handshaked
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_stage1    <= 1'b0;
            mag_raw_stage1 <= 15'd0;
            valid_stage1   <= 1'b0;
        end else if (input_ready) begin
            sign_stage1    <= s_axis_tdata[15];
            mag_raw_stage1 <= s_axis_tdata[14:0];
            valid_stage1   <= 1'b1;
        end else if (output_ready && !valid_stage2 && !valid_stage3) begin
            // Pipeline empty, clear valid
            valid_stage1   <= 1'b0;
        end
    end

    // Stage 2: Pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_stage2    <= 1'b0;
            mag_raw_stage2 <= 15'd0;
            valid_stage2   <= 1'b0;
        end else if (valid_stage1 && (!valid_stage2 || (output_ready && valid_stage3))) begin
            sign_stage2    <= sign_stage1;
            mag_raw_stage2 <= mag_raw_stage1;
            valid_stage2   <= 1'b1;
        end else if (output_ready && !valid_stage3) begin
            valid_stage2   <= 1'b0;
        end
    end

    // Stage 2: Magnitude conversion (sign-magnitude)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mag_conv_stage2 <= 15'd0;
        else if (valid_stage2)
            mag_conv_stage2 <= mag_raw_stage2 ^ {15{sign_stage2}};
    end

    // Stage 3: Pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_stage3     <= 1'b0;
            mag_conv_stage3 <= 15'd0;
            valid_stage3    <= 1'b0;
        end else if (valid_stage2 && (!valid_stage3 || output_ready)) begin
            sign_stage3     <= sign_stage2;
            mag_conv_stage3 <= mag_conv_stage2;
            valid_stage3    <= 1'b1;
        end else if (output_ready) begin
            valid_stage3    <= 1'b0;
        end
    end

    // Output combination
    assign out_stage3 = {sign_stage3, mag_conv_stage3};

    // Output AXI-Stream signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata  <= 16'd0;
            m_axis_tvalid <= 1'b0;
        end else begin
            if (valid_stage3) begin
                m_axis_tdata  <= out_stage3;
                m_axis_tvalid <= 1'b1;
            end else if (output_ready) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule