//SystemVerilog
module biphase_mark_enc_axi_stream #(
    parameter DATA_WIDTH = 1
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    output reg  [DATA_WIDTH-1:0] m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready
);

    reg phase_reg;                   // 原始phase信号
    reg phase_buf1;                  // 一级缓冲寄存器
    reg phase_buf2;                  // 二级缓冲寄存器

    assign s_axis_tready = m_axis_tready;

    // Phase主寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_reg      <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            phase_reg      <= ~phase_reg;
        end
    end

    // 一级缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_buf1     <= 1'b0;
        end else begin
            phase_buf1     <= phase_reg;
        end
    end

    // 二级缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_buf2     <= 1'b0;
        end else begin
            phase_buf2     <= phase_buf1;
        end
    end

    // 数据与valid输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata  <= {DATA_WIDTH{1'b0}};
            m_axis_tvalid <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                m_axis_tdata  <= s_axis_tdata ? phase_buf2 : ~phase_buf2;
                m_axis_tvalid <= 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule