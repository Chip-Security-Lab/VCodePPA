//SystemVerilog
module onehot_mux_axi_stream #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    // AXI-Stream Slave Interface
    input  wire [3:0]            s_axis_one_hot_sel,
    input  wire [DATA_WIDTH-1:0] s_axis_tdata0,
    input  wire [DATA_WIDTH-1:0] s_axis_tdata1,
    input  wire [DATA_WIDTH-1:0] s_axis_tdata2,
    input  wire [DATA_WIDTH-1:0] s_axis_tdata3,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    // AXI-Stream Master Interface
    output reg  [DATA_WIDTH-1:0] m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready,
    output reg                   m_axis_tlast
);

    reg s_axis_ready_int;

    assign s_axis_tready = s_axis_ready_int;

    wire [DATA_WIDTH-1:0] mux_data;

    assign mux_data = ({DATA_WIDTH{s_axis_one_hot_sel[0]}} & s_axis_tdata0) |
                      ({DATA_WIDTH{s_axis_one_hot_sel[1]}} & s_axis_tdata1) |
                      ({DATA_WIDTH{s_axis_one_hot_sel[2]}} & s_axis_tdata2) |
                      ({DATA_WIDTH{s_axis_one_hot_sel[3]}} & s_axis_tdata3);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata      <= {DATA_WIDTH{1'b0}};
            m_axis_tvalid     <= 1'b0;
            m_axis_tlast      <= 1'b0;
            s_axis_ready_int  <= 1'b1;
        end else begin
            if (s_axis_tvalid && s_axis_ready_int) begin
                m_axis_tdata  <= (s_axis_one_hot_sel == 4'b0000) ? {DATA_WIDTH{1'b0}} : mux_data;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= 1'b1;
                s_axis_ready_int <= 1'b0;
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid    <= 1'b0;
                m_axis_tlast     <= 1'b0;
                s_axis_ready_int <= 1'b1;
            end
        end
    end

endmodule