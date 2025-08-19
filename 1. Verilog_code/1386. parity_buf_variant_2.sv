//SystemVerilog
// 顶层模块
module parity_buf #(parameter DW=9) (
    input clk,
    input rst_n,
    input en,
    input [DW-2:0] data_in,
    output [DW-1:0] data_out,
    output valid_out
);
    // 阶段间的连接信号
    wire [DW-2:0] data_stage1;
    wire parity_stage1;
    wire valid_stage1;
    
    wire [DW-1:0] data_stage2;
    wire valid_stage2;
    
    // 实例化第一级流水线模块 - 校验位计算
    parity_buf_stage1 #(
        .DW(DW)
    ) stage1_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .data_in(data_in),
        .data_out(data_stage1),
        .parity_out(parity_stage1),
        .valid_out(valid_stage1)
    );
    
    // 实例化第二级流水线模块 - 数据组合
    parity_buf_stage2 #(
        .DW(DW)
    ) stage2_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_stage1),
        .data_in(data_stage1),
        .parity_in(parity_stage1),
        .data_out(data_stage2),
        .valid_out(valid_stage2)
    );
    
    // 实例化输出级模块
    parity_buf_output #(
        .DW(DW)
    ) output_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_stage2),
        .valid_in(valid_stage2),
        .data_out(data_out),
        .valid_out(valid_out)
    );
endmodule

// 第一级流水线模块 - 计算校验位
module parity_buf_stage1 #(parameter DW=9) (
    input clk,
    input rst_n,
    input en,
    input [DW-2:0] data_in,
    output reg [DW-2:0] data_out,
    output reg parity_out,
    output reg valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {(DW-1){1'b0}};
            parity_out <= 1'b0;
            valid_out <= 1'b0;
        end else if (en) begin
            data_out <= data_in;
            parity_out <= ^data_in;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule

// 第二级流水线模块 - 组合数据
module parity_buf_stage2 #(parameter DW=9) (
    input clk,
    input rst_n,
    input valid_in,
    input [DW-2:0] data_in,
    input parity_in,
    output reg [DW-1:0] data_out,
    output reg valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else if (valid_in) begin
            data_out <= {parity_in, data_in};
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule

// 输出级模块
module parity_buf_output #(parameter DW=9) (
    input clk,
    input rst_n,
    input [DW-1:0] data_in,
    input valid_in,
    output reg [DW-1:0] data_out,
    output reg valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else begin
            data_out <= data_in;
            valid_out <= valid_in;
        end
    end
endmodule