//SystemVerilog
module sync_controlled_bidir_shifter (
    input                  clock,
    input                  resetn,
    input      [31:0]      data_in,
    input      [4:0]       shift_amount,
    input      [1:0]       mode,  // 00:left logical, 01:right logical
                                  // 10:left rotate, 11:right rotate
    input                  valid_in,  // 发送方数据有效信号
    output                 ready_out, // 接收方准备好接收信号
    output reg [31:0]      data_out,
    output reg             valid_out  // 输出数据有效信号
);
    // 内部信号
    reg [31:0] shift_stage1, shift_stage2;
    reg [31:0] temp_result;
    reg processing;  // 用于跟踪当前是否正在处理数据
    
    // 当模块未处理数据时准备好接收新数据
    assign ready_out = !processing;
    
    // 流水线级实现移位操作
    always @(*) begin
        case(mode)
            2'b00: begin // 左逻辑移位
                if (shift_amount[4]) shift_stage1 = data_in << 16;
                else shift_stage1 = data_in;
                
                if (shift_amount[3]) shift_stage2 = shift_stage1 << 8;
                else shift_stage2 = shift_stage1;
                
                if (shift_amount[2]) temp_result = shift_stage2 << 4;
                else temp_result = shift_stage2;
                
                if (shift_amount[1]) temp_result = temp_result << 2;
                if (shift_amount[0]) temp_result = temp_result << 1;
            end
            
            2'b01: begin // 右逻辑移位
                if (shift_amount[4]) shift_stage1 = data_in >> 16;
                else shift_stage1 = data_in;
                
                if (shift_amount[3]) shift_stage2 = shift_stage1 >> 8;
                else shift_stage2 = shift_stage1;
                
                if (shift_amount[2]) temp_result = shift_stage2 >> 4;
                else temp_result = shift_stage2;
                
                if (shift_amount[1]) temp_result = temp_result >> 2;
                if (shift_amount[0]) temp_result = temp_result >> 1;
            end
            
            2'b10: begin // 左旋转
                reg [63:0] double_data;
                double_data = {data_in, data_in};
                
                if (shift_amount[4]) shift_stage1 = double_data >> (32 - 16);
                else shift_stage1 = data_in;
                
                if (shift_amount[3]) shift_stage2 = {shift_stage1, shift_stage1} >> (32 - 8);
                else shift_stage2 = shift_stage1;
                
                double_data = {shift_stage2, shift_stage2};
                
                if (shift_amount[2]) temp_result = double_data >> (32 - 4);
                else temp_result = shift_stage2;
                
                if (shift_amount[1]) temp_result = {temp_result, temp_result} >> (32 - 2);
                if (shift_amount[0]) temp_result = {temp_result, temp_result} >> (32 - 1);
                temp_result = temp_result[31:0];
            end
            
            2'b11: begin // 右旋转
                reg [63:0] double_data;
                double_data = {data_in, data_in};
                
                if (shift_amount[4]) shift_stage1 = double_data >> 16;
                else shift_stage1 = data_in;
                
                if (shift_amount[3]) shift_stage2 = {shift_stage1, shift_stage1} >> 8;
                else shift_stage2 = shift_stage1;
                
                double_data = {shift_stage2, shift_stage2};
                
                if (shift_amount[2]) temp_result = double_data >> 4;
                else temp_result = shift_stage2;
                
                if (shift_amount[1]) temp_result = {temp_result, temp_result} >> 2;
                if (shift_amount[0]) temp_result = {temp_result, temp_result} >> 1;
                temp_result = temp_result[31:0];
            end
        endcase
    end
    
    // 状态控制与输出寄存
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            data_out <= 32'h0;
            valid_out <= 1'b0;
            processing <= 1'b0;
        end
        else begin
            // 握手逻辑处理
            if (valid_in && ready_out) begin
                // 接收到有效数据且准备好接收时，开始处理
                processing <= 1'b1;
                data_out <= temp_result;
                valid_out <= 1'b1;
            end 
            else if (valid_out) begin
                // 当前数据已发送完成
                valid_out <= 1'b0;
                processing <= 1'b0;
            end
        end
    end
endmodule