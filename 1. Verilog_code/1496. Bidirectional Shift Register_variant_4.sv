//SystemVerilog
module bidir_shift_reg #(parameter WIDTH = 8) (
    input wire clk, rst, en, dir, data_in,
    output reg [WIDTH-1:0] q_out
);
    // Single shift register implementation improves resource utilization
    reg [WIDTH-1:0] shift_reg;
    reg dir_reg, data_in_reg;
    
    // Registered control signals for timing improvement
    always @(posedge clk) begin
        if (rst) begin
            dir_reg <= 1'b0;
            data_in_reg <= 1'b0;
        end else if (en) begin
            dir_reg <= dir;
            data_in_reg <= data_in;
        end
    end
    
    // Unified shift register logic with optimized comparisons
    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= {WIDTH{1'b0}};
        end else if (en) begin
            case (dir_reg)
                1'b1: shift_reg <= {shift_reg[WIDTH-2:0], data_in_reg}; // Shift left
                1'b0: shift_reg <= {data_in_reg, shift_reg[WIDTH-1:1]}; // Shift right
            endcase
        end
    end
    
    // Direct shift register output assignment
    always @(posedge clk) begin
        if (rst)
            q_out <= {WIDTH{1'b0}};
        else if (en)
            q_out <= shift_reg;
    end
endmodule