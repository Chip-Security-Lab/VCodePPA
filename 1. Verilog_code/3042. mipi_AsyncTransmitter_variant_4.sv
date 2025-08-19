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
    wire delay_done = ~|delay_counter;
    assign tx_ready = delay_done;

    always @(posedge tx_req or posedge hs_mode) begin
        if (hs_mode) begin
            delay_counter <= DELAY_CYCLES;
            hs_mode <= 1'b1;
            hs_data <= tx_payload;
            lp_mode <= 1'b0;
        end else if (delay_counter != 2'b00) begin
            delay_counter <= delay_counter - 1'b1;
            hs_mode <= 1'b0;
            hs_data <= 8'h00;
            lp_mode <= 1'b1;
        end else begin
            hs_mode <= 1'b0;
            hs_data <= 8'h00;
            lp_mode <= 1'b1;
        end
    end
endmodule