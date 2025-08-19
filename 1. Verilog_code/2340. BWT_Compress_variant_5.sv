//SystemVerilog
module BWT_Compress #(parameter BLK=8) (
    input clk, en,
    input [BLK*8-1:0] data_in,
    output reg [BLK*8-1:0] data_out
);
    // 预注册输入数据
    reg [BLK*8-1:0] data_in_reg;
    always @(posedge clk) begin
        if (en) begin
            data_in_reg <= data_in;
        end
    end
    
    reg [7:0] buffer [0:BLK-1];
    reg [7:0] sorted [0:BLK-1];
    
    // 状态控制
    reg [2:0] state, next_state;
    localparam IDLE = 3'd0,
              EXTRACT = 3'd1,
              COPY = 3'd2,
              SORT = 3'd3,
              OUTPUT = 3'd4;
              
    reg [3:0] i, j, next_i, next_j;
    reg [7:0] temp;
    reg sort_done, next_sort_done;
    
    // 状态转换逻辑 - 组合逻辑部分
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: next_state = en ? EXTRACT : IDLE;
            EXTRACT: next_state = COPY;
            COPY: next_state = SORT;
            SORT: next_state = sort_done ? OUTPUT : SORT;
            OUTPUT: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 状态寄存器
    always @(posedge clk) begin
        if (!en)
            state <= IDLE;
        else
            state <= next_state;
    end

    // 提取数据到buffer - 将寄存器移到组合逻辑之后
    always @(posedge clk) begin
        if (en && state == EXTRACT) begin
            for (i = 0; i < BLK; i = i + 1)
                buffer[i] <= data_in_reg[i*8 +: 8];
        end
    end
    
    // 排序控制 - 组合逻辑部分
    always @(*) begin
        next_i = i;
        next_j = j;
        next_sort_done = sort_done;
        
        if (state == SORT && !sort_done) begin
            if (j < BLK - 1 - i) begin
                next_j = j + 1;
            end else begin
                next_j = 0;
                if (i < BLK - 1) begin
                    next_i = i + 1;
                end else begin
                    next_sort_done = 1;
                end
            end
        end
    end
    
    // 排序控制 - 寄存器部分
    always @(posedge clk) begin
        if (!en || state != SORT) begin
            i <= 0;
            j <= 0;
            sort_done <= 0;
        end else begin
            i <= next_i;
            j <= next_j;
            sort_done <= next_sort_done;
        end
    end
    
    // 复制到排序数组
    reg [7:0] next_sorted [0:BLK-1];
    
    // 对sorted数组的组合逻辑更新计算
    always @(*) begin
        for (i = 0; i < BLK; i = i + 1)
            next_sorted[i] = sorted[i];
            
        if (state == COPY) begin
            for (i = 0; i < BLK; i = i + 1)
                next_sorted[i] = buffer[i];
        end else if (state == SORT && !sort_done) begin
            if (sorted[j] > sorted[j+1]) begin
                next_sorted[j] = sorted[j+1];
                next_sorted[j+1] = sorted[j];
            end
        end
    end
    
    // 更新sorted寄存器
    always @(posedge clk) begin
        if (en && (state == COPY || (state == SORT && !sort_done))) begin
            for (i = 0; i < BLK; i = i + 1)
                sorted[i] <= next_sorted[i];
        end
    end
    
    // 输出组合逻辑
    reg [BLK*8-1:0] next_data_out;
    always @(*) begin
        next_data_out = data_out;
        if (state == OUTPUT) begin
            next_data_out[7:0] = sorted[BLK-1];
            for (i = 1; i < BLK; i = i + 1)
                next_data_out[i*8 +: 8] = sorted[i-1];
        end
    end
    
    // 组装输出数据
    always @(posedge clk) begin
        if (en && state == OUTPUT) begin
            data_out <= next_data_out;
        end
    end
    
endmodule