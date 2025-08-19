//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module sync_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] subtract_value,
    input wire capture,
    input wire perform_subtract,
    output reg [WIDTH-1:0] shadow_data
);
    // Primary register
    reg [WIDTH-1:0] primary_reg;
    wire [WIDTH-1:0] subtraction_result;
    
    // 优化的减法器实现
    optimized_subtractor #(
        .WIDTH(WIDTH)
    ) subtractor (
        .a(primary_reg),
        .b(subtract_value),
        .diff(subtraction_result)
    );
    
    // Primary register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            primary_reg <= {WIDTH{1'b0}};
        else
            primary_reg <= data_in;
    end
    
    // Shadow register update with subtraction capability
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= {WIDTH{1'b0}};
        else if (capture) begin
            shadow_data <= perform_subtract ? subtraction_result : primary_reg;
        end
    end
endmodule

// 优化的减法器模块，采用高效的Kogge-Stone并行前缀结构
module optimized_subtractor #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] diff
);
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] p, g;
    
    // 使用直接减法实现而非补码变换
    assign carry[0] = 1'b1; // 初始进位设为1
    
    // 生成传播(p)和生成(g)信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg
            assign p[i] = a[i] ^ ~b[i];
            assign g[i] = a[i] & ~b[i];
        end
    endgenerate
    
    // Kogge-Stone并行前缀网络 - 对数级深度
    // 优化层次，减少逻辑门数量
    localparam LEVELS = $clog2(WIDTH);
    wire [WIDTH-1:0] gtemp [LEVELS:0];
    wire [WIDTH-1:0] ptemp [LEVELS:0];
    
    // 初始化
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : init_prefix
            assign gtemp[0][i] = g[i];
            assign ptemp[0][i] = p[i];
        end
    endgenerate
    
    // 计算前缀 - Kogge-Stone模式
    generate
        genvar l, j;
        for (l = 0; l < LEVELS; l = l + 1) begin : prefix_levels
            for (j = 0; j < WIDTH; j = j + 1) begin : prefix_positions
                if (j >= (1 << l)) begin
                    assign gtemp[l+1][j] = gtemp[l][j] | (ptemp[l][j] & gtemp[l][j-(1<<l)]);
                    assign ptemp[l+1][j] = ptemp[l][j] & ptemp[l][j-(1<<l)];
                end else begin
                    assign gtemp[l+1][j] = gtemp[l][j];
                    assign ptemp[l+1][j] = ptemp[l][j];
                end
            end
        end
    endgenerate
    
    // 计算进位
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry
            assign carry[i+1] = gtemp[LEVELS][i] | (ptemp[LEVELS][i] & carry[0]);
        end
    endgenerate
    
    // 计算差值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_diff
            assign diff[i] = p[i] ^ carry[i];
        end
    endgenerate
endmodule