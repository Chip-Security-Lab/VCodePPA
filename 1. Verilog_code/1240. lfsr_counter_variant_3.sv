//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module lfsr_counter (
    input  wire        clk,
    input  wire        rst,
    // AXI-Stream Slave Interface
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    // AXI-Stream Master Interface
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tlast
);
    // Internal registers
    reg [7:0] lfsr;
    reg       output_valid;
    reg [3:0] counter;
    wire      feedback;
    
    // LFSR feedback computation optimized for timing
    assign feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];
    
    // Always ready to receive data (can be customized based on requirements)
    assign s_axis_tready = 1'b1;
    
    // Output valid signal control
    assign m_axis_tvalid = output_valid;
    
    // Connect LFSR to output data bus
    assign m_axis_tdata = lfsr;
    
    // Assert TLAST signal every 16 transfers
    assign m_axis_tlast = (counter == 4'hF);
    
    // LFSR update logic
    always @(posedge clk) begin
        if (rst) begin
            lfsr <= 8'h01;         // Non-zero seed value
            output_valid <= 1'b0;  // Start with output invalid
            counter <= 4'h0;       // Reset counter
        end
        else begin
            // Update LFSR when master is ready to accept data or output not valid
            if (m_axis_tready || !output_valid) begin
                lfsr <= {lfsr[6:0], feedback};
                output_valid <= 1'b1;  // Signal valid output
                
                // Update counter when transferring data
                if (output_valid && m_axis_tready)
                    counter <= counter + 4'h1;
            end
        end
    end
endmodule