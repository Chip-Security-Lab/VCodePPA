module cam_pipelined #(parameter WIDTH=8, DEPTH=16)(
    input clk,
    input rst_n,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] match_flags
);

    // CAM存储单元
    reg [WIDTH-1:0] cam_table [0:DEPTH-1];
    
    // 流水线寄存器
    reg [WIDTH-1:0] data_in_stage1;
    reg [WIDTH-1:0] data_in_stage2;
    reg [DEPTH-1:0] match_flags_stage1;
    reg [DEPTH-1:0] match_flags_stage2;
    reg valid_stage1;
    reg valid_stage2;
    
    // 写入逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < DEPTH; i = i + 1)
                cam_table[i] <= {WIDTH{1'b0}};
        end else if (write_en)
            cam_table[write_addr] <= write_data;
    end
    
    // Stage 1: 输入数据寄存和比较
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= {WIDTH{1'b0}};
            match_flags_stage1 <= {DEPTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            for (integer i = 0; i < DEPTH; i = i + 1)
                match_flags_stage1[i] <= (cam_table[i] == data_in);
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: 中间结果寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage2 <= {WIDTH{1'b0}};
            match_flags_stage2 <= {DEPTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            match_flags_stage2 <= match_flags_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match_flags <= {DEPTH{1'b0}};
        else if (valid_stage2)
            match_flags <= match_flags_stage2;
    end

endmodule