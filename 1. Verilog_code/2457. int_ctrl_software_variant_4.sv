//SystemVerilog
module int_ctrl_software #(parameter WIDTH=8)(
    input clk, wr_en,
    input [WIDTH-1:0] sw_int,
    output reg [WIDTH-1:0] int_out
);
    // 注册输入信号，将寄存器前移
    reg wr_en_reg;
    reg [WIDTH-1:0] sw_int_reg;
    
    // 寄存器前移到输入端
    always @(posedge clk) begin
        wr_en_reg <= wr_en;
        sw_int_reg <= sw_int;
    end
    
    wire [WIDTH-1:0] subtractor_result;
    wire [WIDTH:0] borrow;
    
    // 使用寄存后的输入信号进行计算
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: borrow_gen
            // 简化借位逻辑，移除冗余项
            assign borrow[i+1] = (~sw_int_reg[i] & borrow[i]);
            
            // 计算结果位 - 简化XOR操作，因为我们与0相XOR
            assign subtractor_result[i] = sw_int_reg[i] ^ borrow[i];
        end
    endgenerate
    
    // 使用寄存后的wr_en控制信号
    always @(posedge clk) begin
        if(wr_en_reg) 
            int_out <= subtractor_result;
        else 
            int_out <= {WIDTH{1'b0}};
    end
endmodule