//SystemVerilog
`timescale 1ns / 1ps

module var_dir_shifter_axis #(
    parameter DATA_WIDTH = 16
)(
    input  wire                   aclk,
    input  wire                   aresetn,

    // AXI-Stream slave interface (input)
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [3:0]             s_axis_tuser_shift_amount,
    input  wire                   s_axis_tuser_direction,      // 0:right, 1:left
    input  wire                   s_axis_tuser_fill_value,     // Value to fill vacant bits
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,

    // AXI-Stream master interface (output)
    output reg  [DATA_WIDTH-1:0]  m_axis_tdata,
    output reg                    m_axis_tvalid,
    input  wire                   m_axis_tready,
    output reg                    m_axis_tlast
);

    reg [DATA_WIDTH-1:0]  data_reg;
    reg [3:0]             shift_amt_reg;
    reg                   dir_reg;
    reg                   fill_val_reg;
    reg                   busy;
    reg [3:0]             shift_cnt;

    // Move input registers after combinational logic
    wire                  input_accepted;
    assign input_accepted = s_axis_tvalid && s_axis_tready;

    assign s_axis_tready = !busy;

    // Combinational capture of input signals
    wire [DATA_WIDTH-1:0]  s_axis_tdata_c;
    wire [3:0]             s_axis_tuser_shift_amount_c;
    wire                   s_axis_tuser_direction_c;
    wire                   s_axis_tuser_fill_value_c;

    assign s_axis_tdata_c             = s_axis_tdata;
    assign s_axis_tuser_shift_amount_c= s_axis_tuser_shift_amount;
    assign s_axis_tuser_direction_c   = s_axis_tuser_direction;
    assign s_axis_tuser_fill_value_c  = s_axis_tuser_fill_value;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            data_reg      <= {DATA_WIDTH{1'b0}};
            shift_amt_reg <= 4'd0;
            dir_reg       <= 1'b0;
            fill_val_reg  <= 1'b0;
            busy          <= 1'b0;
            shift_cnt     <= 4'd0;
            m_axis_tdata  <= {DATA_WIDTH{1'b0}};
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else begin
            // Accept input and register after combinational logic
            if (input_accepted) begin
                busy          <= 1'b1;
                shift_cnt     <= 4'd0;
                // Registers now capture the result of the combinational logic
                data_reg      <= s_axis_tdata_c;
                shift_amt_reg <= s_axis_tuser_shift_amount_c;
                dir_reg       <= s_axis_tuser_direction_c;
                fill_val_reg  <= s_axis_tuser_fill_value_c;
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end
            // Data processing
            else if (busy) begin
                if (shift_cnt < shift_amt_reg) begin
                    if (dir_reg) begin
                        data_reg <= {data_reg[DATA_WIDTH-2:0], fill_val_reg};
                    end else begin
                        data_reg <= {fill_val_reg, data_reg[DATA_WIDTH-1:1]};
                    end
                    shift_cnt <= shift_cnt + 1'b1;
                end else begin
                    // Shift done, present output
                    if (!m_axis_tvalid || (m_axis_tvalid && m_axis_tready)) begin
                        m_axis_tdata  <= data_reg;
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast  <= 1'b1;
                        busy          <= 1'b0;
                    end
                end
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end
        end
    end

endmodule