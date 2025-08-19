//SystemVerilog
module hierarchical_reset_dist (
    // Clock input (required for AXI-Stream)
    input wire axi_clk,
    
    // AXI-Stream input interface
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [9:0] s_axis_tdata, // global_rst(1-bit) + domain_select(2-bits) + padding(7-bits)
    
    // AXI-Stream output interface
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire [7:0] m_axis_tdata  // subsystem_rst
);

    // Internal signals
    reg [7:0] subsystem_rst_reg;
    reg global_rst_reg;
    reg [1:0] domain_select_reg;
    reg [3:0] domain_rst;
    
    // Extract input signals and register them to break critical path
    always @(posedge axi_clk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            global_rst_reg <= s_axis_tdata[9];
            domain_select_reg <= s_axis_tdata[8:7];
        end
    end
    
    // Always ready to receive data
    assign s_axis_tready = 1'b1;
    
    // Domain reset generation logic - simplified and balanced paths
    always @(posedge axi_clk) begin
        // Common domains - always get global reset
        domain_rst[0] <= global_rst_reg;
        domain_rst[1] <= global_rst_reg;
        
        // Selective domains - conditioned on domain_select bits
        domain_rst[2] <= global_rst_reg & domain_select_reg[0];
        domain_rst[3] <= global_rst_reg & domain_select_reg[1];
    end
    
    // Subsystem reset logic - parallel assignments reduce path depth
    always @(posedge axi_clk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            // Use direct bit duplication for each domain
            // Each pair processes independently in parallel
            subsystem_rst_reg[0] <= domain_rst[0];
            subsystem_rst_reg[1] <= domain_rst[0];
            
            subsystem_rst_reg[2] <= domain_rst[1];
            subsystem_rst_reg[3] <= domain_rst[1];
            
            subsystem_rst_reg[4] <= domain_rst[2];
            subsystem_rst_reg[5] <= domain_rst[2];
            
            subsystem_rst_reg[6] <= domain_rst[3];
            subsystem_rst_reg[7] <= domain_rst[3];
        end
    end
    
    // Output AXI-Stream interface - registered for better timing closure
    reg m_axis_tvalid_reg;
    
    always @(posedge axi_clk) begin
        m_axis_tvalid_reg <= s_axis_tvalid;
    end
    
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tdata = subsystem_rst_reg;
    
endmodule