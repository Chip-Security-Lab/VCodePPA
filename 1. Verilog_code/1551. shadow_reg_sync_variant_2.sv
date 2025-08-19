//SystemVerilog
module shadow_reg_sync #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // Pipeline registers
    reg [WIDTH-1:0] shadow_stage1;
    reg [WIDTH-1:0] shadow_stage2;
    reg [WIDTH-1:0] shadow_stage3;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Combined always block for stages 1, 2, 3 and output stage
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            shadow_stage1 <= 0;
            shadow_stage2 <= 0;
            shadow_stage3 <= 0;
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            valid_stage3 <= 0;
            data_out <= 0;
        end
        else begin
            if(en) begin
                shadow_stage1 <= data_in;
                valid_stage1 <= 1;
            end
            else begin
                valid_stage1 <= 0;
            end
            
            shadow_stage2 <= shadow_stage1;
            valid_stage2 <= valid_stage1;

            shadow_stage3 <= shadow_stage2;
            valid_stage3 <= valid_stage2;

            if(!en && valid_stage3) begin
                data_out <= shadow_stage3;
            end
        end
    end
endmodule