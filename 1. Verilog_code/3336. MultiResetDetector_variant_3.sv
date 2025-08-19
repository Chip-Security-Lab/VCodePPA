//SystemVerilog
module MultiResetDetector_AXIStream (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire        soft_rst,
    // AXI-Stream interface
    output reg  [0:0]  m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg         m_axis_tlast
);
    reg reset_detected_reg;
    reg reset_detected_reg_d;
    wire reset_event;

    // Detect reset: high for one cycle when either aresetn or soft_rst is deasserted
    always @(posedge aclk) begin
        if (!aresetn || !soft_rst) begin
            reset_detected_reg <= 1'b1;
        end else begin
            reset_detected_reg <= 1'b0;
        end
    end

    // Edge detector for reset_detected_reg
    always @(posedge aclk) begin
        if (!aresetn)
            reset_detected_reg_d <= 1'b0;
        else
            reset_detected_reg_d <= reset_detected_reg;
    end

    assign reset_event = reset_detected_reg & ~reset_detected_reg_d;

    // AXI-Stream handshake logic
    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else if (reset_event) begin
            m_axis_tvalid <= 1'b1;
            m_axis_tdata  <= 1'b1;
            m_axis_tlast  <= 1'b1;
        end else if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end
    end

endmodule