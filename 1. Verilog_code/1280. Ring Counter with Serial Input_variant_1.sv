//SystemVerilog
module serial_in_ring_counter(
    input wire clk,
    input wire rst,
    input wire ser_in,
    input wire valid_in,
    output reg valid_out,
    output reg [3:0] count
);
    // 流水线寄存器
    reg ser_in_stage1, ser_in_stage2;
    reg [2:0] count_part_stage1;
    reg [2:0] count_part_stage2;
    reg valid_stage1, valid_stage2;
    
    // 阶段1：接收输入并处理第一部分数据
    always @(posedge clk) begin
        if (rst) begin
            ser_in_stage1 <= 1'b0;
            count_part_stage1 <= 3'b001;
            valid_stage1 <= 1'b0;
        end
        else if (valid_in) begin
            ser_in_stage1 <= ser_in;
            count_part_stage1 <= count[2:0];
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 阶段2：处理后半部分
    always @(posedge clk) begin
        if (rst) begin
            ser_in_stage2 <= 1'b0;
            count_part_stage2 <= 3'b001;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            ser_in_stage2 <= ser_in_stage1;
            count_part_stage2 <= count_part_stage1;
            valid_stage2 <= valid_stage1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 输出阶段：组合最终输出
    always @(posedge clk) begin
        if (rst) begin
            count <= 4'b0001;
            valid_out <= 1'b0;
        end
        else if (valid_stage2) begin
            count <= {count_part_stage2, ser_in_stage2};
            valid_out <= 1'b1;
        end
        else begin
            valid_out <= 1'b0;
        end
    end
endmodule