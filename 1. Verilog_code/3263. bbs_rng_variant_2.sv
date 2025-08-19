//SystemVerilog
module bbs_rng (
    input wire clock,
    input wire reset,
    output wire [7:0] random_byte
);
    parameter P = 11;
    parameter Q = 23;
    parameter M = P * Q;   // 253

    reg [15:0] state_reg;
    reg [15:0] next_state;
    reg [7:0] random_byte_reg;

    // Move register before output mux logic (retiming)
    always @(posedge clock) begin
        if (reset)
            state_reg <= 16'd3;
        else
            state_reg <= next_state;
    end

    // Combinational logic for next state
    always @(*) begin
        next_state = (state_reg * state_reg) % M;
    end

    // Register moved before output assignment
    always @(posedge clock) begin
        if (reset)
            random_byte_reg <= 8'd0;
        else
            random_byte_reg <= (next_state[7:0]);
    end

    assign random_byte = random_byte_reg;

endmodule