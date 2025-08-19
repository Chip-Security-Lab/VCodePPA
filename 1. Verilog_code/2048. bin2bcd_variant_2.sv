//SystemVerilog
module bin2bcd #(parameter WIDTH = 8) (
    input wire clk,
    input wire load,
    input wire [WIDTH-1:0] bin_in,
    output reg [11:0] bcd_out,  // 3 BCD digits
    output reg ready
);
    reg [WIDTH-1:0] bin_reg;
    reg [3:0] state;
    reg [11:0] bcd_next;

    always @(posedge clk) begin
        if (load) begin
            bin_reg <= bin_in;
            bcd_out <= 12'b0;
            state <= 4'd0;
            ready <= 1'b0;
        end else if (!ready) begin
            if (state < WIDTH) begin
                // Optimized parallel BCD add-3 using range checking and direct assignments
                bcd_next[3:0]   = (bcd_out[3:0]   > 4'd4) ? bcd_out[3:0]   + 4'd3 : bcd_out[3:0];
                bcd_next[7:4]   = (bcd_out[7:4]   > 4'd4) ? bcd_out[7:4]   + 4'd3 : bcd_out[7:4];
                bcd_next[11:8]  = (bcd_out[11:8]  > 4'd4) ? bcd_out[11:8]  + 4'd3 : bcd_out[11:8];

                // Shift left and insert next bit
                bcd_out <= {bcd_next[10:0], bin_reg[WIDTH-1]};
                bin_reg <= {bin_reg[WIDTH-2:0], 1'b0};
                state <= state + 1'b1;
            end else begin
                ready <= 1'b1;
            end
        end
    end
endmodule