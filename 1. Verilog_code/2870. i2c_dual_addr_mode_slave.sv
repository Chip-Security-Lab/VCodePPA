module i2c_dual_addr_mode_slave(
    input wire clk, rst_n,
    input wire [6:0] addr_7bit,
    input wire [9:0] addr_10bit,
    input wire addr_mode, // 0=7bit, 1=10bit
    output reg [7:0] data_rx,
    output reg data_valid,
    inout wire sda, scl
);
    reg [2:0] state;
    reg [9:0] addr_buffer;
    reg [7:0] data_buffer;
    reg [3:0] bit_count;
    reg sda_out, sda_oe;
    
    assign sda = sda_oe ? 1'bz : sda_out;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 3'b000;
            data_valid <= 1'b0;
        end else case (state)
            3'b001: if (bit_count == 4'd8) begin
                if (!addr_mode && addr_buffer[7:1] == addr_7bit)
                    state <= 3'b010;
                else if (addr_mode && addr_buffer[7:1] == 10'b1111000000)
                    state <= 3'b100; // 10-bit addr first byte
            end
        endcase
    end
endmodule