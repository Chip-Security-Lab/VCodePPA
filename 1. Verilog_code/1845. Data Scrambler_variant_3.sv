//SystemVerilog
module data_scrambler #(parameter POLY_WIDTH = 7) (
    input  wire clk,
    input  wire reset,
    input  wire data_in,
    input  wire [POLY_WIDTH-1:0] polynomial,
    input  wire [POLY_WIDTH-1:0] initial_state,
    input  wire load_init,
    output wire data_out
);

    reg [POLY_WIDTH-1:0] lfsr_reg;
    reg feedback_reg;
    reg data_out_reg;
    wire feedback;
    wire scrambled_data;
    
    assign feedback = ^(lfsr_reg & polynomial);
    assign scrambled_data = data_in ^ lfsr_reg[0];
    assign data_out = data_out_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            lfsr_reg <= {POLY_WIDTH{1'b1}};
            feedback_reg <= 1'b0;
            data_out_reg <= 1'b0;
        end
        else if (load_init) begin
            lfsr_reg <= initial_state;
            feedback_reg <= ^(initial_state & polynomial);
            data_out_reg <= scrambled_data;
        end
        else begin
            lfsr_reg <= {feedback_reg, lfsr_reg[POLY_WIDTH-1:1]};
            feedback_reg <= feedback;
            data_out_reg <= scrambled_data;
        end
    end

endmodule