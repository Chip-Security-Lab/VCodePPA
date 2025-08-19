//SystemVerilog
module bernoulli_rng #(
    parameter THRESHOLD = 128 // Probability = THRESHOLD/256
)(
    input wire clk,
    input wire rst,
    output wire random_bit
);
    reg [7:0] lfsr_reg;
    reg [7:0] lfsr_next;
    reg [7:0] lfsr_pipelined;
    reg random_bit_reg;
    reg random_bit_mux;

    // LFSR next-state logic (combinational)
    always @(*) begin
        lfsr_next = {lfsr_reg[6:0], lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3]};
    end

    // LFSR register and pipelined register for pipelining the datapath
    always @(posedge clk) begin
        if (rst) begin
            lfsr_reg <= 8'h1;
            lfsr_pipelined <= 8'h1;
        end else begin
            lfsr_reg <= lfsr_next;
            lfsr_pipelined <= lfsr_next;
        end
    end

    // Explicit multiplexer for random_bit_mux
    always @(*) begin
        case (lfsr_pipelined < THRESHOLD)
            1'b1: random_bit_mux = 1'b1;
            1'b0: random_bit_mux = 1'b0;
            default: random_bit_mux = 1'b0;
        endcase
    end

    // Pipeline register for comparison
    always @(posedge clk) begin
        if (rst) begin
            random_bit_reg <= 1'b0;
        end else begin
            random_bit_reg <= random_bit_mux;
        end
    end

    assign random_bit = random_bit_reg;

endmodule