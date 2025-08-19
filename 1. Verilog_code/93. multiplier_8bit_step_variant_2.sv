//SystemVerilog
// Top level module
module multiplier_8bit_step (
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product,
    output reg product_valid
);

    // State machine signals
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    // Input registers
    reg [7:0] a_reg;
    reg [7:0] b_reg;

    // Multiplier core signals
    wire [15:0] product_core;
    wire core_valid;

    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ready <= 1'b1;
            product_valid <= 1'b0;
            product <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid && ready) begin
                        a_reg <= a;
                        b_reg <= b;
                        ready <= 1'b0;
                        state <= CALC;
                    end
                end
                CALC: begin
                    product <= product_core;
                    product_valid <= core_valid;
                    state <= DONE;
                end
                DONE: begin
                    if (!valid) begin
                        ready <= 1'b1;
                        product_valid <= 1'b0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    // Multiplier core instantiation
    multiplier_core u_multiplier_core (
        .a(a_reg),
        .b(b_reg),
        .product(product_core),
        .valid(core_valid)
    );

endmodule

// Multiplier core module
module multiplier_core (
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product,
    output reg valid
);

    always @(*) begin
        product = 16'd0;
        valid = 1'b1;

        // Unrolled multiplication logic
        if (a[0] & b[0]) product[0] = product[0] ^ 1;
        if (a[0] & b[1]) product[1] = product[1] ^ 1;
        if (a[0] & b[2]) product[2] = product[2] ^ 1;
        if (a[0] & b[3]) product[3] = product[3] ^ 1;
        if (a[0] & b[4]) product[4] = product[4] ^ 1;
        if (a[0] & b[5]) product[5] = product[5] ^ 1;
        if (a[0] & b[6]) product[6] = product[6] ^ 1;
        if (a[0] & b[7]) product[7] = product[7] ^ 1;

        if (a[1] & b[0]) product[1] = product[1] ^ 1;
        if (a[1] & b[1]) product[2] = product[2] ^ 1;
        if (a[1] & b[2]) product[3] = product[3] ^ 1;
        if (a[1] & b[3]) product[4] = product[4] ^ 1;
        if (a[1] & b[4]) product[5] = product[5] ^ 1;
        if (a[1] & b[5]) product[6] = product[6] ^ 1;
        if (a[1] & b[6]) product[7] = product[7] ^ 1;
        if (a[1] & b[7]) product[8] = product[8] ^ 1;

        if (a[2] & b[0]) product[2] = product[2] ^ 1;
        if (a[2] & b[1]) product[3] = product[3] ^ 1;
        if (a[2] & b[2]) product[4] = product[4] ^ 1;
        if (a[2] & b[3]) product[5] = product[5] ^ 1;
        if (a[2] & b[4]) product[6] = product[6] ^ 1;
        if (a[2] & b[5]) product[7] = product[7] ^ 1;
        if (a[2] & b[6]) product[8] = product[8] ^ 1;
        if (a[2] & b[7]) product[9] = product[9] ^ 1;

        if (a[3] & b[0]) product[3] = product[3] ^ 1;
        if (a[3] & b[1]) product[4] = product[4] ^ 1;
        if (a[3] & b[2]) product[5] = product[5] ^ 1;
        if (a[3] & b[3]) product[6] = product[6] ^ 1;
        if (a[3] & b[4]) product[7] = product[7] ^ 1;
        if (a[3] & b[5]) product[8] = product[8] ^ 1;
        if (a[3] & b[6]) product[9] = product[9] ^ 1;
        if (a[3] & b[7]) product[10] = product[10] ^ 1;

        if (a[4] & b[0]) product[4] = product[4] ^ 1;
        if (a[4] & b[1]) product[5] = product[5] ^ 1;
        if (a[4] & b[2]) product[6] = product[6] ^ 1;
        if (a[4] & b[3]) product[7] = product[7] ^ 1;
        if (a[4] & b[4]) product[8] = product[8] ^ 1;
        if (a[4] & b[5]) product[9] = product[9] ^ 1;
        if (a[4] & b[6]) product[10] = product[10] ^ 1;
        if (a[4] & b[7]) product[11] = product[11] ^ 1;

        if (a[5] & b[0]) product[5] = product[5] ^ 1;
        if (a[5] & b[1]) product[6] = product[6] ^ 1;
        if (a[5] & b[2]) product[7] = product[7] ^ 1;
        if (a[5] & b[3]) product[8] = product[8] ^ 1;
        if (a[5] & b[4]) product[9] = product[9] ^ 1;
        if (a[5] & b[5]) product[10] = product[10] ^ 1;
        if (a[5] & b[6]) product[11] = product[11] ^ 1;
        if (a[5] & b[7]) product[12] = product[12] ^ 1;

        if (a[6] & b[0]) product[6] = product[6] ^ 1;
        if (a[6] & b[1]) product[7] = product[7] ^ 1;
        if (a[6] & b[2]) product[8] = product[8] ^ 1;
        if (a[6] & b[3]) product[9] = product[9] ^ 1;
        if (a[6] & b[4]) product[10] = product[10] ^ 1;
        if (a[6] & b[5]) product[11] = product[11] ^ 1;
        if (a[6] & b[6]) product[12] = product[12] ^ 1;
        if (a[6] & b[7]) product[13] = product[13] ^ 1;

        if (a[7] & b[0]) product[7] = product[7] ^ 1;
        if (a[7] & b[1]) product[8] = product[8] ^ 1;
        if (a[7] & b[2]) product[9] = product[9] ^ 1;
        if (a[7] & b[3]) product[10] = product[10] ^ 1;
        if (a[7] & b[4]) product[11] = product[11] ^ 1;
        if (a[7] & b[5]) product[12] = product[12] ^ 1;
        if (a[7] & b[6]) product[13] = product[13] ^ 1;
        if (a[7] & b[7]) product[14] = product[14] ^ 1;
    end

endmodule