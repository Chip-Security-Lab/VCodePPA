module simon_light #(
    parameter ROUNDS = 44
)(
    input clk, load_key,
    input [63:0] block_in,
    input [127:0] key_in,
    output reg [63:0] block_out
);
    reg [63:0] key_schedule [0:ROUNDS-1];
    integer r;
    reg [31:0] left, right;
    reg [31:0] new_left;
    
    always @(posedge clk) begin
        if (load_key) begin
            key_schedule[0] <= key_in[63:0];
            for(r=1; r<ROUNDS; r=r+1) begin
                key_schedule[r][63:3] <= key_schedule[r-1][60:0];
                key_schedule[r][2:0] <= key_schedule[r-1][63:61] ^ 3'h5;
            end
        end else begin
            left = block_in[63:32];
            right = block_in[31:0];
            
            // 计算新的左半部分
            new_left = right ^ ((left << 1) | (left >> 31)) ^ key_schedule[0][31:0];
            
            // 更新输出
            block_out <= {right, new_left};
        end
    end
endmodule