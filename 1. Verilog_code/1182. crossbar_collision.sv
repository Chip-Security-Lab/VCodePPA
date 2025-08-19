module crossbar_collision #(parameter DW=8, parameter N=4) (
    input clk, rst,
    input [N-1:0] valid,
    input [N*DW-1:0] din, // 打平的数组
    output reg [N*DW-1:0] dout, // 打平的数组
    output reg [N-1:0] collision
);
    // 目标映射(使用低2位作为目标地址)
    wire [1:0] dest_addr [0:N-1];
    reg [N-1:0] dest_count [0:N-1];
    integer i, j;
    reg finish_flag;
    
    // 提取目标地址
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin: gen_dest_addr
            assign dest_addr[g] = din[(g*DW) +: 2];
        end
    endgenerate
    
    // 检测冲突并路由数据
    always @(posedge clk or negedge rst) begin
        if(rst) begin
            for(i=0; i<N; i=i+1) begin
                dout[(i*DW) +: DW] <= 0;
                collision[i] <= 0;
                for(j=0; j<N; j=j+1) begin
                    dest_count[i][j] <= 0;
                end
            end
        end else begin
            // 初始化目标计数
            for (i = 0; i < N; i = i + 1) begin
                for(j=0; j<N; j=j+1) begin
                    dest_count[i][j] <= 0;
                end
                dout[(i*DW) +: DW] <= 0;
                collision[i] <= 0;
            end
            
            // 统计每个目标的请求数
            for (i = 0; i < N; i = i + 1) begin
                if (valid[i]) begin
                    dest_count[dest_addr[i]][dest_addr[i]] <= dest_count[dest_addr[i]][dest_addr[i]] + 1;
                end
            end
            
            // 检查冲突并路由数据
            for (i = 0; i < N; i = i + 1) begin
                if(dest_count[i][i] > 1)
                    collision[i] <= 1'b1;
                else
                    collision[i] <= 1'b0;
                
                // 路由来自第一个有效输入的数据到此目标
                finish_flag = 0;
                for (j = 0; j < N; j = j + 1) begin
                    if (valid[j] && (dest_addr[j] == i) && !finish_flag) begin
                        dout[(i*DW) +: DW] <= din[(j*DW) +: DW];
                        finish_flag = 1;
                    end
                end
            end
        end
    end
endmodule