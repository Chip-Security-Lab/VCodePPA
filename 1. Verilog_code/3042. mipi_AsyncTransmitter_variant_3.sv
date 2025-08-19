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
    wire [1:0] state;
    
    assign tx_ready = ~|delay_counter;
    assign state = {tx_ready, tx_req};

    always @(*) begin
        {hs_mode, hs_data, lp_mode} = state[1] & state[0] ? 
            {1'b1, tx_payload, 1'b0} : 
            {1'b0, 8'h00, 1'b1};
    end

    always @(posedge tx_req or posedge hs_mode) begin
        if (hs_mode & ~|delay_counter)
            delay_counter <= DELAY_CYCLES;
        else if (|delay_counter)
            delay_counter <= delay_counter - 1;
    end
endmodule