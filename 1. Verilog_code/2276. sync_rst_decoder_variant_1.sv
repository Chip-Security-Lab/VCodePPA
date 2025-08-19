//SystemVerilog
// 顶层模块
module sync_rst_decoder(
    input clk,
    input rst,
    input [3:0] addr,
    output [15:0] select
);
    // 内部连线
    wire [3:0] addr_stage1;
    wire valid_stage1;
    wire [15:0] decoded_stage2;
    wire valid_stage2;
    
    // 实例化输入寄存阶段子模块
    input_stage input_proc (
        .clk(clk),
        .rst(rst),
        .addr_in(addr),
        .addr_out(addr_stage1),
        .valid_out(valid_stage1)
    );
    
    // 实例化解码阶段子模块
    decode_stage decode_proc (
        .clk(clk),
        .rst(rst),
        .addr_in(addr_stage1),
        .valid_in(valid_stage1),
        .decoded_out(decoded_stage2),
        .valid_out(valid_stage2)
    );
    
    // 实例化输出阶段子模块
    output_stage output_proc (
        .clk(clk),
        .rst(rst),
        .decoded_in(decoded_stage2),
        .valid_in(valid_stage2),
        .select(select)
    );
endmodule

// 输入处理子模块
module input_stage(
    input clk,
    input rst,
    input [3:0] addr_in,
    output reg [3:0] addr_out,
    output reg valid_out
);
    // 寄存输入并处理第一阶段
    always @(posedge clk) begin
        if (rst) begin
            addr_out <= 4'b0;
            valid_out <= 1'b0;
        end
        else begin
            addr_out <= addr_in;
            valid_out <= 1'b1;
        end
    end
endmodule

// 解码处理子模块
module decode_stage(
    input clk,
    input rst,
    input [3:0] addr_in,
    input valid_in,
    output reg [15:0] decoded_out,
    output reg valid_out
);
    // 解码逻辑和验证
    always @(posedge clk) begin
        if (rst) begin
            decoded_out <= 16'b0;
            valid_out <= 1'b0;
        end
        else begin
            if (valid_in) begin
                decoded_out <= (16'b1 << addr_in);
                valid_out <= valid_in;
            end
            else begin
                decoded_out <= 16'b0;
                valid_out <= 1'b0;
            end
        end
    end
endmodule

// 输出处理子模块
module output_stage(
    input clk,
    input rst,
    input [15:0] decoded_in,
    input valid_in,
    output reg [15:0] select
);
    // 输出阶段处理
    always @(posedge clk) begin
        if (rst) begin
            select <= 16'b0;
        end
        else begin
            if (valid_in) begin
                select <= decoded_in;
            end
        end
    end
endmodule