module i2c_timeout_master(
    input clk, rst_n,
    input [6:0] slave_addr,
    input [7:0] write_data,
    input enable,
    output reg [7:0] read_data,
    output reg busy, timeout_error,
    inout scl, sda
);
    localparam TIMEOUT = 16'd1000;
    reg [15:0] timeout_counter;
    reg [3:0] state;
    reg sda_out, scl_out, sda_oe;
    
    assign scl = scl_out ? 1'bz : 1'b0;
    assign sda = sda_oe ? 1'bz : sda_out;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_counter <= 16'd0;
            timeout_error <= 1'b0;
        end else if (state != 4'd0 && enable) begin
            timeout_counter <= timeout_counter + 1'b1;
            if (timeout_counter >= TIMEOUT) begin
                timeout_error <= 1'b1;
                state <= 4'd0;
            end
        end
    end
endmodule