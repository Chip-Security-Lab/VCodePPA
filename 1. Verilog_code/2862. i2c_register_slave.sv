module i2c_register_slave(
    input wire reset_n,
    input wire [6:0] device_address,
    output wire [7:0] reg_data_out,
    inout wire sda, scl
);
    reg [7:0] registers [0:15];
    reg [3:0] reg_addr;
    reg [7:0] rx_shift_reg;
    reg [3:0] bit_cnt;
    reg [2:0] state;
    reg addr_matched, addr_phase, reg_addr_received;
    
    assign reg_data_out = registers[reg_addr];
    
    always @(posedge scl or negedge reset_n) begin
        if (!reset_n) begin
            state <= 3'b000;
        end else if (state == 3'b010 && bit_cnt == 4'd8) begin
            reg_addr <= rx_shift_reg[3:0];
            reg_addr_received <= 1'b1;
        end
    end
endmodule