module i2c_master_basic(
    input clk, rst_n,
    input [7:0] tx_data,
    input start_trans,
    output reg [7:0] rx_data,
    output reg busy,
    inout sda, scl
);
    reg [2:0] state;
    reg sda_out, scl_out, sda_oen;
    reg [3:0] bit_cnt;
    
    assign scl = scl_out ? 1'bz : 1'b0;
    assign sda = sda_oen ? 1'bz : sda_out;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 3'b000; busy <= 0; sda_oen <= 1;
        end else case (state)
            3'b000: if (start_trans) begin state <= 3'b001; busy <= 1; end
            3'b001: begin sda_oen <= 0; state <= 3'b010; end // START
            3'b010: begin bit_cnt <= 4'd7; state <= 3'b011; end // ADDR+W/R
            // Additional states implementation
        endcase
    end
endmodule