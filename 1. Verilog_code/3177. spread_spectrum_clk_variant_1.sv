//SystemVerilog
module spread_spectrum_clk(
    input clk_in,
    input rst,
    input [3:0] modulation,
    input valid,
    output reg ready,
    output reg clk_out
);

    reg [5:0] counter;
    reg [3:0] mod_counter;
    reg [3:0] divisor;
    reg [3:0] modulation_reg;

    // Parallel prefix adder signals
    wire [5:0] counter_next;
    wire [5:0] counter_plus_1;
    wire [5:0] g, p;
    wire [5:0] c;

    // Generate and propagate signals
    assign g = counter & 6'b111111;
    assign p = 6'b000001;

    // Parallel prefix computation
    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);

    // Sum computation
    assign counter_plus_1 = counter ^ p ^ c;
    assign counter_next = (counter >= {2'b00, divisor}) ? 6'd0 : counter_plus_1;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 6'd0;
            mod_counter <= 4'd0;
            divisor <= 4'd8;
            clk_out <= 1'b0;
            ready <= 1'b1;
            modulation_reg <= 4'd0;
        end else begin
            if (valid && ready) begin
                modulation_reg <= modulation;
                ready <= 1'b0;
            end
            
            mod_counter <= mod_counter + 4'd1;
            if (mod_counter == 4'd15) begin
                divisor <= 4'd8 + (modulation_reg & {3'b000, counter[5]});
                ready <= 1'b1;
            end
            
            counter <= counter_next;
            if (counter >= {2'b00, divisor}) begin
                clk_out <= ~clk_out;
            end
        end
    end
endmodule