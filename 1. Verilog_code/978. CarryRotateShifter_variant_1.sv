//SystemVerilog
module CarryRotateShifter #(parameter WIDTH=8) (
    input wire clk,
    input wire rst_n,      // Reset signal for proper pipeline initialization
    input wire en,
    input wire valid_in,   // Valid signal for pipeline control
    input wire carry_in,
    output wire valid_out, // Pipeline status output
    output wire carry_out,
    output wire [WIDTH-1:0] data_out
);
    // Pipeline stage registers
    reg [WIDTH-1:0] data_stage1, data_stage2;
    reg carry_stage1, carry_stage2;
    reg valid_stage1, valid_stage2;
    
    // Combined pipeline stages with same trigger conditions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers simultaneously
            data_stage1 <= {WIDTH{1'b0}};
            carry_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            data_stage2 <= {WIDTH{1'b0}};
            carry_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (en) begin
            // Pipeline stage 1: First half of rotation
            valid_stage1 <= valid_in;
            data_stage1 <= {data_out[WIDTH-2:0], carry_in};
            carry_stage1 <= data_out[WIDTH-1];
            
            // Pipeline stage 2: Complete rotation and prepare outputs
            valid_stage2 <= valid_stage1;
            data_stage2 <= data_stage1;
            carry_stage2 <= carry_stage1;
        end
    end
    
    // Output assignments
    assign data_out = data_stage2;
    assign carry_out = carry_stage2;
    assign valid_out = valid_stage2;

endmodule