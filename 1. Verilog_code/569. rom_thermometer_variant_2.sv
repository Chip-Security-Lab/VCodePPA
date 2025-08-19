//SystemVerilog
// 顶层模块
module rom_thermometer #(parameter N=8)(
    input [2:0] val,
    output [N-1:0] code
);
    // 中间信号声明
    wire [2:0] encoded_val;
    
    // 实例化输入预处理模块
    input_preprocessor input_proc_inst (
        .raw_val(val),
        .processed_val(encoded_val)
    );
    
    // 实例化热码生成器模块
    thermometer_generator #(
        .WIDTH(N)
    ) thermo_gen_inst (
        .binary_val(encoded_val),
        .thermo_code(code)
    );
    
endmodule

// 输入预处理模块
module input_preprocessor (
    input [2:0] raw_val,
    output [2:0] processed_val
);
    // 进行输入的边界检查和优化处理
    // 在这个简单的例子中，直接传递，但保留了结构以便未来扩展
    assign processed_val = raw_val;
    
endmodule

// 热码生成器模块
module thermometer_generator #(
    parameter WIDTH = 8
)(
    input [2:0] binary_val,
    output reg [WIDTH-1:0] thermo_code
);
    // 使用并行前缀减法器算法实现热码生成
    wire [WIDTH:0] shifted_one;
    wire [WIDTH:0] p_gen, g_gen;
    wire [WIDTH:0] p_stage1, g_stage1;
    wire [WIDTH:0] p_stage2, g_stage2;
    wire [WIDTH:0] borrow;
    
    // 生成进位生成(Generate)和传播(Propagate)信号
    assign shifted_one = (1'b1 << binary_val);
    
    // 初始P和G信号生成 (P: Propagate, G: Generate)
    // 在减法中，G表示产生借位，P表示传播借位
    assign p_gen[0] = 1'b0;  // 初始无借位传播
    assign g_gen[0] = 1'b1;  // 初始有借位生成(减1操作)
    
    genvar i;
    generate
        for(i = 1; i <= WIDTH; i = i + 1) begin: gen_pg
            assign p_gen[i] = ~shifted_one[i-1]; // 当被减数位为0时传播借位
            assign g_gen[i] = 1'b0;              // 被减数各位不产生借位
        end
    endgenerate
    
    // 第一级并行前缀计算
    generate
        for(i = 0; i <= WIDTH; i = i + 2) begin: stage1
            if(i == 0) begin
                assign p_stage1[i] = p_gen[i];
                assign g_stage1[i] = g_gen[i];
            end else if(i == WIDTH && WIDTH % 2 == 0) begin
                assign p_stage1[i] = p_gen[i];
                assign g_stage1[i] = g_gen[i];
            end else begin
                assign p_stage1[i] = p_gen[i] & p_gen[i-1];
                assign g_stage1[i] = g_gen[i] | (p_gen[i] & g_gen[i-1]);
                
                if(i+1 <= WIDTH) begin
                    assign p_stage1[i+1] = p_gen[i+1];
                    assign g_stage1[i+1] = g_gen[i+1];
                end
            end
        end
    endgenerate
    
    // 第二级并行前缀计算
    generate
        for(i = 0; i <= WIDTH; i = i + 4) begin: stage2
            if(i == 0) begin
                assign p_stage2[i] = p_stage1[i];
                assign g_stage2[i] = g_stage1[i];
                
                if(i+1 <= WIDTH) begin
                    assign p_stage2[i+1] = p_stage1[i+1];
                    assign g_stage2[i+1] = g_stage1[i+1];
                end
                
                if(i+2 <= WIDTH) begin
                    assign p_stage2[i+2] = p_stage1[i+2] & p_stage1[i];
                    assign g_stage2[i+2] = g_stage1[i+2] | (p_stage1[i+2] & g_stage1[i]);
                end
                
                if(i+3 <= WIDTH) begin
                    assign p_stage2[i+3] = p_stage1[i+3] & p_stage1[i+1];
                    assign g_stage2[i+3] = g_stage1[i+3] | (p_stage1[i+3] & g_stage1[i+1]);
                end
            end else begin
                if(i <= WIDTH) begin
                    assign p_stage2[i] = p_stage1[i] & p_stage1[i-2];
                    assign g_stage2[i] = g_stage1[i] | (p_stage1[i] & g_stage1[i-2]);
                end
                
                if(i+1 <= WIDTH) begin
                    assign p_stage2[i+1] = p_stage1[i+1] & p_stage1[i-1];
                    assign g_stage2[i+1] = g_stage1[i+1] | (p_stage1[i+1] & g_stage1[i-1]);
                end
                
                if(i+2 <= WIDTH) begin
                    assign p_stage2[i+2] = p_stage1[i+2] & p_stage1[i-2];
                    assign g_stage2[i+2] = g_stage1[i+2] | (p_stage1[i+2] & g_stage1[i-2]);
                end
                
                if(i+3 <= WIDTH) begin
                    assign p_stage2[i+3] = p_stage1[i+3] & p_stage1[i-1];
                    assign g_stage2[i+3] = g_stage1[i+3] | (p_stage1[i+3] & g_stage1[i-1]);
                end
            end
        end
    endgenerate
    
    // 计算各位的借位
    assign borrow[0] = g_stage2[0];
    
    generate
        for(i = 1; i <= WIDTH; i = i + 1) begin: gen_borrow
            assign borrow[i] = g_stage2[i];
        end
    endgenerate
    
    // 生成热码输出
    always @(*) begin
        thermo_code = shifted_one[WIDTH-1:0] - {{(WIDTH-1){1'b0}}, 1'b1};
    end
    
endmodule