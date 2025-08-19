//SystemVerilog
module shadow_reg_hier #(parameter DW=16) (
    input clk, main_en, sub_en,
    input [DW-1:0] main_data,
    output reg [DW-1:0] final_data
);
    reg [DW-1:0] main_shadow;
    
    always @(posedge clk) begin
        if(main_en) 
            main_shadow <= main_data;
            
        if(sub_en)
            final_data <= main_shadow;
    end
endmodule