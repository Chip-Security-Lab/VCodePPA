//SystemVerilog - IEEE 1364-2005

// 顶层模块
module counter_bcd (
    input wire clk, rst, en,
    output wire [3:0] bcd,
    output wire carry
);
    // 内部连线
    wire [3:0] next_bcd_stage1;
    wire carry_stage1;
    wire valid_stage1;
    
    wire [3:0] next_bcd_stage2;
    wire carry_stage2;
    wire valid_stage2;
    
    // 实例化计算阶段子模块
    bcd_compute_stage compute_unit (
        .clk(clk),
        .rst(rst),
        .en(en),
        .current_bcd(bcd),
        .next_bcd(next_bcd_stage1),
        .carry_out(carry_stage1),
        .valid_out(valid_stage1)
    );
    
    // 实例化流水线寄存器子模块
    pipeline_register pipeline_reg (
        .clk(clk),
        .rst(rst),
        .bcd_in(next_bcd_stage1),
        .carry_in(carry_stage1),
        .valid_in(valid_stage1),
        .bcd_out(next_bcd_stage2),
        .carry_out(carry_stage2),
        .valid_out(valid_stage2)
    );
    
    // 实例化输出寄存器子模块
    output_register output_reg (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_stage2),
        .bcd_in(next_bcd_stage2),
        .carry_in(carry_stage2),
        .bcd_out(bcd),
        .carry_out(carry)
    );
endmodule

// 计算阶段子模块 - 负责BCD计数逻辑
module bcd_compute_stage (
    input wire clk,
    input wire rst,
    input wire en,
    input wire [3:0] current_bcd,
    output reg [3:0] next_bcd,
    output reg carry_out,
    output reg valid_out
);
    always @(posedge clk) begin
        if (rst) begin
            next_bcd <= 4'd0;
            carry_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= en;
            if (en) begin
                if (current_bcd == 4'd9) begin
                    next_bcd <= 4'd0;
                    carry_out <= 1'b1;
                end else begin
                    next_bcd <= current_bcd + 4'd1;
                    carry_out <= 1'b0;
                end
            end else begin
                next_bcd <= current_bcd;
                carry_out <= 1'b0;
            end
        end
    end
endmodule

// 流水线寄存器子模块 - 负责数据流水线传递
module pipeline_register (
    input wire clk,
    input wire rst,
    input wire [3:0] bcd_in,
    input wire carry_in,
    input wire valid_in,
    output reg [3:0] bcd_out,
    output reg carry_out,
    output reg valid_out
);
    always @(posedge clk) begin
        if (rst) begin
            bcd_out <= 4'd0;
            carry_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            bcd_out <= bcd_in;
            carry_out <= carry_in;
            valid_out <= valid_in;
        end
    end
endmodule

// 输出寄存器子模块 - 负责最终结果更新
module output_register (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [3:0] bcd_in,
    input wire carry_in,
    output reg [3:0] bcd_out,
    output reg carry_out
);
    always @(posedge clk) begin
        if (rst) begin
            bcd_out <= 4'd0;
            carry_out <= 1'b0;
        end else if (valid_in) begin
            bcd_out <= bcd_in;
            carry_out <= carry_in;
        end
    end
endmodule