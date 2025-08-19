//SystemVerilog
module bin2bcd #(parameter WIDTH = 8) (
    input wire clk,
    input wire load,
    input wire [WIDTH-1:0] bin_in,
    output reg [11:0] bcd_out,           // 3 BCD digits
    output reg ready
);

    reg [WIDTH-1:0] bin_reg;
    reg [3:0] state;

    // First-level buffer for bcd_out
    reg [11:0] bcd_buffer1;
    // Second-level buffer for bcd_out (fanout balancing)
    reg [11:0] bcd_buffer2;

    // Internal wires for BCD digit manipulation
    wire [3:0] bcd_digit0, bcd_digit1, bcd_digit2;
    assign bcd_digit0 = bcd_buffer2[3:0];
    assign bcd_digit1 = bcd_buffer2[7:4];
    assign bcd_digit2 = bcd_buffer2[11:8];

    // Carry Lookahead Adder for 4 bits
    function [4:0] carry_lookahead_adder4;
        input [3:0] a;
        input [3:0] b;
        input cin;
        reg [3:0] g, p;
        reg [4:0] c;
        reg [3:0] sum;
        begin
            g = a & b;              // generate
            p = a ^ b;              // propagate
            c[0] = cin;
            c[1] = g[0] | (p[0] & c[0]);
            c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
            c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
            c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
            sum = p ^ c[3:0];
            carry_lookahead_adder4 = {c[4], sum};
        end
    endfunction

    // Add 3 using carry lookahead adder
    function [3:0] cla_add3;
        input [3:0] val;
        reg [4:0] cla_result;
        begin
            cla_result = carry_lookahead_adder4(val, 4'd3, 1'b0);
            cla_add3 = cla_result[3:0];
        end
    endfunction

    always @(posedge clk) begin
        if (load) begin
            bin_reg      <= bin_in;
            bcd_buffer1  <= 12'b0;
            bcd_buffer2  <= 12'b0;
            bcd_out      <= 12'b0;
            state        <= 4'd0;
            ready        <= 1'b0;
        end else if (!ready) begin
            if (state < WIDTH) begin
                // Shift left and bring in next MSB from bin_reg
                bcd_buffer1 <= {bcd_buffer2[10:0], bin_reg[WIDTH-1]};
                bin_reg     <= {bin_reg[WIDTH-2:0], 1'b0};
                state       <= state + 1;
            end else begin
                ready <= 1'b1;
            end
        end
    end

    // First buffer stage: combinational adjustment after shift using carry lookahead adder
    reg [11:0] bcd_adj1;
    always @(*) begin
        bcd_adj1 = bcd_buffer1;
        if (bcd_buffer1[3:0] > 4)
            bcd_adj1[3:0] = cla_add3(bcd_buffer1[3:0]);
        if (bcd_buffer1[7:4] > 4)
            bcd_adj1[7:4] = cla_add3(bcd_buffer1[7:4]);
        if (bcd_buffer1[11:8] > 4)
            bcd_adj1[11:8] = cla_add3(bcd_buffer1[11:8]);
    end

    // Second buffer stage (registered): balances fanout of bcd signal
    always @(posedge clk) begin
        if (load) begin
            bcd_buffer2 <= 12'b0;
        end else if (!ready && state < WIDTH) begin
            bcd_buffer2 <= bcd_adj1;
        end
    end

    // Output buffer stage: ensures balanced fanout to output and other internal logic
    always @(posedge clk) begin
        if (load) begin
            bcd_out <= 12'b0;
        end else if (!ready && state < WIDTH) begin
            bcd_out <= bcd_buffer2;
        end
    end

endmodule