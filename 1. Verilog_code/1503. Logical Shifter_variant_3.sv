//SystemVerilog
// IEEE 1364-2005
module logical_shifter #(parameter W = 16) (
    input wire clock, reset_n, load, shift,
    input wire [W-1:0] data,
    output wire [W-1:0] q_out
);
    reg [W-1:0] q_reg;
    wire [W-1:0] shift_result;
    
    // 使用并行前缀结构实现逻辑右移
    parallel_prefix_shifter #(.WIDTH(W)) ppshifter (
        .data_in(q_reg),
        .shift_result(shift_result)
    );
    
    // 复位逻辑独立处理
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            q_reg <= {W{1'b0}};
    end
    
    // 数据加载逻辑独立处理
    always @(posedge clock) begin
        if (reset_n && load)
            q_reg <= data;
    end
    
    // 移位逻辑独立处理
    always @(posedge clock) begin
        if (reset_n && shift && !load)
            q_reg <= shift_result;
    end
    
    assign q_out = q_reg;
endmodule

// 并行前缀移位器实现
module parallel_prefix_shifter #(parameter WIDTH = 16) (
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] shift_result
);
    // 生成逻辑右移的各级信号
    wire [WIDTH-1:0] level0, level1;
    
    // 第一级移位 - 产生初始结果
    assign level0 = {1'b0, data_in[WIDTH-1:1]};
    
    // 并行前缀结构优化实现
    genvar i;
    generate
        if (WIDTH >= 8) begin
            // 前4位处理
            assign level1[3:0] = level0[3:0];
            
            // 中间部分并行处理
            for (i = 4; i < WIDTH-4; i=i+1) begin
                assign level1[i] = level0[i];
            end
            
            // 后4位处理
            if (WIDTH > 8) begin
                assign level1[WIDTH-1:WIDTH-4] = level0[WIDTH-1:WIDTH-4];
            end else begin
                assign level1[7:4] = level0[7:4];
            end
            
            assign shift_result = level1;
        end else begin
            assign shift_result = level0;
        end
    endgenerate
endmodule