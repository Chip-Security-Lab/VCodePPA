module ShiftSub(input [7:0] a, b, output reg [7:0] res);
    reg [7:0] b_comp;
    reg [7:0] temp_res;
    
    always @(*) begin
        b_comp = ~b + 1'b1;  // 计算b的补码
        temp_res = a;
        
        if(temp_res >= (b_comp<<0)) temp_res = temp_res - (b_comp<<0);
        if(temp_res >= (b_comp<<1)) temp_res = temp_res - (b_comp<<1);
        if(temp_res >= (b_comp<<2)) temp_res = temp_res - (b_comp<<2);
        if(temp_res >= (b_comp<<3)) temp_res = temp_res - (b_comp<<3);
        if(temp_res >= (b_comp<<4)) temp_res = temp_res - (b_comp<<4);
        if(temp_res >= (b_comp<<5)) temp_res = temp_res - (b_comp<<5);
        if(temp_res >= (b_comp<<6)) temp_res = temp_res - (b_comp<<6);
        if(temp_res >= (b_comp<<7)) temp_res = temp_res - (b_comp<<7);
        
        res = temp_res;
    end
endmodule