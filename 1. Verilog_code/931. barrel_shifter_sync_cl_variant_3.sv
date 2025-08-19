//SystemVerilog
module barrel_shifter_sync_cl (
    input clk, rst_n, en,
    input [7:0] data_in,
    input [2:0] shift_amount,
    output reg [7:0] data_out
);
    // 为data_in添加缓冲寄存器，减少扇出负载
    reg [7:0] data_in_buf1, data_in_buf2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_buf1 <= 8'b0;
            data_in_buf2 <= 8'b0;
        end else begin
            data_in_buf1 <= data_in;
            data_in_buf2 <= data_in;
        end
    end
    
    // 分割组合逻辑，减少关键路径延迟
    reg [7:0] partial_shift1, partial_shift2;
    
    // 第一组移位操作使用data_in_buf1
    always @(*) begin
        case (shift_amount)
            3'd0: partial_shift1 = data_in_buf1;
            3'd1: partial_shift1 = {data_in_buf1[6:0], data_in_buf1[7]};
            3'd2: partial_shift1 = {data_in_buf1[5:0], data_in_buf1[7:6]};
            3'd3: partial_shift1 = {data_in_buf1[4:0], data_in_buf1[7:5]};
            default: partial_shift1 = 8'b0;
        endcase
    end
    
    // 第二组移位操作使用data_in_buf2
    always @(*) begin
        case (shift_amount)
            3'd4: partial_shift2 = {data_in_buf2[3:0], data_in_buf2[7:4]};
            3'd5: partial_shift2 = {data_in_buf2[2:0], data_in_buf2[7:3]};
            3'd6: partial_shift2 = {data_in_buf2[1:0], data_in_buf2[7:2]};
            3'd7: partial_shift2 = {data_in_buf2[0], data_in_buf2[7:1]};
            default: partial_shift2 = 8'b0;
        endcase
    end
    
    // 组合两组结果得到最终shifted_data
    reg [7:0] shifted_data;
    always @(*) begin
        if (shift_amount < 4)
            shifted_data = partial_shift1;
        else
            shifted_data = partial_shift2;
    end
    
    // 为shifted_data添加缓冲寄存器，避免高扇出
    reg [7:0] shifted_data_buf;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shifted_data_buf <= 8'b0;
        else
            shifted_data_buf <= shifted_data;
    end
    
    // 输出寄存器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'b0;
        else if (en)
            data_out <= shifted_data_buf;
    end
endmodule