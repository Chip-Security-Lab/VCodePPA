module cam_cache_bypass #(parameter WIDTH=16, DEPTH=128)(
    input clk,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] search_data,
    output reg hit,
    output reg [WIDTH-1:0] cache_out
);
    reg [WIDTH-1:0] cam_array [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] match_addr;
    reg found;
    
    // 条件反相减法器部分
    reg [7:0] sub_result;
    reg [7:0] a, b;
    reg cin;
    wire [7:0] b_inv;
    wire [7:0] adder_result;
    
    // 反相处理
    assign b_inv = ~b;
    
    // 加法器实现
    assign adder_result = a + b_inv + cin;
    
    // 写入逻辑保持同步时序
    always @(posedge clk) begin
        if (write_en)
            cam_array[write_addr] <= write_data;
    end
    
    // 优化搜索逻辑，使用条件反相减法器进行比较
    always @(*) begin
        found = 0;
        match_addr = 0;
        for(integer i=0; i<DEPTH; i=i+1) begin
            // 使用条件反相减法器进行比较
            a = cam_array[i][7:0];
            b = search_data[7:0];
            cin = 1'b1; // 补码减法中的进位输入
            sub_result = adder_result;
            
            if(sub_result == 8'b0 && cam_array[i][WIDTH-1:8] == search_data[WIDTH-1:8] && !found) begin
                found = 1;
                match_addr = i[$clog2(DEPTH)-1:0];
            end
        end
    end
    
    // 分离时序逻辑，减少关键路径延迟
    always @(posedge clk) begin
        hit <= found;
        cache_out <= found ? cam_array[match_addr] : {WIDTH{1'b0}};
    end
endmodule