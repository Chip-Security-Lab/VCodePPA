module cam_1 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] data_in,
    output reg match_flag,
    output reg [7:0] store_data
);
    // 流水線階段寄存器
    reg [7:0] data_in_stage1;
    reg write_en_stage1;
    reg is_match_stage1;
    reg [7:0] store_data_stage1;
    
    // 流水線控制信號
    reg valid_stage1;
    
    // 階段1：數據輸入寄存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_stage1 <= 8'b0;
            write_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            store_data_stage1 <= 8'b0;
        end else begin
            data_in_stage1 <= data_in;
            write_en_stage1 <= write_en;
            valid_stage1 <= 1'b1;  // 每個時鐘週期處理一個新輸入
            store_data_stage1 <= store_data;
        end
    end
    
    // 階段1：比較計算
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            is_match_stage1 <= 1'b0;
        end else begin
            is_match_stage1 <= (store_data_stage1 == data_in_stage1);
        end
    end
    
    // 階段2：更新存儲數據和匹配標誌
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            store_data <= 8'b0;
            match_flag <= 1'b0;
        end else if (valid_stage1) begin
            if (write_en_stage1) begin
                store_data <= data_in_stage1;
                match_flag <= 1'b0;
            end else begin
                match_flag <= is_match_stage1;
            end
        end
    end
endmodule