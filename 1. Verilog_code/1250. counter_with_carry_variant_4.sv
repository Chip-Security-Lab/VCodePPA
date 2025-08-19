//SystemVerilog
module counter_with_carry_axi (
    input  wire        clk,
    input  wire        rst_n,
    // AXI-Stream master interface
    output wire [3:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    output wire        m_axis_tlast,
    input  wire        m_axis_tready
);
    // Internal counter and registers for outputs
    reg [3:0] count;
    reg [3:0] m_axis_tdata_reg;
    reg       m_axis_tvalid_reg;
    reg       m_axis_tlast_reg;
    
    // Output assignments through registered outputs
    assign m_axis_tdata  = m_axis_tdata_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast  = m_axis_tlast_reg;
    
    // Counter logic with ready signal control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'b0000;
        end
        else if (m_axis_tready) begin
            count <= count + 1'b1;
        end
    end
    
    // Register outputs to improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata_reg  <= 4'b0000;
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tlast_reg  <= 1'b0;
        end
        else begin
            m_axis_tdata_reg  <= count;
            m_axis_tvalid_reg <= 1'b1;
            m_axis_tlast_reg  <= (count == 4'b1111);
        end
    end
endmodule