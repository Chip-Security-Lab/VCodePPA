//SystemVerilog
module sync_majority_filter #(
    parameter WINDOW = 5,
    parameter W = WINDOW / 2 + 1
)(
    input clk, rst_n,
    input data_in,
    output reg data_out
);
    reg [WINDOW-1:0] shift_reg;
    reg [2:0] one_count;
    wire [2:0] next_one_count;
    wire next_data_out;
    
    // Optimized count calculation using carry-save adder
    wire [2:0] add_in = {2'b0, data_in};
    wire [2:0] sub_out = {2'b0, shift_reg[WINDOW-1]};
    assign next_one_count = one_count + add_in - sub_out;
    
    // Optimized majority decision using range check
    assign next_data_out = (next_one_count[2] | (next_one_count[1:0] >= W[1:0]));
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= {WINDOW{1'b0}};
            one_count <= 3'b000;
            data_out <= 1'b0;
        end else begin
            shift_reg <= {shift_reg[WINDOW-2:0], data_in};
            one_count <= next_one_count;
            data_out <= next_data_out;
        end
    end
endmodule