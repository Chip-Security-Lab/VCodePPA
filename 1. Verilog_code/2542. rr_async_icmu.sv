module rr_async_icmu (
    input rst,
    input [7:0] interrupt_in,
    input ctx_save_done,
    output reg [7:0] int_grant,
    output reg [2:0] int_vector,
    output reg context_save_req
);
    reg [2:0] last_served;
    reg [7:0] masked_ints;
    
    // 重构组合逻辑
    always @(*) begin
        masked_ints = interrupt_in;
        context_save_req = |masked_ints;
        
        // 使用调用函数而不是复杂赋值
        int_grant = select_next(masked_ints, last_served);
        int_vector = encode_vec(int_grant);
    end
    
    always @(posedge ctx_save_done or posedge rst) begin
        if (rst) last_served <= 3'b0;
        else last_served <= int_vector;
    end
    
    // 修改函数实现
    function [7:0] select_next;
        input [7:0] ints; 
        input [2:0] last;
        reg [7:0] mask, high_result, any_result;
        integer i;
        begin
            mask = 0;
            high_result = 0;
            any_result = 0;
            
            // 创建掩码
            for (i = 0; i < 8; i = i + 1) begin
                if (i > last) mask[i] = 1'b1;
            end
            
            // 查找高于last的中断
            for (i = 7; i >= 0; i = i - 1) begin
                if (ints[i] && mask[i]) high_result[i] = 1'b1;
            end
            
            // 查找所有中断
            for (i = 7; i >= 0; i = i - 1) begin
                if (ints[i]) any_result[i] = 1'b1;
            end
            
            // 选择结果
            if (|high_result) 
                select_next = high_result;
            else
                select_next = any_result;
        end
    endfunction
    
    function [2:0] encode_vec;
        input [7:0] grant; 
        begin
            casez(grant)
                8'b???????1: encode_vec = 3'd0;
                8'b??????10: encode_vec = 3'd1;
                8'b?????100: encode_vec = 3'd2;
                8'b????1000: encode_vec = 3'd3;
                8'b???10000: encode_vec = 3'd4;
                8'b??100000: encode_vec = 3'd5;
                8'b?1000000: encode_vec = 3'd6;
                8'b10000000: encode_vec = 3'd7;
                default: encode_vec = 3'd0;
            endcase
        end
    endfunction
    
    function [2:0] find_first;
        input [7:0] val; 
        begin
            casez(val)
                8'b???????1: find_first = 3'd0;
                8'b??????10: find_first = 3'd1;
                8'b?????100: find_first = 3'd2;
                8'b????1000: find_first = 3'd3;
                8'b???10000: find_first = 3'd4;
                8'b??100000: find_first = 3'd5;
                8'b?1000000: find_first = 3'd6;
                8'b10000000: find_first = 3'd7;
                default: find_first = 3'd0;
            endcase
        end
    endfunction
endmodule