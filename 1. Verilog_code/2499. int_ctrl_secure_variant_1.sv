//SystemVerilog
module int_ctrl_secure #(
    parameter DOMAINS = 2
)(
    input clk, rst,
    input [DOMAINS-1:0] domain_en,
    input [15:0] intr_vec,
    output reg [3:0] secure_grant
);
    // 寄存器化输入
    reg [DOMAINS-1:0] domain_en_reg;
    reg [15:0] intr_vec_reg;
    
    always @(posedge clk) begin
        domain_en_reg <= domain_en;
        intr_vec_reg <= intr_vec;
    end
    
    // 使用寄存器化的输入计算mask
    wire domain_active;
    wire [15:0] domain_mask;
    wire [15:0] masked_intr;
    
    // 使用if-else结构替代条件运算符
    assign domain_active = |domain_en_reg;
    
    // 使用if-else代替条件运算符结构
    reg [15:0] domain_mask_reg;
    always @(*) begin
        if (domain_active)
            domain_mask_reg = 16'hFFFF;
        else
            domain_mask_reg = 16'h0000;
    end
    
    assign domain_mask = domain_mask_reg;
    assign masked_intr = intr_vec_reg & domain_mask;
    
    // 编码器函数 - 使用if-else替代casez
    function [3:0] priority_encoder;
        input [15:0] value;
        begin
            if (value[15]) 
                priority_encoder = 4'd15;
            else if (value[14]) 
                priority_encoder = 4'd14;
            else if (value[13]) 
                priority_encoder = 4'd13;
            else if (value[12]) 
                priority_encoder = 4'd12;
            else if (value[11]) 
                priority_encoder = 4'd11;
            else if (value[10]) 
                priority_encoder = 4'd10;
            else if (value[9]) 
                priority_encoder = 4'd9;
            else if (value[8]) 
                priority_encoder = 4'd8;
            else if (value[7]) 
                priority_encoder = 4'd7;
            else if (value[6]) 
                priority_encoder = 4'd6;
            else if (value[5]) 
                priority_encoder = 4'd5;
            else if (value[4]) 
                priority_encoder = 4'd4;
            else if (value[3]) 
                priority_encoder = 4'd3;
            else if (value[2]) 
                priority_encoder = 4'd2;
            else if (value[1]) 
                priority_encoder = 4'd1;
            else if (value[0]) 
                priority_encoder = 4'd0;
            else 
                priority_encoder = 4'd0;
        end
    endfunction
    
    // 输出寄存器
    always @(posedge clk) begin
        if (rst) begin
            secure_grant <= 4'b0;
        end else begin
            secure_grant <= priority_encoder(masked_intr);
        end
    end
endmodule