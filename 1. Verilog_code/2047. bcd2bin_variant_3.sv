//SystemVerilog
`timescale 1ns / 1ps

module bcd2bin_axis #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  aclk,
    input  wire                  aresetn,

    // AXI-Stream slave interface (input)
    input  wire [11:0]           s_axis_tdata,  // 3 BCD digits
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    input  wire                  s_axis_tlast,

    // AXI-Stream master interface (output)
    output reg  [9:0]            m_axis_tdata,  // Binary value up to 999
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready,
    output reg                   m_axis_tlast
);

    // Internal handshake
    reg                          input_accepted;

    assign s_axis_tready = ~input_accepted;

    always @(posedge aclk) begin
        if (!aresetn) begin
            input_accepted <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            input_accepted <= 1'b1;
        end else if (m_axis_tvalid && m_axis_tready) begin
            input_accepted <= 1'b0;
        end
    end

    // Register input BCD and tlast
    reg [11:0] bcd_input_reg;
    reg        tlast_input_reg;

    always @(posedge aclk) begin
        if (!aresetn) begin
            bcd_input_reg  <= 12'd0;
            tlast_input_reg <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            bcd_input_reg  <= s_axis_tdata;
            tlast_input_reg <= s_axis_tlast;
        end
    end

    // Optimized BCD to Binary conversion
    wire [3:0] hundreds_digit;
    wire [3:0] tens_digit;
    wire [3:0] ones_digit;
    wire [9:0] binary_value;

    assign hundreds_digit = bcd_input_reg[11:8];
    assign tens_digit     = bcd_input_reg[7:4];
    assign ones_digit     = bcd_input_reg[3:0];

    // Efficient multiplication using shift-and-add for BCD * 10 and BCD * 100
    wire [9:0] hundreds_mul;
    wire [7:0] tens_mul;

    // hundreds * 100 = hundreds * (64 + 32 + 4)
    assign hundreds_mul = (hundreds_digit << 6) + (hundreds_digit << 5) + (hundreds_digit << 2);
    // tens * 10 = (tens << 3) + (tens << 1)
    assign tens_mul = (tens_digit << 3) + (tens_digit << 1);
    assign binary_value = hundreds_mul + tens_mul + ones_digit;

    // Output logic
    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_tdata  <= 10'd0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else if (input_accepted && !m_axis_tvalid) begin
            m_axis_tdata  <= binary_value;
            m_axis_tvalid <= 1'b1;
            m_axis_tlast  <= tlast_input_reg;
        end else if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end
    end

endmodule