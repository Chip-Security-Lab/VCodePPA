//SystemVerilog
module hierarchical_reset_dist (
    // Clock input
    input  wire        aclk,
    
    // AXI-Stream input interface
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [9:0]  s_axis_tdata,
    input  wire        s_axis_tlast,
    
    // AXI-Stream output interface
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tlast
);

    // Optimized data flow control
    reg        data_valid_reg;
    reg [7:0]  subsystem_rst_reg;
    reg        tlast_reg;
    
    // Direct signal extraction
    wire global_rst = s_axis_tdata[0];
    wire [1:0] domain_select = s_axis_tdata[2:1];
    
    // Optimized domain reset calculation
    wire [3:0] domain_rst;
    assign domain_rst[1:0] = {2{global_rst}}; // Domains 0 and 1 use global reset directly
    assign domain_rst[3:2] = {global_rst & domain_select[1], global_rst & domain_select[0]};
    
    // Simplified ready logic
    assign s_axis_tready = ~data_valid_reg | m_axis_tready;
    
    // Output assignments
    assign m_axis_tvalid = data_valid_reg;
    assign m_axis_tdata = subsystem_rst_reg;
    assign m_axis_tlast = tlast_reg;
    
    // Optimized data transfer process with reduced logic
    always @(posedge aclk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            // Efficient subsystem reset generation using concatenation
            // Each domain controls 2 bits in the output
            subsystem_rst_reg <= {
                {2{domain_rst[3]}},  // Bits 7:6
                {2{domain_rst[2]}},  // Bits 5:4
                {2{domain_rst[1]}},  // Bits 3:2
                {2{domain_rst[0]}}   // Bits 1:0
            };
            
            tlast_reg <= s_axis_tlast;
            data_valid_reg <= 1'b1;
        end 
        else if (m_axis_tready && data_valid_reg) begin
            data_valid_reg <= 1'b0;
        end
    end

endmodule