//SystemVerilog
module shadow_reg_pipeline #(
    parameter DW = 8
)(
    input wire clk,
    input wire en,
    input wire [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    // Stage 1: Input capture with enable control
    reg [DW-1:0] stage1_reg;
    
    // Stage 2: Middle pipeline register
    reg [DW-1:0] stage2_reg;
    
    // Pipeline flow control
    always @(posedge clk) begin
        // Stage 1: Conditionally capture input data
        if (en) begin
            stage1_reg <= data_in;
        end
        
        // Stage 2: Forward data to middle pipeline register
        stage2_reg <= stage1_reg;
        
        // Stage 3: Forward data to output register
        data_out <= stage2_reg;
    end
endmodule