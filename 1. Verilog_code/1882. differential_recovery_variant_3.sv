//SystemVerilog
module differential_recovery (
    input  wire        clk,
    input  wire        rst_n,
    
    // Input AXI-Stream interface
    input  wire [15:0] s_axis_tdata,  // Combined pos_signal and neg_signal
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    
    // Output AXI-Stream interface
    output wire [8:0]  m_axis_tdata,  // Recovered signal with sign bit
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready
);
    // IEEE 1364-2005 Verilog standard
    
    // Internal signals
    wire [7:0] pos_signal, neg_signal;
    reg  [8:0] recovered_signal;
    reg        output_valid;
    
    // Extract pos_signal and neg_signal from s_axis_tdata
    assign pos_signal = s_axis_tdata[15:8];
    assign neg_signal = s_axis_tdata[7:0];
    
    // Input ready when output is ready or output not valid
    assign s_axis_tready = m_axis_tready || !output_valid;
    
    // Output data and valid
    assign m_axis_tdata  = recovered_signal;
    assign m_axis_tvalid = output_valid;
    
    // Process data and manage valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_signal <= 9'b0;
            output_valid <= 1'b0;
        end
        else begin
            if (s_axis_tvalid && s_axis_tready) begin
                // Convert differential to single-ended with sign bit
                recovered_signal <= (pos_signal >= neg_signal) ? 
                                   {1'b0, pos_signal - neg_signal} : 
                                   {1'b1, neg_signal - pos_signal};
                output_valid <= 1'b1;
            end
            else if (m_axis_tready && output_valid) begin
                output_valid <= 1'b0;
            end
        end
    end
endmodule