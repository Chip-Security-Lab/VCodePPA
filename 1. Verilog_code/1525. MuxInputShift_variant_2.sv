//SystemVerilog
// SystemVerilog - IEEE 1364-2005 Verilog standard
module MuxInputShift #(parameter W=4) (
    input clk,
    input [1:0] sel,
    input [W-1:0] d0, d1, d2, d3,
    input valid_in,
    output valid_out,
    output reg [W-1:0] q
);
    // 第一级流水线：选择输入信号
    reg [W-1:0] data_stage1;
    reg [1:0] sel_stage1;
    reg valid_stage1;
    
    // 第二级流水线：执行移位操作
    reg [W-1:0] q_stage2;
    reg valid_stage2;
    
    // 第一级流水线逻辑：选择输入
    always @(posedge clk) begin
        case (sel)
            2'b00: data_stage1 <= d0;
            2'b01: data_stage1 <= d1;
            2'b10: data_stage1 <= d2;
            2'b11: data_stage1 <= d3;
        endcase
        sel_stage1 <= sel;
        valid_stage1 <= valid_in;
    end
    
    // 第二级流水线逻辑：执行移位操作
    always @(posedge clk) begin
        case (sel_stage1)
            2'b00: q_stage2 <= {q[W-2:0], data_stage1[0]};
            2'b01: q_stage2 <= {q[W-2:0], data_stage1[0]};
            2'b10: q_stage2 <= {data_stage1, q[W-1:1]};
            2'b11: q_stage2 <= data_stage1;
        endcase
        valid_stage2 <= valid_stage1;
    end
    
    // 最终输出寄存器
    always @(posedge clk) begin
        q <= q_stage2;
    end
    
    // 输出有效信号
    assign valid_out = valid_stage2;
    
endmodule