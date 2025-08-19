//SystemVerilog
`timescale 1ns / 1ps

module var_width_shifter_axi_stream #
(
    parameter DATA_WIDTH = 32
)
(
    input wire clk,
    input wire rst,

    // AXI-Stream Slave (Input) Interface
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire [1:0]            s_axis_tuser_width_sel,   // width selector in tuser
    input  wire [4:0]            s_axis_tuser_shift_amt,   // shift amount in tuser
    input  wire                  s_axis_tuser_shift_left,  // shift direction in tuser
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,

    // AXI-Stream Master (Output) Interface
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire                  m_axis_tvalid,
    input  wire                  m_axis_tready,
    output wire                  m_axis_tlast
);

    // Internal handshake signal
    wire handshake;
    assign handshake = s_axis_tvalid & s_axis_tready;

    // Data pipeline registers moved before combinational logic for retiming
    reg [DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [1:0]            width_sel_reg;
    reg [4:0]            shift_amt_reg;
    reg                  shift_left_reg;
    reg                  valid_reg;
    reg                  last_reg;

    // Always ready to accept input if pipeline is not full or output is accepted
    assign s_axis_tready = (~valid_reg) | (m_axis_tready);

    // Register input at handshake
    always @(posedge clk) begin
        if (rst) begin
            s_axis_tdata_reg <= {DATA_WIDTH{1'b0}};
            width_sel_reg    <= 2'b00;
            shift_amt_reg    <= 5'b0;
            shift_left_reg   <= 1'b0;
            valid_reg        <= 1'b0;
            last_reg         <= 1'b0;
        end else begin
            if (handshake) begin
                s_axis_tdata_reg <= s_axis_tdata;
                width_sel_reg    <= s_axis_tuser_width_sel;
                shift_amt_reg    <= s_axis_tuser_shift_amt;
                shift_left_reg   <= s_axis_tuser_shift_left;
                valid_reg        <= 1'b1;
                last_reg         <= 1'b1;
            end else if (m_axis_tready && valid_reg) begin
                valid_reg        <= 1'b0;
                last_reg         <= 1'b0;
            end
        end
    end

    // Data path logic after pipeline register
    reg [DATA_WIDTH-1:0] masked_data_pipe;
    always @(*) begin
        case (width_sel_reg)
            2'b00: masked_data_pipe = {24'b0, s_axis_tdata_reg[7:0]};
            2'b01: masked_data_pipe = {16'b0, s_axis_tdata_reg[15:0]};
            2'b10: masked_data_pipe = {8'b0,  s_axis_tdata_reg[23:0]};
            default: masked_data_pipe = s_axis_tdata_reg;
        endcase
    end

    reg [DATA_WIDTH-1:0] shifted_data_pipe;
    always @(*) begin
        if (shift_left_reg)
            shifted_data_pipe = masked_data_pipe << shift_amt_reg;
        else
            shifted_data_pipe = masked_data_pipe >> shift_amt_reg;
    end

    assign m_axis_tdata  = shifted_data_pipe;
    assign m_axis_tvalid = valid_reg;
    assign m_axis_tlast  = last_reg;

endmodule