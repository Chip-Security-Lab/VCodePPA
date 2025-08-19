//SystemVerilog
module dram_mode_register #(
    parameter MR_ADDR_WIDTH = 4
)(
    input clk,
    input load_mr,
    input [MR_ADDR_WIDTH-1:0] mr_addr,
    input [15:0] mr_data,
    output reg [15:0] current_mode,
    // Added subtraction inputs and output
    input [15:0] sub_a,
    input [15:0] sub_b,
    output reg [15:0] sub_result
);
    reg [15:0] mode_regs [0:(1<<MR_ADDR_WIDTH)-1];
    
    // Two's complement subtraction implementation
    wire [15:0] sub_b_complement;
    wire [15:0] sub_temp;
    wire sub_carry;
    
    // Generate two's complement of sub_b
    assign sub_b_complement = ~sub_b + 1'b1;
    
    // Perform addition with carry
    assign {sub_carry, sub_temp} = sub_a + sub_b_complement;
    
    always @(posedge clk) begin
        if(load_mr)
            mode_regs[mr_addr] <= mr_data;
        
        current_mode <= mode_regs[mr_addr];
        
        // Store subtraction result
        sub_result <= sub_temp;
    end
endmodule