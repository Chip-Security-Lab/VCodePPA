//SystemVerilog
//IEEE 1364-2005 Verilog标准
module crossbar_bidir #(
    parameter DATA_WIDTH = 8,
    parameter PORTS = 4
) (
    input wire clk,                         // 添加时钟信号用于流水线寄存器
    input wire rst_n,                       // 添加复位信号
    inout wire [PORTS*DATA_WIDTH-1:0] port, // 双向端口
    input wire [PORTS*PORTS-1:0] connect_map // 连接映射
);
    // 常量定义
    wire [DATA_WIDTH-1:0] TRI_STATE;
    assign TRI_STATE = {DATA_WIDTH{1'bz}}; // 高阻态
    
    // ====== 第一级流水线：连接映射解码 ======
    reg [PORTS-1:0] connect_map_stage1 [0:PORTS-1];
    wire [PORTS-1:0] connect_map_2d [0:PORTS-1];
    
    // 将1维连接映射转换为2维结构以提高可读性
    genvar i, j;
    generate
        for(i=0; i<PORTS; i=i+1) begin: map_decoder
            for(j=0; j<PORTS; j=j+1) begin: map_entry
                assign connect_map_2d[i][j] = connect_map[i*PORTS+j];
            end
        end
    endgenerate
    
    // 寄存器化连接映射信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k=0; k<PORTS; k=k+1) begin
                connect_map_stage1[k] <= {PORTS{1'b0}};
            end
        end else begin
            for (int k=0; k<PORTS; k=k+1) begin
                connect_map_stage1[k] <= connect_map_2d[k];
            end
        end
    end
    
    // ====== 第二级流水线：输入数据捕获 ======
    wire [DATA_WIDTH-1:0] port_input [0:PORTS-1];
    reg [DATA_WIDTH-1:0] port_input_stage2 [0:PORTS-1];
    
    // 从双向端口中提取输入数据
    generate
        for(i=0; i<PORTS; i=i+1) begin: input_extractor
            assign port_input[i] = port[(i*DATA_WIDTH) +: DATA_WIDTH];
        end
    endgenerate
    
    // 寄存器化输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k=0; k<PORTS; k=k+1) begin
                port_input_stage2[k] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            for (int k=0; k<PORTS; k=k+1) begin
                port_input_stage2[k] <= port_input[k];
            end
        end
    end
    
    // ====== 第三级流水线：路由矩阵计算 ======
    wire [DATA_WIDTH-1:0] route_matrix [0:PORTS-1][0:PORTS-1];
    reg [DATA_WIDTH-1:0] route_matrix_stage3 [0:PORTS-1][0:PORTS-1];
    
    // 数据路由矩阵计算
    generate
        for(i=0; i<PORTS; i=i+1) begin: route_matrix_row
            for(j=0; j<PORTS; j=j+1) begin: route_matrix_col
                // 当连接映射为1时，选择对应的输入数据；否则为高阻态
                assign route_matrix[i][j] = connect_map_stage1[j][i] ? port_input_stage2[j] : TRI_STATE;
            end
        end
    endgenerate
    
    // 寄存器化路由矩阵
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int r=0; r<PORTS; r=r+1) begin
                for (int c=0; c<PORTS; c=c+1) begin
                    route_matrix_stage3[r][c] <= {DATA_WIDTH{1'b0}};
                end
            end
        end else begin
            for (int r=0; r<PORTS; r=r+1) begin
                for (int c=0; c<PORTS; c=c+1) begin
                    route_matrix_stage3[r][c] <= route_matrix[r][c];
                end
            end
        end
    end
    
    // ====== 第四级流水线：输出汇聚和驱动 ======
    wire [DATA_WIDTH-1:0] output_data [0:PORTS-1];
    reg [DATA_WIDTH-1:0] output_data_stage4 [0:PORTS-1];
    
    // 使用分层归约树结构汇聚数据
    generate
        for(i=0; i<PORTS; i=i+1) begin: output_merger
            // 第一级归约：将PORTS路数据分为两组进行或运算
            wire [DATA_WIDTH-1:0] merge_level1 [0:1];
            assign merge_level1[0] = route_matrix_stage3[i][0] | route_matrix_stage3[i][1];
            assign merge_level1[1] = route_matrix_stage3[i][2] | route_matrix_stage3[i][3];
            
            // 第二级归约：合并两组结果
            assign output_data[i] = merge_level1[0] | merge_level1[1];
        end
    endgenerate
    
    // 寄存器化输出数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k=0; k<PORTS; k=k+1) begin
                output_data_stage4[k] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            for (int k=0; k<PORTS; k=k+1) begin
                output_data_stage4[k] <= output_data[k];
            end
        end
    end
    
    // ====== 输出驱动 ======
    // 通过双向端口驱动输出数据
    generate
        for(i=0; i<PORTS; i=i+1) begin: output_driver
            assign port[(i*DATA_WIDTH) +: DATA_WIDTH] = output_data_stage4[i];
        end
    endgenerate
    
endmodule