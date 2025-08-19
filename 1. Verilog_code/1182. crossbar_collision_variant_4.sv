//SystemVerilog
module crossbar_collision #(parameter DW=8, parameter N=4) (
    input clk, rst,
    input [N-1:0] valid,
    input [N*DW-1:0] din, // 打平的数组
    output reg [N*DW-1:0] dout, // 打平的数组
    output reg [N-1:0] collision
);
    // 目标映射(使用低2位作为目标地址)
    wire [1:0] dest_addr [0:N-1];
    reg [N-1:0] valid_reg;
    reg [N*DW-1:0] din_reg;
    
    // 为每个可能的输入/输出组合创建预计算的数据路由寄存器
    reg [DW-1:0] pre_routed_data [0:N-1][0:N-1];
    reg [N-1:0] route_valid [0:N-1];
    reg [N-1:0] collision_pre;
    
    integer i, j;
    
    // 提取目标地址
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin: gen_dest_addr
            assign dest_addr[g] = din[(g*DW) +: 2];
        end
    endgenerate
    
    // 寄存输入数据和有效信号
    always @(posedge clk or negedge rst) begin
        if(~rst) begin
            din_reg <= 0;
            valid_reg <= 0;
        end else begin
            din_reg <= din;
            valid_reg <= valid;
        end
    end
    
    // 后向重定时：在数据源处预先计算冲突检测和路由决策
    always @(posedge clk or negedge rst) begin
        if(~rst) begin
            for(i = 0; i < N; i = i + 1) begin
                for(j = 0; j < N; j = j + 1) begin
                    pre_routed_data[i][j] <= 0;
                end
                route_valid[i] <= 0;
                collision_pre[i] <= 0;
            end
        end else begin
            // 计算每个目标的请求数并预检测冲突
            for(i = 0; i < N; i = i + 1) begin
                // 统计每个目标请求数并检测冲突
                collision_pre[i] <= (
                    (valid[0] && dest_addr[0] == i ? 1'b1 : 1'b0) +
                    (valid[1] && dest_addr[1] == i ? 1'b1 : 1'b0) +
                    (valid[2] && dest_addr[2] == i ? 1'b1 : 1'b0) +
                    (valid[3] && dest_addr[3] == i ? 1'b1 : 1'b0)
                ) > 1;
                
                // 预路由数据 - 将组合逻辑移到寄存器前
                // 为每个目标预先计算路由
                route_valid[i] <= 0;
                
                if (valid[0] && (dest_addr[0] == i) && 
                    !(valid[1] && (dest_addr[1] == i)) && 
                    !(valid[2] && (dest_addr[2] == i)) && 
                    !(valid[3] && (dest_addr[3] == i))) begin
                    pre_routed_data[0][i] <= din[(0*DW) +: DW];
                    route_valid[i][0] <= 1'b1;
                end else begin
                    pre_routed_data[0][i] <= 0;
                    route_valid[i][0] <= 1'b0;
                end
                
                if (valid[1] && (dest_addr[1] == i) && 
                    !(valid[0] && (dest_addr[0] == i)) && 
                    !(valid[2] && (dest_addr[2] == i)) && 
                    !(valid[3] && (dest_addr[3] == i))) begin
                    pre_routed_data[1][i] <= din[(1*DW) +: DW];
                    route_valid[i][1] <= 1'b1;
                end else begin
                    pre_routed_data[1][i] <= 0;
                    route_valid[i][1] <= 1'b0;
                end
                
                if (valid[2] && (dest_addr[2] == i) && 
                    !(valid[0] && (dest_addr[0] == i)) && 
                    !(valid[1] && (dest_addr[1] == i)) && 
                    !(valid[3] && (dest_addr[3] == i))) begin
                    pre_routed_data[2][i] <= din[(2*DW) +: DW];
                    route_valid[i][2] <= 1'b1;
                end else begin
                    pre_routed_data[2][i] <= 0;
                    route_valid[i][2] <= 1'b0;
                end
                
                if (valid[3] && (dest_addr[3] == i) && 
                    !(valid[0] && (dest_addr[0] == i)) && 
                    !(valid[1] && (dest_addr[1] == i)) && 
                    !(valid[2] && (dest_addr[2] == i))) begin
                    pre_routed_data[3][i] <= din[(3*DW) +: DW];
                    route_valid[i][3] <= 1'b1;
                end else begin
                    pre_routed_data[3][i] <= 0;
                    route_valid[i][3] <= 1'b0;
                end
            end
        end
    end
    
    // 简化输出级 - 只需选择预计算的数据
    always @(posedge clk or negedge rst) begin
        if(~rst) begin
            for(i = 0; i < N; i = i + 1) begin
                dout[(i*DW) +: DW] <= 0;
                collision[i] <= 0;
            end
        end else begin
            // 冲突标志直接从预计算结果获取
            collision <= collision_pre;
            
            // 输出路由 - 使用预计算的数据
            for(i = 0; i < N; i = i + 1) begin
                dout[(i*DW) +: DW] <= 0; // 默认值
                
                // 选择预路由数据
                for(j = 0; j < N; j = j + 1) begin
                    if(route_valid[i][j]) begin
                        dout[(i*DW) +: DW] <= pre_routed_data[j][i];
                    end
                end
            end
        end
    end
endmodule