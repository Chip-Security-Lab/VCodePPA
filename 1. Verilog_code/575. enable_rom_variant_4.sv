//SystemVerilog
module enable_rom_axi (
    input wire clk,
    input wire resetn,  // Active low reset signal for AXI protocol
    
    // AXI-Stream Slave interface (for address)
    input wire [3:0] s_axis_tdata,   // Address as input data
    input wire s_axis_tvalid,        // Address valid signal
    output wire s_axis_tready,       // Ready to accept address
    
    // AXI-Stream Master interface (for data output)
    output wire [7:0] m_axis_tdata,  // ROM data output
    output reg m_axis_tvalid,        // Data valid signal
    input wire m_axis_tready,        // Downstream component ready
    output reg m_axis_tlast          // Can be used to indicate end of transfer
);
    
    reg [7:0] rom [0:15];
    reg [7:0] data_reg;
    reg data_valid;
    
    // ROM initialization
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
        rom[8] = 8'h11; rom[9] = 8'h22; rom[10] = 8'h33; rom[11] = 8'h44;
        rom[12] = 8'h55; rom[13] = 8'h66; rom[14] = 8'h77; rom[15] = 8'h88;
    end
    
    // Ready to accept new address when not processing or when output is accepted
    assign s_axis_tready = !data_valid || (m_axis_tvalid && m_axis_tready);
    
    // Connect data register to output
    assign m_axis_tdata = data_reg;
    
    // ROM read logic with AXI handshaking
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            data_reg <= 8'h00;
            data_valid <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
        end else begin
            // Handle completion of data transfer
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                data_valid <= 1'b0;
            end
            
            // Handle new address input
            if (s_axis_tvalid && s_axis_tready) begin
                data_reg <= rom[s_axis_tdata];
                m_axis_tvalid <= 1'b1;
                data_valid <= 1'b1;
                // Set TLAST if address is the last in range (can be customized)
                m_axis_tlast <= (s_axis_tdata == 4'hF) ? 1'b1 : 1'b0;
            end
        end
    end
    
endmodule