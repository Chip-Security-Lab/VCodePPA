//SystemVerilog
module sync_signed_divider (
    input clk,
    input reset,
    input signed [7:0] a,
    input signed [7:0] b,
    output reg signed [7:0] quotient,
    output reg signed [7:0] remainder
);

    // Newton-Raphson states
    localparam IDLE = 2'b00;
    localparam ITERATE = 2'b01;
    localparam DONE = 2'b10;

    reg [1:0] state;
    reg [7:0] dividend;
    reg [7:0] divisor;
    reg [2:0] iter_count;
    reg [15:0] x_n;  // 16-bit for better precision
    reg [15:0] x_n_plus_1;
    reg [15:0] product;
    reg sign_result;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            quotient <= 0;
            remainder <= 0;
            dividend <= 0;
            divisor <= 0;
            iter_count <= 0;
            x_n <= 0;
            x_n_plus_1 <= 0;
            product <= 0;
            sign_result <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (b != 0) begin
                        sign_result <= (a[7] ^ b[7]);
                        dividend <= (a[7]) ? -a : a;
                        divisor <= (b[7]) ? -b : b;
                        x_n <= {8'b0, 8'h80};  // Initial guess: 0.5
                        iter_count <= 0;
                        state <= ITERATE;
                    end
                end

                ITERATE: begin
                    if (iter_count < 4) begin  // 4 iterations for 8-bit precision
                        // x_{n+1} = x_n * (2 - b * x_n)
                        product = divisor * x_n[15:8];
                        x_n_plus_1 = x_n * (16'h200 - product);
                        x_n <= x_n_plus_1;
                        iter_count <= iter_count + 1;
                    end else begin
                        // Final multiplication: a * (1/b)
                        product = dividend * x_n[15:8];
                        quotient <= (sign_result) ? -product[7:0] : product[7:0];
                        remainder <= (a[7]) ? -dividend : dividend;
                        state <= DONE;
                    end
                end

                DONE: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule