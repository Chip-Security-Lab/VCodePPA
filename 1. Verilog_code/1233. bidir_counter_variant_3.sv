//SystemVerilog
module bidir_counter #(parameter N = 8) (
    input wire clock, clear, load, up_down,
    input wire [N-1:0] data_in,
    output reg [N-1:0] count
);
    reg [N-1:0] next_count;
    reg clear_reg, load_reg, up_down_reg;
    reg [N-1:0] data_in_reg;
    
    // 减法器查找表 - 存储常见的减法结果
    reg [N-1:0] sub_lut [0:15];
    
    // 初始化查找表
    initial begin
        sub_lut[0] = 8'hFF;  // 0-1
        sub_lut[1] = 8'hFE;  // 1-1
        sub_lut[2] = 8'h01;  // 2-1
        sub_lut[3] = 8'h02;  // 3-1
        sub_lut[4] = 8'h03;  // 4-1
        sub_lut[5] = 8'h04;  // 5-1
        sub_lut[6] = 8'h05;  // 6-1
        sub_lut[7] = 8'h06;  // 7-1
        sub_lut[8] = 8'h07;  // 8-1
        sub_lut[9] = 8'h08;  // 9-1
        sub_lut[10] = 8'h09; // 10-1
        sub_lut[11] = 8'h0A; // 11-1
        sub_lut[12] = 8'h0B; // 12-1
        sub_lut[13] = 8'h0C; // 13-1
        sub_lut[14] = 8'h0D; // 14-1
        sub_lut[15] = 8'h0E; // 15-1
    end
    
    // 输入寄存器 - 将寄存器前移到输入端
    always @(posedge clock) begin
        clear_reg <= clear;
        load_reg <= load;
        up_down_reg <= up_down;
        data_in_reg <= data_in;
    end
    
    wire use_lut;
    wire [3:0] lut_index;
    
    // 判断是否可以使用查找表
    assign use_lut = !up_down_reg && (count[7:4] == 4'h0) && (count[3:0] < 4'h10);
    assign lut_index = count[3:0];
    
    // 计算下一个计数值的组合逻辑
    always @(*) begin
        if (clear_reg)
            next_count = {N{1'b0}};
        else if (load_reg)
            next_count = data_in_reg;
        else if (up_down_reg)
            next_count = count + 1'b1;
        else if (use_lut)
            next_count = sub_lut[lut_index];
        else
            next_count = count - 1'b1;
    end
    
    // 输出寄存器
    always @(posedge clock) begin
        count <= next_count;
    end
endmodule