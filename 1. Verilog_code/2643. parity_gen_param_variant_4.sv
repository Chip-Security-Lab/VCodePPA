//SystemVerilog
// 顶层模块
module parity_gen_param #(
    parameter WIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [WIDTH-1:0] data,
    output reg parity
);

    // 内部信号定义
    wire [WIDTH-1:0] filtered_data;
    wire raw_parity;
    wire valid_parity;
    
    // 数据预处理子模块
    data_preprocessor #(
        .WIDTH(WIDTH)
    ) u_data_preprocessor (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .data_in(data),
        .data_out(filtered_data)
    );

    // 校验位计算子模块
    parity_core #(
        .WIDTH(WIDTH)
    ) u_parity_core (
        .clk(clk),
        .rst_n(rst_n),
        .data(filtered_data),
        .parity(raw_parity)
    );

    // 输出控制子模块
    output_controller u_output_controller (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .raw_parity(raw_parity),
        .valid_parity(valid_parity)
    );

    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            parity <= 1'b0;
        else
            parity <= valid_parity;
    end

endmodule

// 数据预处理子模块
module data_preprocessor #(
    parameter WIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

    // 数据同步和过滤
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {WIDTH{1'b0}};
        else if (en)
            data_out <= data_in;
        else
            data_out <= {WIDTH{1'b0}};
    end

endmodule

// 校验位计算子模块
module parity_core #(
    parameter WIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data,
    output reg parity
);

    // 流水线化奇偶校验计算
    reg [WIDTH/2-1:0] stage1;
    reg [WIDTH/4-1:0] stage2;
    reg [WIDTH/8-1:0] stage3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1 <= {(WIDTH/2){1'b0}};
            stage2 <= {(WIDTH/4){1'b0}};
            stage3 <= {(WIDTH/8){1'b0}};
            parity <= 1'b0;
        end
        else begin
            // 第一级流水线
            for (int i = 0; i < WIDTH/2; i++)
                stage1[i] <= data[2*i] ^ data[2*i+1];
                
            // 第二级流水线
            for (int i = 0; i < WIDTH/4; i++)
                stage2[i] <= stage1[2*i] ^ stage1[2*i+1];
                
            // 第三级流水线
            for (int i = 0; i < WIDTH/8; i++)
                stage3[i] <= stage2[2*i] ^ stage2[2*i+1];
                
            // 最终校验位
            parity <= ^stage3;
        end
    end

endmodule

// 输出控制子模块
module output_controller (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire raw_parity,
    output reg valid_parity
);

    // 输出控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_parity <= 1'b0;
        else
            valid_parity <= en ? raw_parity : 1'b0;
    end

endmodule