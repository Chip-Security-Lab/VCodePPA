//SystemVerilog
module CAN_Monitor_Error_Detect #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,
    input can_tx,
    output reg form_error,
    output reg ack_error,
    output reg crc_error
);
    reg [6:0] bit_counter;
    reg [14:0] crc_calc;
    reg [14:0] crc_received;

    // Wires for next state calculations
    wire [6:0] next_bit_counter;
    wire [14:0] next_crc_calc;
    wire [14:0] next_crc_received;
    wire next_form_error;
    wire next_ack_error;
    wire next_crc_error;

    // Combinational logic to calculate next state values
    assign next_bit_counter = bit_counter + 1;

    // CRC calculation - based on the original code's polynomial 15'h4599
    assign next_crc_calc = {crc_calc[13:0], 1'b0} ^
                           ((crc_calc[14] ^ can_rx) ? 15'h4599 : 15'h0);

    // CRC received update - captures bit when counter is 95
    assign next_crc_received = (bit_counter == 95) ? {crc_received[13:0], can_rx} : crc_received;

    // Error detection logic
    assign next_form_error = (can_rx && can_tx);
    assign next_ack_error = (bit_counter == 96) && !can_tx;
    assign next_crc_error = (bit_counter == 97) && (crc_calc != crc_received);

    // Sequential logic for state updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
            crc_calc <= 0;
            crc_received <= 0;
            form_error <= 0;
            ack_error <= 0;
            crc_error <= 0;
        end else begin
            bit_counter <= next_bit_counter;
            crc_calc <= next_crc_calc;
            crc_received <= next_crc_received;
            form_error <= next_form_error;
            ack_error <= next_ack_error;
            crc_error <= next_crc_error;
        end
    end

endmodule