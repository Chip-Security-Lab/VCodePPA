//SystemVerilog
module bbs_rng_valid_ready (
    input  wire        clock,
    input  wire        reset,
    input  wire        random_byte_ready,
    output wire        random_byte_valid,
    output wire [7:0]  random_byte
);
    parameter P = 11;
    parameter Q = 23;
    parameter M = P * Q;   // 253

    reg  [15:0] state_reg, state_next;
    reg  [7:0]  output_reg, output_next;
    reg         valid_reg, valid_next;

    wire [31:0] square;
    wire [15:0] mod_m;

    assign square = state_reg * state_reg;

    // Optimized modulo operation for M = 253
    function [15:0] mod253;
        input [31:0] in;
        reg [15:0] temp;
        begin
            temp = in[15:0] + in[31:16] * 3;
            if (temp >= 253)
                temp = temp - 253;
            if (temp >= 253)
                temp = temp - 253;
            if (temp >= 253)
                temp = temp - 253;
            mod253 = temp;
        end
    endfunction

    assign mod_m = mod253(square);

    // Valid-Ready Handshake FSM
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state_reg  <= 16'd3;
            output_reg <= 8'd0;
            valid_reg  <= 1'b0;
        end else begin
            state_reg  <= state_next;
            output_reg <= output_next;
            valid_reg  <= valid_next;
        end
    end

    always @* begin
        state_next  = state_reg;
        output_next = output_reg;
        valid_next  = valid_reg;

        if (!valid_reg) begin
            // Generate new random byte if output is not valid
            state_next  = mod_m;
            output_next = state_reg[7:0];
            valid_next  = 1'b1;
        end else if (valid_reg && random_byte_ready) begin
            // On handshake, update state and output next random byte
            state_next  = mod_m;
            output_next = state_reg[7:0];
            valid_next  = 1'b1;
        end
        // If valid_reg is high and ready is not asserted, hold values (stall)
    end

    assign random_byte_valid = valid_reg;
    assign random_byte       = output_reg;

endmodule