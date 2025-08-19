module cam_async_reset #(parameter WIDTH=8, DEPTH=8)(
    input clk,
    input async_rst,
    input write_en,                      
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,        
    input [WIDTH-1:0] search_data,       
    output [DEPTH-1:0] match_lines       
);
    // CAM存储
    reg [WIDTH-1:0] cam_entries [0:DEPTH-1];
    
    // 异步复位逻辑
    integer i;
    always @(posedge clk or posedge async_rst) begin
        if(async_rst) begin
            // 复位所有条目
            for(i=0; i<DEPTH; i=i+1)
                cam_entries[i] <= {WIDTH{1'b0}};
        end else begin
            // 写入操作
            if (write_en) begin
                cam_entries[write_addr] <= write_data;
            end
        end
    end

    // 并行前缀加法器实现
    wire [WIDTH-1:0] P [0:DEPTH-1]; // 生成信号
    wire [WIDTH-1:0] G [0:DEPTH-1]; // 传播信号
    wire [WIDTH-1:0] S [0:DEPTH-1]; // 和信号

    // 生成和传播信号
    genvar j;
    generate
        for (j = 0; j < DEPTH; j = j + 1) begin : gen_pg
            assign P[j] = cam_entries[j] ^ search_data;
            assign G[j] = cam_entries[j] & search_data;
        end
    endgenerate

    // 计算和信号
    assign S[0] = P[0];
    assign match_lines[0] = G[0] | (P[0] & G[1]);
    
    generate
        for (j = 1; j < DEPTH; j = j + 1) begin : sum
            assign S[j] = P[j] ^ G[j-1];
            assign match_lines[j] = G[j] | (P[j] & G[j+1]);
        end
    endgenerate

    // 输出匹配线
    assign match_lines = match_lines;

endmodule