module prog_freq_divider #(parameter COUNTER_WIDTH = 16) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire [COUNTER_WIDTH-1:0] divisor,
    input  wire update,
    output reg  clk_o
);
    reg [COUNTER_WIDTH-1:0] counter;
    reg [COUNTER_WIDTH-1:0] divisor_reg;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            divisor_reg <= {COUNTER_WIDTH{1'b0}};
            clk_o <= 1'b0;
        end else begin
            if (update)
                divisor_reg <= divisor;
                
            if (counter >= divisor_reg - 1) begin
                counter <= {COUNTER_WIDTH{1'b0}};
                clk_o <= ~clk_o;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule