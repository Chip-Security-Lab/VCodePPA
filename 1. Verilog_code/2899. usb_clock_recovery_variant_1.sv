//SystemVerilog
module usb_clock_recovery (
    // AXI-Stream interface
    input  wire        s_axis_aclk,     // Clock
    input  wire        s_axis_aresetn,  // Active-low reset
    input  wire        s_axis_tvalid,   // Input data valid
    output wire        s_axis_tready,   // Ready to accept data
    input  wire [15:0] s_axis_tdata,    // Input data (dp_in at bit 0, dm_in at bit 8)
    
    // AXI-Stream output interface
    output wire        m_axis_tvalid,   // Output data valid 
    input  wire        m_axis_tready,   // Downstream is ready
    output wire [15:0] m_axis_tdata,    // Output data (recovered_clk at bit 0, bit_locked at bit 8)
    output wire        m_axis_tlast     // End of packet indicator
);

    // Internal signals
    reg recovered_clk_reg;
    reg bit_locked_reg;
    reg [2:0] edge_detect;
    reg [7:0] edge_counter;
    reg [7:0] period_count;
    
    // Extract input signals from AXI-Stream
    wire dp_in = s_axis_tvalid ? s_axis_tdata[0] : 1'b0;
    wire dm_in = s_axis_tvalid ? s_axis_tdata[8] : 1'b0;
    
    // Always ready to accept data
    assign s_axis_tready = 1'b1;
    
    // Main processing logic
    always @(posedge s_axis_aclk or negedge s_axis_aresetn) begin
        if (!s_axis_aresetn) begin
            edge_detect <= 3'b000;
            edge_counter <= 8'd0;
            period_count <= 8'd0;
            recovered_clk_reg <= 1'b0;
            bit_locked_reg <= 1'b0;
        end else if (s_axis_tvalid) begin
            edge_detect <= {edge_detect[1:0], dp_in ^ dm_in};
            
            if (edge_detect[2:1] == 2'b01) begin  // Rising edge
                if (period_count > 8'd10) begin
                    bit_locked_reg <= 1'b1;
                    period_count <= 8'd0;
                    recovered_clk_reg <= 1'b1;
                end else begin
                    period_count <= period_count + 1'b1;
                end
            end else begin
                period_count <= period_count + 1'b1;
                if (period_count >= 8'd24) begin
                    recovered_clk_reg <= 1'b0;
                    period_count <= 8'd0;
                end
            end
        end
    end
    
    // AXI-Stream output assignments
    assign m_axis_tvalid = s_axis_tvalid;
    assign m_axis_tdata = {8'b0, bit_locked_reg, 7'b0, recovered_clk_reg};
    assign m_axis_tlast = 1'b0;  // No packet framing in this design
    
endmodule