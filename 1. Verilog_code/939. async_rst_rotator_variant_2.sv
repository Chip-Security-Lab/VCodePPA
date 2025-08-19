//SystemVerilog
module async_rst_rotator (
    input clk, arst, en,
    input [7:0] data_in,
    input [2:0] shift,
    output reg [7:0] data_out
);
    // 将barrel shifter分解为两个级联阶段以减少关键路径
    reg [7:0] stage1_data;
    reg [7:0] stage2_data;
    
    // 第一阶段: 基于最低位处理0,1,2,3移位
    always @(*) begin
        case(shift[1:0])
            2'b00: stage1_data = data_in;
            2'b01: stage1_data = {data_in[6:0], data_in[7]};
            2'b10: stage1_data = {data_in[5:0], data_in[7:6]};
            2'b11: stage1_data = {data_in[4:0], data_in[7:5]};
        endcase
    end
    
    // 第二阶段: 基于高位处理0或4移位
    always @(*) begin
        if (shift[2])
            stage2_data = {stage1_data[3:0], stage1_data[7:4]};
        else
            stage2_data = stage1_data;
    end
    
    // 将数据寄存到输出寄存器
    always @(posedge clk or posedge arst) begin
        if (arst) 
            data_out <= 8'b0;
        else if (en)
            data_out <= stage2_data;
    end
endmodule