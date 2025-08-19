//SystemVerilog
module serial_shifter_axi_stream (
    input wire clk,
    input wire rst_n,
    // AXI-Stream Slave Interface (input)
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [1:0] s_axis_tuser_mode,    // Mode: 00:hold, 01:left, 10:right, 11:load
    input wire [7:0] s_axis_tdata,         // Data input
    input wire s_axis_tuser_serial_in,     // Serial input
    // AXI-Stream Master Interface (output)
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg [7:0] m_axis_tdata
);

// Internal data register
reg [7:0] shift_reg;
reg [7:0] next_shift_reg;

// Ready signal logic
assign s_axis_tready = (!m_axis_tvalid) || (m_axis_tvalid && m_axis_tready);

// Data path and handshake
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 8'h00;
        m_axis_tvalid <= 1'b0;
        m_axis_tdata <= 8'h00;
    end else begin
        // Accept input only when slave valid and ready, and downstream can accept new data
        if (s_axis_tvalid && s_axis_tready) begin
            case (s_axis_tuser_mode)
                2'b00: next_shift_reg = shift_reg;                                   // Hold
                2'b01: next_shift_reg = {shift_reg[6:0], s_axis_tuser_serial_in};    // Shift left
                2'b10: next_shift_reg = {s_axis_tuser_serial_in, shift_reg[7:1]};    // Shift right
                2'b11: next_shift_reg = s_axis_tdata;                                // Load
                default: next_shift_reg = shift_reg;
            endcase
            shift_reg <= next_shift_reg;
            m_axis_tdata <= next_shift_reg;
            m_axis_tvalid <= 1'b1;
        end else if (m_axis_tvalid && m_axis_tready) begin
            // Clear valid after data is accepted by downstream
            m_axis_tvalid <= 1'b0;
        end
    end
end

endmodule