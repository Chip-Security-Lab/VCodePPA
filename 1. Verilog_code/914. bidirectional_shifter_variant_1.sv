//SystemVerilog
module bidirectional_shifter(
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    input wire [4:0] shift_amount,
    input wire direction,  // 0: left, 1: right
    output reg [31:0] result
);

    // Pipeline registers
    reg [31:0] data_reg;
    reg [4:0] shift_reg;
    reg dir_reg;
    
    // Pre-shift registered values
    reg [31:0] left_shift_result_reg;
    reg [31:0] right_shift_result_reg;
    
    // Input pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 32'b0;
            shift_reg <= 5'b0;
            dir_reg <= 1'b0;
        end else begin
            data_reg <= data_in;
            shift_reg <= shift_amount;
            dir_reg <= direction;
        end
    end
    
    // Pre-compute and register both shift operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_shift_result_reg <= 32'b0;
            right_shift_result_reg <= 32'b0;
        end else begin
            left_shift_result_reg <= data_reg << shift_reg;
            right_shift_result_reg <= data_reg >> shift_reg;
        end
    end
    
    // Output stage - now a simple mux between pre-computed values
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 32'b0;
        end else begin
            result <= dir_reg ? right_shift_result_reg : left_shift_result_reg;
        end
    end

endmodule