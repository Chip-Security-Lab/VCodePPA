//SystemVerilog
//IEEE 1364-2005 Verilog
module crossbar_bidir #(parameter DATA_WIDTH=8, parameter PORTS=4) (
    inout [PORTS*DATA_WIDTH-1:0] port, // 打平的数组
    input [PORTS*PORTS-1:0] connect_map // 打平的连接映射
);
    genvar i, j;
    wire [DATA_WIDTH-1:0] tri_state;
    assign tri_state = {DATA_WIDTH{1'bz}}; // 高阻态
    
    // 曼彻斯特进位链加法器相关信号
    reg [PORTS-1:0] connect_map_2d [0:PORTS-1];
    wire [DATA_WIDTH-1:0] port_data [0:PORTS-1];
    wire [DATA_WIDTH-1:0] port_out [0:PORTS-1];
    
    // 使用曼彻斯特进位链处理数组索引计算
    genvar idx;
    generate
        for(idx=0; idx<PORTS; idx=idx+1) begin: gen_port_mapping
            // 分解端口数据便于处理
            assign port_data[idx] = port[(idx*DATA_WIDTH) +: DATA_WIDTH];
            
            // 使用曼彻斯特进位链计算的结果连接到输出
            manchester_adder #(
                .WIDTH(DATA_WIDTH)
            ) index_adder (
                .a(idx * DATA_WIDTH),  // 基础索引
                .b(0),                 // 偏移量（这里为0，保持原索引）
                .sum(port[(idx*DATA_WIDTH) +: DATA_WIDTH])
            );
        end
    endgenerate
    
    // 将一维连接映射转为二维
    integer k, l;
    always @(*) begin
        k = 0;
        while (k < PORTS) begin
            l = 0;
            while (l < PORTS) begin
                connect_map_2d[k][l] = connect_map[k*PORTS+l];
                l = l + 1;
            end
            k = k + 1;
        end
    end

    // 生成端口互联逻辑
    generate
        for(i=0; i<PORTS; i=i+1) begin: gen_port
            for(j=0; j<PORTS; j=j+1) begin: gen_conn
                assign port[(i*DATA_WIDTH) +: DATA_WIDTH] = connect_map_2d[j][i] ? 
                            port[(j*DATA_WIDTH) +: DATA_WIDTH] : tri_state;
            end
        end
    endgenerate
endmodule

// 曼彻斯特进位链加法器模块
module manchester_adder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    wire [WIDTH-1:0] p; // 预处理信号
    wire [WIDTH-1:0] g; // 生成信号
    wire [WIDTH:0] c;   // 进位信号
    
    // 预处理阶段 - 生成传播和生成信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pg
            assign p[i] = a[i] ^ b[i]; // 传播信号
            assign g[i] = a[i] & b[i]; // 生成信号
        end
    endgenerate
    
    // 初始进位设为0
    assign c[0] = 1'b0;
    
    // 曼彻斯特进位链 - 计算每位的进位
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_carry
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate
    
    // 计算最终和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_sum
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
endmodule