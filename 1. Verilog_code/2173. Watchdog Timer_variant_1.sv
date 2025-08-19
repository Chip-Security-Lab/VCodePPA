//SystemVerilog
module watchdog_timer #(parameter WIDTH = 24)(
    input clk_i, rst_ni, wdt_en_i, feed_i,
    input [WIDTH-1:0] timeout_i,
    output reg timeout_o
);
    reg [WIDTH-1:0] counter;
    reg feed_d;
    
    // 并行前缀减法器用于超时检测
    wire [WIDTH-1:0] time_remaining;
    wire timeout_detected;
    
    // 实例化并行前缀减法器
    parallel_prefix_subtractor #(.WIDTH(WIDTH)) subtractor_inst (
        .a(timeout_i),
        .b(counter),
        .difference(time_remaining),
        .borrow_out(timeout_detected)
    );
    
    always @(posedge clk_i) begin
        if (!rst_ni) begin 
            counter <= {WIDTH{1'b0}}; 
            timeout_o <= 1'b0;
            feed_d <= 1'b0;
        end
        else begin
            // 更新上一次feed信号的值
            feed_d <= feed_i;
            
            // 看门狗计数器逻辑
            if (wdt_en_i) begin
                if (feed_i & ~feed_d) // 使用内联边缘检测
                    counter <= {WIDTH{1'b0}};
                else 
                    counter <= counter + 1'b1;
                    
                // 使用并行前缀减法器的结果进行超时检测
                timeout_o <= timeout_detected | (time_remaining == {WIDTH{1'b0}});
            end
        end
    end
endmodule

// 并行前缀减法器模块
module parallel_prefix_subtractor #(parameter WIDTH = 8)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] difference,
    output borrow_out
);
    // 生成和传播信号
    wire [WIDTH-1:0] g, p;
    wire [WIDTH:0] borrow;
    
    // 初始借位为0
    assign borrow[0] = 1'b0;
    
    // 第一层: 生成初始生成(g)和传播(p)信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_gp
            assign g[i] = ~a[i] & b[i];
            assign p[i] = ~a[i] | b[i];
        end
    endgenerate
    
    // 第二层: 使用Kogge-Stone并行前缀算法计算借位
    // 这里实现8位并行前缀减法器，如果WIDTH>8，会需要更多的级联层
    generate
        if (WIDTH <= 8) begin : kogge_stone_8bit
            // 第一级: 2位组合
            wire [WIDTH-1:0] g1, p1;
            for (i = 0; i < WIDTH-1; i = i + 1) begin : level1
                assign g1[i] = g[i] | (p[i] & g[i+1]);
                assign p1[i] = p[i] & p[i+1];
            end
            assign g1[WIDTH-1] = g[WIDTH-1];
            assign p1[WIDTH-1] = p[WIDTH-1];
            
            // 第二级: 4位组合
            wire [WIDTH-1:0] g2, p2;
            for (i = 0; i < WIDTH-2; i = i + 1) begin : level2
                assign g2[i] = g1[i] | (p1[i] & g1[i+2]);
                assign p2[i] = p1[i] & p1[i+2];
            end
            for (i = WIDTH-2; i < WIDTH; i = i + 1) begin : level2_end
                assign g2[i] = g1[i];
                assign p2[i] = p1[i];
            end
            
            // 第三级: 8位组合
            wire [WIDTH-1:0] g3, p3;
            for (i = 0; i < WIDTH-4; i = i + 1) begin : level3
                assign g3[i] = g2[i] | (p2[i] & g2[i+4]);
                assign p3[i] = p2[i] & p2[i+4];
            end
            for (i = WIDTH-4; i < WIDTH; i = i + 1) begin : level3_end
                assign g3[i] = g2[i];
                assign p3[i] = p2[i];
            end
            
            // 计算最终借位
            for (i = 0; i < WIDTH; i = i + 1) begin : borrow_calc
                if (i == 0)
                    assign borrow[i+1] = g[i];
                else
                    assign borrow[i+1] = g3[i-1] | (p3[i-1] & borrow[0]);
            end
        end
    endgenerate
    
    // 计算差值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : diff_calc
            assign difference[i] = a[i] ^ b[i] ^ borrow[i];
        end
    endgenerate
    
    // 最终借位输出
    assign borrow_out = borrow[WIDTH];
endmodule