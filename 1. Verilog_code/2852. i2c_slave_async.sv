module i2c_slave_async(
    input rst_n,
    input [6:0] device_addr,
    output reg [7:0] data_received,
    output wire data_valid,
    inout sda, scl
);
    reg [6:0] addr_buffer;
    reg [7:0] data_buffer;
    reg [3:0] bit_count;
    reg addr_match, receiving;

    wire scl_falling = (scl_prev && !scl);
    wire scl_rising = (!scl_prev && scl);
    reg scl_prev, sda_prev;
    
    // Detect START/STOP conditions
    wire start_condition = (sda_prev && !sda && scl);
    wire stop_condition = (!sda_prev && sda && scl);
    
    always @(negedge scl or negedge rst_n) begin
        if (!rst_n) receiving <= 0;
        else if (addr_match && bit_count == 4'd8)
            data_buffer[7-bit_count] <= sda;
    end
endmodule
