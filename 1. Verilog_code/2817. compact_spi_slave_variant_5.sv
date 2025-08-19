//SystemVerilog
module compact_spi_slave(
    input wire sclk,
    input wire cs,
    input wire mosi,
    output wire miso,
    input wire [7:0] tx_byte,
    output reg [7:0] rx_byte
);
    reg [7:0] tx_shift_reg;
    reg [2:0] bit_count;
    wire [7:0] sum_result;
    reg [7:0] rx_shift_reg;

    assign miso = tx_shift_reg[7];

    always @(posedge sclk or posedge cs) begin
        if (cs) begin
            bit_count <= 3'b000;
            tx_shift_reg <= tx_byte;
            rx_shift_reg <= 8'b0;
            rx_byte <= 8'b0;
        end else begin
            rx_shift_reg <= {rx_shift_reg[6:0], mosi};
            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
            bit_count <= bit_count + 1'b1;
            if (bit_count == 3'b111) begin
                rx_byte <= rx_shift_reg_parallel_sum(rx_shift_reg, 8'b0);
            end
        end
    end

    // 并行前缀加法器顶层调用
    function [7:0] rx_shift_reg_parallel_sum;
        input [7:0] a;
        input [7:0] b;
        reg [7:0] sum;
        reg carry_out;
        begin
            {carry_out, sum} = parallel_prefix_adder_8bit(a, b, 1'b0);
            rx_shift_reg_parallel_sum = sum;
        end
    endfunction

    // 并行前缀加法器实现
    function [8:0] parallel_prefix_adder_8bit;
        input [7:0] a;
        input [7:0] b;
        input cin;
        reg [7:0] g, p;
        reg [7:0] c;
        reg [7:0] sum;
        begin
            // Generate and propagate
            g = a & b;
            p = a ^ b;

            // Level 0
            c[0] = cin;
            // Level 1
            c[1] = g[0] | (p[0] & cin);
            // Level 2
            c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
            // Level 3
            c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
            // Level 4
            c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
            // Level 5
            c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & cin);
            // Level 6
            c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin);
            // Level 7
            c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin);
            // Level 8 (carry out)
            parallel_prefix_adder_8bit[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & cin);

            // Sum
            sum[0] = p[0] ^ cin;
            sum[1] = p[1] ^ c[1];
            sum[2] = p[2] ^ c[2];
            sum[3] = p[3] ^ c[3];
            sum[4] = p[4] ^ c[4];
            sum[5] = p[5] ^ c[5];
            sum[6] = p[6] ^ c[6];
            sum[7] = p[7] ^ c[7];

            parallel_prefix_adder_8bit[7:0] = sum;
        end
    endfunction

endmodule