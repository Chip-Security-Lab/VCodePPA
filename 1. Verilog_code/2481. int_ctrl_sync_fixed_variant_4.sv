//SystemVerilog
module int_ctrl_sync_fixed #(
    parameter WIDTH = 8
)(
    input clk, rst_n, en,
    input [WIDTH-1:0] req,
    output reg [$clog2(WIDTH)-1:0] grant
);
    // 将req转换为独热码编码的grant信号
    reg [WIDTH-1:0] req_r;
    wire [$clog2(WIDTH)-1:0] grant_next;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            grant <= {$clog2(WIDTH){1'b0}};
        else if(en) 
            grant <= grant_next;
    end
    
    // 使用case语句，基于req的优先级编码
    always @(*) begin
        req_r = req;
    end
    
    // 组合逻辑使用case语句实现优先编码器
    reg [WIDTH-1:0] highest_bit;
    
    always @(*) begin
        highest_bit = {WIDTH{1'b0}};
        casez(req)
            {1'b1, {WIDTH-1{1'bz}}}: highest_bit[WIDTH-1] = 1'b1;
            {1'b0, 1'b1, {WIDTH-2{1'bz}}}: highest_bit[WIDTH-2] = 1'b1;
            {2'b00, 1'b1, {WIDTH-3{1'bz}}}: highest_bit[WIDTH-3] = 1'b1;
            {3'b000, 1'b1, {WIDTH-4{1'bz}}}: highest_bit[WIDTH-4] = 1'b1;
            {4'b0000, 1'b1, {WIDTH-5{1'bz}}}: highest_bit[WIDTH-5] = 1'b1;
            {5'b00000, 1'b1, {WIDTH-6{1'bz}}}: highest_bit[WIDTH-6] = 1'b1;
            {6'b000000, 1'b1, {WIDTH-7{1'bz}}}: highest_bit[WIDTH-7] = 1'b1;
            {7'b0000000, 1'b1}: highest_bit[0] = 1'b1;
            default: highest_bit = {WIDTH{1'b0}};
        endcase
    end
    
    // 从独热码转换为二进制编码 - 使用if-else结构替代条件运算符
    reg [$clog2(WIDTH)-1:0] encoded_grant;
    
    always @(*) begin
        if (highest_bit == {WIDTH{1'b0}}) begin
            encoded_grant = {$clog2(WIDTH){1'b0}};
        end
        else if (highest_bit[7]) begin
            encoded_grant = 3'd7;
        end
        else if (highest_bit[6]) begin
            encoded_grant = 3'd6;
        end
        else if (highest_bit[5]) begin
            encoded_grant = 3'd5;
        end
        else if (highest_bit[4]) begin
            encoded_grant = 3'd4;
        end
        else if (highest_bit[3]) begin
            encoded_grant = 3'd3;
        end
        else if (highest_bit[2]) begin
            encoded_grant = 3'd2;
        end
        else if (highest_bit[1]) begin
            encoded_grant = 3'd1;
        end
        else if (highest_bit[0]) begin
            encoded_grant = 3'd0;
        end
        else begin
            encoded_grant = {$clog2(WIDTH){1'b0}};
        end
    end
    
    assign grant_next = encoded_grant;
                    
endmodule