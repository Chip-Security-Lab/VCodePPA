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
    assign tx_ready = (delay_counter == 0);

    always @(*) begin
        if (tx_ready && tx_req) begin
            hs_mode = 1;
            hs_data = tx_payload;
            lp_mode = 0;
        end else begin
            hs_mode = 0;
            hs_data = 8'h00;
            lp_mode = 1;
        end
    end

    always @(posedge tx_req or posedge hs_mode) begin
        if (hs_mode) delay_counter <= DELAY_CYCLES;
        else if (|delay_counter) delay_counter <= delay_counter - 1;
    end
endmodule
