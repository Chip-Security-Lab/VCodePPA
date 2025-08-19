module i2c_error_slave #(
    parameter ADDR_WIDTH = 7
)(
    input rst_n,
    input [ADDR_WIDTH-1:0] device_addr,
    output reg [7:0] rx_data,
    output reg framing_error, overrun_error, addr_error,
    inout scl, sda
);
    reg [2:0] state;
    reg [7:0] data_buf;
    reg [3:0] bit_count;
    reg data_valid, prev_sda, prev_scl;
    
    wire start = prev_sda & ~sda & scl;
    wire stop = ~prev_sda & sda & scl;
    
    always @(posedge scl or negedge rst_n) begin
        if (!rst_n) begin
            state <= 3'b0; framing_error <= 1'b0;
        end else if (state == 3'b010 && bit_count > 4'd8)
            framing_error <= 1'b1;
    end
endmodule