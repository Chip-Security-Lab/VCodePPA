//SystemVerilog
//IEEE 1364-2005 Verilog standard
module crossbar_collision #(
    parameter DW = 8,
    parameter N = 4
)(
    input wire clk,
    input wire rst,
    input wire [N-1:0] valid,
    input wire [N*DW-1:0] din,  // 打平的数组
    output reg [N*DW-1:0] dout, // 打平的数组
    output reg [N-1:0] collision
);
    // 分阶段寄存器声明
    reg [N-1:0] valid_s1;
    reg [N*DW-1:0] din_s1;
    
    // 提取目标地址 - 分离为独立信号以提高可读性
    wire [1:0] dest_addr [0:N-1];
    reg [1:0] dest_addr_s1 [0:N-1];
    
    // 冲突检测和路由控制信号
    reg [N-1:0] dest_req_count [0:N-1];
    reg [N-1:0] route_grant;
    reg [N-1:0] route_select [0:N-1];
    
    // 数据流水线第二阶段信号
    reg [N*DW-1:0] routed_data;
    
    // 提取目标地址 - 确保清晰的第一阶段数据路径
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin: gen_dest_addr
            assign dest_addr[g] = din[(g*DW) +: 2];
        end
    endgenerate
    
    // 流水线第一阶段 - 输入寄存
    integer i, j;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            valid_s1 <= {N{1'b0}};
            din_s1 <= {(N*DW){1'b0}};
            for (i = 0; i < N; i = i + 1) begin
                dest_addr_s1[i] <= 2'b00;
            end
        end else begin
            valid_s1 <= valid;
            din_s1 <= din;
            for (i = 0; i < N; i = i + 1) begin
                dest_addr_s1[i] <= dest_addr[i];
            end
        end
    end
    
    // 流水线第二阶段 - 冲突检测逻辑
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    dest_req_count[i][j] <= 1'b0;
                end
                route_grant[i] <= 1'b0;
                for (j = 0; j < N; j = j + 1) begin
                    route_select[i][j] <= 1'b0;
                end
            end
            collision <= {N{1'b0}};
            routed_data <= {(N*DW){1'b0}};
        end else begin
            // 初始化计数器和路由控制信号
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    dest_req_count[i][j] <= 1'b0;
                end
                route_grant[i] <= 1'b0;
                for (j = 0; j < N; j = j + 1) begin
                    route_select[i][j] <= 1'b0;
                end
            end
            
            // 统计目标请求，分离冲突检测逻辑和路由决策
            for (i = 0; i < N; i = i + 1) begin
                if (valid_s1[i]) begin
                    dest_req_count[dest_addr_s1[i]][dest_addr_s1[i]] <= 
                        dest_req_count[dest_addr_s1[i]][dest_addr_s1[i]] + 1'b1;
                end
            end
            
            // 冲突检测
            for (i = 0; i < N; i = i + 1) begin
                collision[i] <= (dest_req_count[i][i] > 1) ? 1'b1 : 1'b0;
            end
            
            // 路由授权 - 为每个目标选择第一个请求
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    if (valid_s1[j] && (dest_addr_s1[j] == i) && !route_grant[i]) begin
                        route_select[i][j] <= 1'b1;
                        route_grant[i] <= 1'b1;
                    end
                end
            end
            
            // 准备路由数据
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    if (route_select[i][j]) begin
                        routed_data[(i*DW) +: DW] <= din_s1[(j*DW) +: DW];
                    end
                end
            end
        end
    end
    
    // 流水线第三阶段 - 输出寄存
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            dout <= {(N*DW){1'b0}};
        end else begin
            dout <= routed_data;
        end
    end
    
endmodule