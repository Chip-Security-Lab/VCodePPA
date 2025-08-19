//SystemVerilog
// IEEE 1364-2005 Verilog
module P2S_Converter #(parameter WIDTH=8) (
    input clk, load,
    input [WIDTH-1:0] parallel_in,
    output reg serial_out
);
    // 流水线阶段寄存器
    reg [WIDTH-1:0] buffer_stage1;
    reg [WIDTH-1:0] buffer_stage2;
    reg [3:0] count_stage1;
    reg [3:0] count_stage2;
    reg load_stage1;
    reg valid_stage1;
    reg valid_stage2;
    reg serial_out_stage2;
    
    // 第一级流水线：加载和计数控制
    always @(posedge clk) begin
        case ({load, (count_stage1 > 0 || load_stage1)})
            2'b10, 2'b11: begin  // load = 1 (优先级更高)
                buffer_stage1 <= parallel_in;
                count_stage1 <= WIDTH-1;
                load_stage1 <= 1'b1;
                valid_stage1 <= 1'b1;
            end
            2'b01: begin  // load = 0, count_stage1 > 0 || load_stage1 = 1
                load_stage1 <= 1'b0;
                count_stage1 <= count_stage1 - 1;
                valid_stage1 <= 1'b1;
            end
            2'b00: begin  // load = 0, count_stage1 = 0, load_stage1 = 0
                valid_stage1 <= 1'b0;
            end
        endcase
    end
    
    // 第二级流水线：位选择和输出生成
    always @(posedge clk) begin
        buffer_stage2 <= buffer_stage1;
        count_stage2 <= count_stage1;
        valid_stage2 <= valid_stage1;
        
        if (valid_stage1) begin
            case (load_stage1)
                1'b1: serial_out_stage2 <= buffer_stage1[WIDTH-1];
                1'b0: serial_out_stage2 <= buffer_stage1[count_stage1];
            endcase
        end
    end
    
    // 第三级流水线：最终输出
    always @(posedge clk) begin
        case (valid_stage2)
            1'b1: serial_out <= serial_out_stage2;
            1'b0: serial_out <= serial_out;  // 保持原值
        endcase
    end
endmodule