//SystemVerilog - IEEE 1364-2005 Standard
module sd_cmd_encoder (
    input wire clk,
    input wire aresetn,  // AXI Reset signal (active low)
    
    // AXI-Stream slave interface
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    input wire [37:0] s_axis_tdata,  // [37:32]=cmd, [31:0]=arg
    
    // AXI-Stream master interface
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg m_axis_tdata,  // Single bit output
    output reg m_axis_tlast
);
    // Internal registers
    reg [47:0] shift_reg;
    reg [5:0] cnt;
    reg transfer_active;
    
    // Extract cmd and arg from input data
    wire [5:0] cmd = s_axis_tdata[37:32];
    wire [31:0] arg = s_axis_tdata[31:0];
    
    // Create combined packet in the shift register
    wire [47:0] packet = {1'b0, cmd, arg, 7'h01};
    
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            shift_reg <= 48'h0;
            cnt <= 6'd0;
            s_axis_tready <= 1'b1;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 1'b0;
            m_axis_tlast <= 1'b0;
            transfer_active <= 1'b0;
        end
        else begin
            // Handle slave interface
            if (s_axis_tvalid && s_axis_tready) begin
                // Accept new command
                shift_reg <= packet;
                cnt <= 6'd47;
                s_axis_tready <= 1'b0;  // Stop accepting new data
                m_axis_tvalid <= 1'b1;  // Start transmitting
                transfer_active <= 1'b1;
            end
            
            // Handle master interface
            if (m_axis_tvalid && m_axis_tready) begin
                if (|cnt) begin  // Still bits to send
                    // Shift out next bit
                    m_axis_tdata <= shift_reg[cnt];
                    cnt <= cnt - 1'b1;
                    
                    // Set TLAST signal when we reach the last bit
                    m_axis_tlast <= (cnt == 6'd1);
                end
                else if (transfer_active) begin
                    // End of transmission
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                    s_axis_tready <= 1'b1;  // Ready for next command
                    transfer_active <= 1'b0;
                end
            end
        end
    end
endmodule