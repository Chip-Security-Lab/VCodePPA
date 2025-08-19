module bin2bcd #(parameter WIDTH = 8) (
    input wire clk, load,
    input wire [WIDTH-1:0] bin_in,
    output reg [11:0] bcd_out,  // 3 BCD digits
    output reg ready
);
    reg [WIDTH-1:0] bin_reg;
    reg [3:0] state;
    
    always @(posedge clk) begin
        if (load) begin
            bin_reg <= bin_in;
            bcd_out <= 12'b0;
            state <= 4'd0;
            ready <= 1'b0;
        end else if (!ready) begin
            if (state < WIDTH) begin
                bcd_out <= {bcd_out[10:0], bin_reg[WIDTH-1]};
                bin_reg <= {bin_reg[WIDTH-2:0], 1'b0};
                
                if (bcd_out[3:0] > 4) bcd_out[3:0] <= bcd_out[3:0] + 3;
                if (bcd_out[7:4] > 4) bcd_out[7:4] <= bcd_out[7:4] + 3;
                if (bcd_out[11:8] > 4) bcd_out[11:8] <= bcd_out[11:8] + 3;
                
                state <= state + 1;
            end else ready <= 1'b1;
        end
    end
endmodule