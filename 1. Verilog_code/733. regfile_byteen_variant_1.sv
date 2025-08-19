//SystemVerilog
module regfile_byteen #(
    parameter WIDTH = 32,
    parameter ADDRW = 4
)(
    input clk,
    input rst,
    input [3:0] byte_en,
    input [ADDRW-1:0] addr,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    // Register bank storage
    reg [WIDTH-1:0] reg_bank [0:(1<<ADDRW)-1];
    
    // Buffer signals to reduce fanout
    reg [3:0] byte_en_buf;
    reg [WIDTH-1:0] din_buf;
    reg [ADDRW-1:0] addr_buf;
    
    // Current value buffer
    reg [WIDTH-1:0] current_buf;
    
    // Byte-specific write enable signals
    wire [3:0] byte_write_en;
    
    // Result of byte selection for writing
    reg [7:0] byte3_data, byte2_data, byte1_data, byte0_data;
    
    // Buffer stage for input signals
    always @(posedge clk) begin
        byte_en_buf <= byte_en;
        din_buf <= din;
        addr_buf <= addr;
    end
    
    // Reset logic and current value reading
    always @(posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < (1<<ADDRW); i = i + 1) begin
                reg_bank[i] <= 0;
            end
        end else begin
            // Read current value from register bank for byte selection
            current_buf <= reg_bank[addr_buf];
        end
    end
    
    // Generate byte write enable signals
    assign byte_write_en = byte_en_buf & {4{~rst}};
    
    // Byte selection logic
    always @(*) begin
        // Byte 3 (MSB)
        byte3_data = byte_write_en[3] ? din_buf[31:24] : current_buf[31:24];
        
        // Byte 2
        byte2_data = byte_write_en[2] ? din_buf[23:16] : current_buf[23:16];
        
        // Byte 1
        byte1_data = byte_write_en[1] ? din_buf[15:8] : current_buf[15:8];
        
        // Byte 0 (LSB)
        byte0_data = byte_write_en[0] ? din_buf[7:0] : current_buf[7:0];
    end
    
    // Write back to register bank
    always @(posedge clk) begin
        if (~rst) begin
            reg_bank[addr_buf] <= {byte3_data, byte2_data, byte1_data, byte0_data};
        end
    end
    
    // Output assignment - direct read from register bank
    assign dout = reg_bank[addr];
    
endmodule