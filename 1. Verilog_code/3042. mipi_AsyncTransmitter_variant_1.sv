//SystemVerilog
module MIPI_AsyncTransmitter #(
    parameter DELAY_CYCLES = 3
)(
    input wire tx_req,
    input wire [7:0] tx_payload,
    output wire tx_ready,
    output reg lp_mode,
    output reg hs_mode,
    output reg [7:0] hs_data
);
    reg [1:0] delay_counter;
    wire tx_active;
    
    assign tx_ready = (delay_counter == 2'b00);
    assign tx_active = tx_ready & tx_req;
    
    always @(*) begin
        hs_mode = tx_active;
        hs_data = {8{tx_active}} & tx_payload;
        lp_mode = ~tx_active;
    end

    always @(posedge tx_req or posedge hs_mode) begin
        if (hs_mode) 
            delay_counter <= DELAY_CYCLES;
        else if (delay_counter != 2'b00) 
            delay_counter <= delay_counter - 1'b1;
    end
endmodule