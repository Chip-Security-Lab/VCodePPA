//SystemVerilog
module usb_crc16_gen(
    input wire clk,               // Clock signal
    input wire rst_n,             // Active low reset
    
    // Input interface
    input wire [7:0] data_in,     // Input data
    input wire data_valid,        // Input data valid signal
    output wire data_ready,       // Ready to accept input data
    
    // Output interface
    input wire crc_ready,         // Downstream module ready to accept CRC
    output wire crc_valid,        // CRC output valid
    input wire [15:0] crc_in,     // Input CRC value
    output wire [15:0] crc_out    // Output CRC value
);

    // Internal registers
    reg [15:0] next_crc;
    reg [15:0] crc_result;
    reg crc_valid_r;
    reg data_ready_r;
    
    // Control signals
    wire handshake_in;
    wire handshake_out;
    
    // Handshake logic
    assign handshake_in = data_valid & data_ready;
    assign handshake_out = crc_valid & crc_ready;
    
    // Output assignments
    assign crc_out = crc_result;
    assign crc_valid = crc_valid_r;
    assign data_ready = data_ready_r;
    
    // CRC calculation logic - simplified boolean expressions
    always @(*) begin
        // Simplified expression for next_crc[0]
        // XOR of all data bits and upper 8 bits of crc_in
        next_crc[0] = ^{data_in, crc_in[15:8]};
        
        // Simplified expression for next_crc[1]
        // XOR of all data bits except LSB and upper 7 bits of crc_in
        next_crc[1] = ^{data_in[7:1], crc_in[15:9]};
        
        // Remaining bits shifted from crc_in
        next_crc[15:2] = crc_in[13:0];
    end
    
    // Sequential logic for handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_result <= 16'h0000;
            crc_valid_r <= 1'b0;
            data_ready_r <= 1'b1;
        end
        else begin
            // Update valid signal based on handshake
            crc_valid_r <= handshake_in | (crc_valid_r & ~handshake_out);
            
            // Update CRC result when new data arrives
            if (handshake_in) begin
                crc_result <= next_crc;
            end
            
            // Ready logic - simplified expression
            data_ready_r <= ~crc_valid_r | handshake_out;
        end
    end

endmodule