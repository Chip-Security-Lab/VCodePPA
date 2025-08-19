//SystemVerilog
// Top-level module: EyeSampling_AXIStream
// Function: Performs eye sampling with AXI-Stream output interface

module EyeSampling_AXIStream #(
    parameter SAMPLE_OFFSET = 3
) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         serial_in,
    output wire [7:0]   m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast
);

    wire [7:0]          shift_reg_out;
    wire                recovered_bit;

    // Shift Register Submodule
    ShiftRegister_8bit u_shift_register (
        .clk        (clk),
        .rst_n      (rst_n),
        .serial_in  (serial_in),
        .shift_reg  (shift_reg_out)
    );

    // Eye Sampler Submodule
    EyeSampler #(
        .SAMPLE_OFFSET (SAMPLE_OFFSET)
    ) u_eye_sampler (
        .shift_reg     (shift_reg_out),
        .recovered_bit (recovered_bit)
    );

    // AXI-Stream Output Logic
    reg         tvalid_reg;
    reg [7:0]   tdata_reg;
    reg         tlast_reg;
    reg [2:0]   sample_cnt;

    assign m_axis_tdata  = tdata_reg;
    assign m_axis_tvalid = tvalid_reg;
    assign m_axis_tlast  = tlast_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tvalid_reg  <= 1'b0;
            tdata_reg   <= 8'b0;
            tlast_reg   <= 1'b0;
            sample_cnt  <= 3'd0;
        end else begin
            // Shift register always updates, tvalid driven by sample_cnt
            if (m_axis_tready || !tvalid_reg) begin
                tdata_reg   <= shift_reg_out;
                tvalid_reg  <= 1'b1;
                if (sample_cnt == 3'd7) begin
                    tlast_reg   <= 1'b1;
                    sample_cnt  <= 3'd0;
                end else begin
                    tlast_reg   <= 1'b0;
                    sample_cnt  <= sample_cnt + 3'd1;
                end
            end else begin
                // Hold tvalid high until tready is asserted
                tvalid_reg  <= tvalid_reg;
                tdata_reg   <= tdata_reg;
                tlast_reg   <= tlast_reg;
                sample_cnt  <= sample_cnt;
            end
        end
    end

endmodule

// --------------------------------------------------------------------
// ShiftRegister_8bit
// Function: 8-bit serial-in, parallel-out shift register with async reset

module ShiftRegister_8bit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       serial_in,
    output reg [7:0]  shift_reg
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= 8'b0;
        else
            shift_reg <= {shift_reg[6:0], serial_in};
    end
endmodule

// --------------------------------------------------------------------
// EyeSampler
// Function: Selects a bit from the shift register at SAMPLE_OFFSET

module EyeSampler #(
    parameter SAMPLE_OFFSET = 3
) (
    input  wire [7:0] shift_reg,
    output reg        recovered_bit
);
    always @(*) begin
        recovered_bit = shift_reg[SAMPLE_OFFSET];
    end
endmodule