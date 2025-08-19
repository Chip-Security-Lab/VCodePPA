//SystemVerilog

// 顶层模块
module prefix_subtractor_top #(parameter WIDTH=8)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);
    wire [WIDTH-1:0] p; // 传播信号
    wire [WIDTH-1:0] g; // 生成信号
    wire [WIDTH:0] c;   // 进位信号

    // 实例化生成和传播信号模块
    generate_and_propagate #(WIDTH) g_p_inst (
        .a(a),
        .b(b),
        .g(g),
        .p(p)
    );

    // 实例化进位生成模块
    carry_generator #(WIDTH) carry_inst (
        .g(g),
        .p(p),
        .c(c)
    );

    // 实例化结果计算模块
    result_calculator #(WIDTH) result_inst (
        .a(a),
        .b(b),
        .c(c),
        .result(result)
    );

endmodule

// 生成和传播信号模块
module generate_and_propagate #(parameter WIDTH=8)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] g,
    output [WIDTH-1:0] p
);
    assign g = a & ~b; // 生成信号
    assign p = a | ~b; // 传播信号
endmodule

// 进位生成模块
module carry_generator #(parameter WIDTH=8)(
    input [WIDTH-1:0] g,
    input [WIDTH-1:0] p,
    output [WIDTH:0] c
);
    assign c[0] = 1'b0; // 初始进位为0
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : carry_gen
            assign c[i + 1] = g[i] | (p[i] & c[i]);
        end
    endgenerate
endmodule

// 结果计算模块
module result_calculator #(parameter WIDTH=8)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [WIDTH:0] c,
    output [WIDTH-1:0] result
);
    assign result = a ^ b ^ c[WIDTH-1:0]; // 结果为a、b和进位的异或
endmodule

// 异步ROM模块
module rom_async #(parameter DATA=16, ADDR=8)(
    input [ADDR-1:0] a,
    output [DATA-1:0] dout
);
    // 声明存储器
    reg [DATA-1:0] mem [(1<<ADDR)-1:0];
    
    // 读取操作
    assign dout = mem[a];
    
    // 初始化内容 - 直接在代码中初始化部分内容
    initial begin
        // 示例初始化，实际使用时应替换为具体值
        mem[0] = 16'h1234;
        mem[1] = 16'h5678;
        mem[2] = 16'h9ABC;
        mem[3] = 16'hDEF0;
        // 为简化，仅初始化部分内容
        // $readmemh("init_data.hex", mem); // 仿真中使用
    end
endmodule