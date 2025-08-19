module CAN_Transmitter_Config #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5,
    parameter BIT_TIME = 100
)(
    input clk,
    input rst_n,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] data_in,
    input transmit_en,
    output reg can_tx,
    output reg tx_complete
);
    localparam TOTAL_BITS = ADDR_WIDTH + DATA_WIDTH + 3;
    reg [7:0] bit_timer;
    reg [7:0] bit_counter;
    reg [TOTAL_BITS-1:0] shift_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_timer <= 0;
            bit_counter <= 0;
            shift_reg <= 0;
            tx_complete <= 0;
        end else begin
            if (bit_timer < BIT_TIME-1) begin
                bit_timer <= bit_timer + 1;
            end else begin
                bit_timer <= 0;
                if (bit_counter < TOTAL_BITS) begin
                    can_tx <= shift_reg[TOTAL_BITS-1];
                    shift_reg <= {shift_reg[TOTAL_BITS-2:0], 1'b0};
                    bit_counter <= bit_counter + 1;
                end else begin
                    tx_complete <= 1;
                    bit_counter <= 0;
                    if (transmit_en) begin
                        shift_reg <= {3'b101, addr, data_in};
                    end
                end
            end
        end
    end
endmodule