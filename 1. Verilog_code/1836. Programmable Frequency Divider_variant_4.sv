//SystemVerilog
module prog_freq_divider #(parameter COUNTER_WIDTH = 16) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire [COUNTER_WIDTH-1:0] divisor,
    input  wire update,
    output reg  clk_o
);
    reg [COUNTER_WIDTH-1:0] counter;
    reg [COUNTER_WIDTH-1:0] divisor_reg;
    wire [COUNTER_WIDTH-1:0] borrow;
    wire [COUNTER_WIDTH-1:0] diff;
    
    // Generate borrow chain
    assign borrow[0] = 1'b1;
    genvar i;
    generate
        for(i = 0; i < COUNTER_WIDTH-1; i = i + 1) begin : borrow_chain
            assign borrow[i+1] = ~(counter[i] | ~divisor_reg[i]) & borrow[i];
        end
    endgenerate
    
    // Calculate difference using borrow lookahead
    assign diff = counter - divisor_reg;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            divisor_reg <= {COUNTER_WIDTH{1'b0}};
            clk_o <= 1'b0;
        end else if (update) begin
            divisor_reg <= divisor;
            if (diff == {COUNTER_WIDTH{1'b0}}) begin
                counter <= {COUNTER_WIDTH{1'b0}};
                clk_o <= ~clk_o;
            end else begin
                counter <= counter + 1'b1;
            end
        end else if (diff == {COUNTER_WIDTH{1'b0}}) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            clk_o <= ~clk_o;
        end else begin
            counter <= counter + 1'b1;
        end
    end
endmodule