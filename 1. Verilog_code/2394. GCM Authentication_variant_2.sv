//SystemVerilog
// 顶层模块
module gcm_auth #(parameter WIDTH = 32) (
    input wire clk, reset_l,
    input wire data_valid, last_block,
    input wire [WIDTH-1:0] data_in, h_key,
    output wire [WIDTH-1:0] auth_tag,
    output wire tag_valid
);
    // 内部信号连接
    wire [WIDTH-1:0] mixed_data;
    wire [WIDTH-1:0] accumulated;
    wire process_data;
    wire finalize_tag;

    // 控制单元
    gcm_control_unit u_control (
        .clk(clk),
        .reset_l(reset_l),
        .data_valid(data_valid),
        .last_block(last_block),
        .process_data(process_data),
        .finalize_tag(finalize_tag)
    );

    // 数据处理单元
    gcm_data_processor #(.WIDTH(WIDTH)) u_data_proc (
        .clk(clk),
        .reset_l(reset_l),
        .data_valid(data_valid),
        .data_in(data_in),
        .accumulated(accumulated),
        .mixed_data(mixed_data)
    );

    // GF乘法累加单元
    gcm_gf_accumulator #(.WIDTH(WIDTH)) u_accumulator (
        .clk(clk),
        .reset_l(reset_l),
        .process_data(process_data),
        .mixed_data(mixed_data),
        .h_key(h_key),
        .accumulated(accumulated)
    );

    // 输出生成单元
    gcm_output_generator #(.WIDTH(WIDTH)) u_output_gen (
        .clk(clk),
        .reset_l(reset_l),
        .finalize_tag(finalize_tag),
        .mixed_data(mixed_data),
        .auth_tag(auth_tag),
        .tag_valid(tag_valid)
    );
endmodule

// 控制单元模块
module gcm_control_unit (
    input wire clk, reset_l,
    input wire data_valid, last_block,
    output reg process_data,
    output reg finalize_tag
);
    // 控制逻辑 - 检测输入状态并产生控制信号
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            process_data <= 1'b0;
            finalize_tag <= 1'b0;
        end else begin
            process_data <= data_valid;
            finalize_tag <= data_valid & last_block;
        end
    end
endmodule

// 数据处理单元模块
module gcm_data_processor #(parameter WIDTH = 32) (
    input wire clk, reset_l,
    input wire data_valid,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] accumulated,
    output reg [WIDTH-1:0] mixed_data
);
    // 数据预处理 - 混合输入数据和累加值
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            mixed_data <= {WIDTH{1'b0}};
        end else if (data_valid) begin
            mixed_data <= accumulated ^ data_in;
        end
    end
endmodule

// GF乘法累加单元模块
module gcm_gf_accumulator #(parameter WIDTH = 32) (
    input wire clk, reset_l,
    input wire process_data,
    input wire [WIDTH-1:0] mixed_data, h_key,
    output reg [WIDTH-1:0] accumulated
);
    // GF(2^128) multiplication (simplified for this example)
    function [WIDTH-1:0] gf_mult(input [WIDTH-1:0] a, b);
        reg [WIDTH-1:0] res;
        reg carry;
        integer i, j;
        begin
            res = 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (a[i]) res = res ^ (b << i);
            end
            // Reduction step (simplified)
            for (j = WIDTH*2-1; j >= WIDTH; j = j - 1) begin
                if (res[j]) res = res ^ (32'h87000000 << (j - WIDTH));
            end
            gf_mult = res;
        end
    endfunction

    // 累加计算 - 执行GF乘法并更新累加值
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            accumulated <= {WIDTH{1'b0}};
        end else if (process_data) begin
            accumulated <= gf_mult(mixed_data, h_key);
        end
    end
endmodule

// 输出生成单元模块
module gcm_output_generator #(parameter WIDTH = 32) (
    input wire clk, reset_l,
    input wire finalize_tag,
    input wire [WIDTH-1:0] mixed_data,
    output reg [WIDTH-1:0] auth_tag,
    output reg tag_valid
);
    // 输出生成 - 产生认证标签和有效信号
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            auth_tag <= {WIDTH{1'b0}};
            tag_valid <= 1'b0;
        end else begin
            // 只在最后一个块时设置认证标签
            if (finalize_tag) begin
                auth_tag <= mixed_data;
            end
            // 标签有效信号
            tag_valid <= finalize_tag;
        end
    end
endmodule