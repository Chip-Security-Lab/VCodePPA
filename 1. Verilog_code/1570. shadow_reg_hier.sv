module shadow_reg_hier #(parameter DW=16) (
    input clk, main_en, sub_en,
    input [DW-1:0] main_data,
    output [DW-1:0] final_data
);
    reg [DW-1:0] main_shadow, sub_shadow;
    always @(posedge clk) begin
        if(main_en) main_shadow <= main_data;
        if(sub_en)  sub_shadow <= main_shadow;
    end
    assign final_data = sub_shadow;
endmodule