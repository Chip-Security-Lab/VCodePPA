//SystemVerilog
module priority_range_detector(
    input wire clk, rst_n,
    input wire [15:0] value,
    input wire [15:0] range_start [0:3],
    input wire [15:0] range_end [0:3],
    output reg [2:0] range_id,
    output reg valid
);
    reg [3:0] in_range;
    reg [2:0] detected_id;
    reg detection_valid;
    reg [15:0] value_reg;
    reg [15:0] range_start_reg [0:3];
    reg [15:0] range_end_reg [0:3];
    
    integer i;
    
    // 输入寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            value_reg <= 16'd0;
            for (i = 0; i < 4; i = i + 1) begin
                range_start_reg[i] <= 16'd0;
                range_end_reg[i] <= 16'd0;
            end
        end
        else begin
            value_reg <= value;
            for (i = 0; i < 4; i = i + 1) begin
                range_start_reg[i] <= range_start[i];
                range_end_reg[i] <= range_end[i];
            end
        end
    end
    
    // 比较级
    reg [3:0] in_range_temp;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_range <= 4'b0;
            in_range_temp <= 4'b0;
        end
        else begin
            for (i = 0; i < 4; i = i + 1) begin
                in_range_temp[i] <= (value_reg >= range_start_reg[i]) && (value_reg <= range_end_reg[i]);
            end
            in_range <= in_range_temp;
        end
    end
    
    // 优先级编码级
    reg [2:0] detected_id_temp;
    reg detection_valid_temp;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detected_id <= 3'd0;
            detection_valid <= 1'b0;
            detected_id_temp <= 3'd0;
            detection_valid_temp <= 1'b0;
        end
        else begin
            detection_valid_temp <= |in_range;
            
            if (in_range[0]) detected_id_temp <= 3'd0;
            else if (in_range[1]) detected_id_temp <= 3'd1;
            else if (in_range[2]) detected_id_temp <= 3'd2;
            else if (in_range[3]) detected_id_temp <= 3'd3;
            else detected_id_temp <= detected_id_temp;
            
            detected_id <= detected_id_temp;
            detection_valid <= detection_valid_temp;
        end
    end
    
    // 输出寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            range_id <= 3'd0;
            valid <= 1'b0;
        end
        else begin
            range_id <= detected_id;
            valid <= detection_valid;
        end
    end
endmodule