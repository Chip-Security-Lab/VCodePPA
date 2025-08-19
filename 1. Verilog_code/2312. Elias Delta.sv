// log2函数定义
function integer clog2;
    input integer value;
    begin
        value = value - 1;
        for (clog2 = 0; value > 0; clog2 = clog2 + 1) begin
            value = value >> 1;
        end
    end
endfunction

module elias_delta_codec #(
    parameter MAX_WIDTH = 16
)(
    input                    encode_en,
    input  [MAX_WIDTH-1:0]   value_in,
    output [2*MAX_WIDTH-1:0] code_out,
    output [5:0] code_len
);
    wire [4:0] N; // Length of value in bits
    wire [4:0] L; // Length of N in bits
    
    // Find length of value (bit position of MSB + 1)
    assign N = value_in[15] ? 16 :
               value_in[14] ? 15 :
               value_in[13] ? 14 :
               value_in[12] ? 13 :
               value_in[11] ? 12 :
               value_in[10] ? 11 :
               value_in[9] ? 10 :
               value_in[8] ? 9 :
               value_in[7] ? 8 :
               value_in[6] ? 7 :
               value_in[5] ? 6 :
               value_in[4] ? 5 :
               value_in[3] ? 4 :
               value_in[2] ? 3 :
               value_in[1] ? 2 : 
               value_in[0] ? 1 : 0;
               
    // Find length of N
    assign L = N[4] ? 5 :
               N[3] ? 4 :
               N[2] ? 3 :
               N[1] ? 2 : 1;
    
    // 组合逻辑生成code_out
    reg [2*MAX_WIDTH-1:0] temp_code;
    reg [5:0] temp_len;
    integer i;
    
    always @(*) begin
        temp_code = 0;
        
        if (encode_en) begin
            // 添加gamma(N)部分
            for (i = 0; i < L-1; i = i + 1)
                temp_code[2*MAX_WIDTH-1-i] = 1;
            
            temp_code[2*MAX_WIDTH-L] = 0;
            
            // 添加N[L-2:0]部分
            for (i = 0; i < L-1; i = i + 1)
                if (i < L-1)
                    temp_code[2*MAX_WIDTH-L-1-i] = N[L-2-i];
            
            // 添加value_in[N-2:0]部分
            for (i = 0; i < N-1; i = i + 1)
                temp_code[2*MAX_WIDTH-L-(L-1)-1-i] = value_in[N-2-i];
                
            temp_len = 2*L - 1 + N - 1;
        end else begin
            temp_code = 0;
            temp_len = 0;
        end
    end
    
    assign code_out = temp_code;
    assign code_len = temp_len;
endmodule