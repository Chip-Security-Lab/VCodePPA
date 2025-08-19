//SystemVerilog
module sync_majority_filter #(
    parameter WINDOW = 5,
    parameter W = WINDOW / 2 + 1  // Majority threshold
)(
    input clk, rst_n,
    input data_in,
    output reg data_out
);
    reg [WINDOW-1:0] shift_reg;
    reg [2:0] one_count;  // Count of '1's (assumes WINDOW ≤ 7)
    reg [2:0] one_count_pipe;  // Pipeline register for one_count
    reg data_in_pipe;  // Pipeline register for input data
    reg shift_out_pipe;  // Pipeline register for shift out data
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            one_count <= 0;
            one_count_pipe <= 0;
            data_in_pipe <= 0;
            shift_out_pipe <= 0;
            data_out <= 0;
        end else begin
            // Pipeline stage 1: Calculate new one_count
            one_count_pipe <= one_count + data_in - shift_reg[WINDOW-1];
            
            // Pipeline stage 1: Register input and shift out data
            data_in_pipe <= data_in;
            shift_out_pipe <= shift_reg[WINDOW-1];
            
            // Pipeline stage 2: Update shift register
            shift_reg <= {shift_reg[WINDOW-2:0], data_in_pipe};
            
            // Pipeline stage 2: Update one_count
            one_count <= one_count_pipe;
            
            // Pipeline stage 2: Majority decision
            data_out <= (one_count_pipe >= W) ? 1'b1 : 1'b0;
        end
    end
endmodule