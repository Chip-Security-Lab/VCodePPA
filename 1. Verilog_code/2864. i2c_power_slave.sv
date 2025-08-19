module i2c_power_slave(
    input rst_b,
    input power_mode,
    input [6:0] dev_addr,
    output reg [7:0] data_out,
    output reg wake_up,
    inout sda, scl
);
    reg [2:0] state;
    reg [7:0] shift_reg;
    reg [3:0] bit_counter;
    reg sda_prev, scl_prev, addr_match;
    
    wire start_condition = scl && sda_prev && !sda;
    
    always @(posedge scl or negedge rst_b) begin
        if (!rst_b) begin
            state <= 3'b000; wake_up <= 1'b0;
        end else if (!power_mode && start_condition) begin
            wake_up <= 1'b1;
        end else if (state == 3'b001 && bit_counter == 4'd7) begin
            addr_match <= (shift_reg[7:1] == dev_addr);
        end
    end
endmodule