//SystemVerilog
module dual_port_rom (
    input wire clk,
    input wire rst_n,
    
    // Port A - AXI-Stream input interface
    input wire [3:0] s_axis_a_tdata,  // Address for port A
    input wire s_axis_a_tvalid,
    output wire s_axis_a_tready,
    
    // Port A - AXI-Stream output interface
    output wire [7:0] m_axis_a_tdata,  // Data output for port A
    output wire m_axis_a_tvalid,
    input wire m_axis_a_tready,
    
    // Port B - AXI-Stream input interface
    input wire [3:0] s_axis_b_tdata,  // Address for port B
    input wire s_axis_b_tvalid,
    output wire s_axis_b_tready,
    
    // Port B - AXI-Stream output interface
    output wire [7:0] m_axis_b_tdata,  // Data output for port B
    output wire m_axis_b_tvalid,
    input wire m_axis_b_tready
);
    // ROM memory
    reg [7:0] rom [0:15];
    
    // Internal registers for address and data
    reg [3:0] addr_a_reg, addr_b_reg;
    reg [7:0] data_a_reg, data_b_reg;
    
    // Valid flags for output data
    reg a_valid_reg, b_valid_reg;
    
    // Ready signals for input addresses
    assign s_axis_a_tready = m_axis_a_tready || !a_valid_reg;
    assign s_axis_b_tready = m_axis_b_tready || !b_valid_reg;
    
    // Output valid signals
    assign m_axis_a_tvalid = a_valid_reg;
    assign m_axis_b_tvalid = b_valid_reg;
    
    // Output data
    assign m_axis_a_tdata = data_a_reg;
    assign m_axis_b_tdata = data_b_reg;
    
    // Initialize ROM contents
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
        rom[8] = 8'h11; rom[9] = 8'h22; rom[10] = 8'h33; rom[11] = 8'h44;
        rom[12] = 8'h55; rom[13] = 8'h66; rom[14] = 8'h77; rom[15] = 8'h88;
    end
    
    // Port A logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_a_reg <= 4'b0;
            data_a_reg <= 8'b0;
            a_valid_reg <= 1'b0;
        end else begin
            // Handle data transfer on Port A
            if (m_axis_a_tready && a_valid_reg) begin
                a_valid_reg <= 1'b0;
            end
            
            // Accept and process new address on Port A
            if (s_axis_a_tvalid && s_axis_a_tready) begin
                addr_a_reg <= s_axis_a_tdata;
                data_a_reg <= rom[s_axis_a_tdata];
                a_valid_reg <= 1'b1;
            end
        end
    end
    
    // Port B logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_b_reg <= 4'b0;
            data_b_reg <= 8'b0;
            b_valid_reg <= 1'b0;
        end else begin
            // Handle data transfer on Port B
            if (m_axis_b_tready && b_valid_reg) begin
                b_valid_reg <= 1'b0;
            end
            
            // Accept and process new address on Port B
            if (s_axis_b_tvalid && s_axis_b_tready) begin
                addr_b_reg <= s_axis_b_tdata;
                data_b_reg <= rom[s_axis_b_tdata];
                b_valid_reg <= 1'b1;
            end
        end
    end
    
endmodule