//SystemVerilog
module PipelinedNOT(
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream Slave Interface
    input wire [31:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream Master Interface
    output reg [31:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready
);

    // Internal pipeline register
    reg [31:0] data_reg;
    reg valid_reg;
    
    // Ready signal generation - we're ready when downstream is ready or not valid
    assign s_axis_tready = !m_axis_tvalid || m_axis_tready;
    
    // Pipeline logic with handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata <= 32'b0;
            m_axis_tvalid <= 1'b0;
        end else begin
            if (m_axis_tready || !m_axis_tvalid) begin
                if (s_axis_tvalid && s_axis_tready) begin
                    // Process data only when valid handshake occurs
                    m_axis_tdata <= ~s_axis_tdata; // Invert the data
                    m_axis_tvalid <= 1'b1;
                end else if (m_axis_tready) begin
                    // Clear valid when data is consumed and no new data
                    m_axis_tvalid <= 1'b0;
                end
            end
        end
    end

endmodule