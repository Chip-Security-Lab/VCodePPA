//SystemVerilog
module shadow_reg_hier #(parameter DW=16) (
    input clk, main_en, sub_en,
    input [DW-1:0] main_data,
    output [DW-1:0] final_data
);
    reg [DW-1:0] main_shadow, sub_shadow;
    wire [7:0] subtractor_out;
    wire [8:0] borrow;
    
    // 主要寄存器逻辑
    always @(posedge clk) begin
        if(main_en) main_shadow <= main_data;
        if(sub_en)  sub_shadow <= {main_shadow[DW-1:8], subtractor_out};
    end
    
    // 8位借位减法器实现
    // borrow[0]是初始借位输入，设为0
    assign borrow[0] = 1'b0;
    
    // 逐位计算借位链和差值
    genvar i;
    generate
        for(i = 0; i < 8; i = i + 1) begin: borrow_subtractor
            assign subtractor_out[i] = main_shadow[i] ^ main_data[i] ^ borrow[i];
            assign borrow[i+1] = (~main_shadow[i] & main_data[i]) | 
                                (~main_shadow[i] & borrow[i]) | 
                                (main_data[i] & borrow[i]);
        end
    endgenerate
    
    assign final_data = sub_shadow;
endmodule