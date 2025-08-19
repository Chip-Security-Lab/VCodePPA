//SystemVerilog
module sync_variable_fill_shifter (
    input                clk,
    input                rst,
    input      [7:0]     data_in,
    input      [2:0]     shift_val,
    input                shift_dir,  // 0: left, 1: right
    input                fill_bit,   // Value to fill vacant positions
    output reg [7:0]     data_out
);
    // 优化的移位逻辑
    reg [7:0] shifted;
    
    // 创建填充位掩码
    reg [7:0] fill_mask;
    
    always @(*) begin
        // 根据移位值生成填充位掩码
        case (shift_val)
            3'd0: fill_mask = 8'h00;
            3'd1: fill_mask = 8'h01;
            3'd2: fill_mask = 8'h03;
            3'd3: fill_mask = 8'h07;
            3'd4: fill_mask = 8'h0F;
            3'd5: fill_mask = 8'h1F;
            3'd6: fill_mask = 8'h3F;
            3'd7: fill_mask = 8'h7F;
            default: fill_mask = 8'h00;
        endcase
        
        // 条件合并，优化分支结构
        if (shift_dir) begin  // 右移
            shifted = data_in >> shift_val;
            if (fill_bit)
                shifted = shifted | (fill_mask << (8 - shift_val));
        end else begin        // 左移
            shifted = data_in << shift_val;
            if (fill_bit)
                shifted = shifted | fill_mask;
        end
    end
    
    // 寄存输出
    always @(posedge clk or posedge rst) begin
        if (rst) 
            data_out <= 8'h00;
        else 
            data_out <= shifted;
    end
endmodule