//SystemVerilog
// 顶层模块
module neg_edge_shifter #(parameter LENGTH = 6) (
    input wire neg_clk,
    input wire d_in,
    input wire rstn,
    output wire [LENGTH-1:0] q_out
);
    // 内部连线
    wire [7:0] subtract_result;
    wire borrow_out;
    wire [7:0] counter_a, counter_b;

    // 子模块实例化
    shift_register #(
        .LENGTH(LENGTH)
    ) shift_reg_inst (
        .neg_clk(neg_clk),
        .d_in(d_in),
        .rstn(rstn),
        .q_out(q_out)
    );

    counter_unit counter_inst (
        .neg_clk(neg_clk),
        .d_in(d_in),
        .rstn(rstn),
        .subtract_result(subtract_result),
        .counter_a(counter_a),
        .counter_b(counter_b)
    );

    subtractor subtract_inst (
        .counter_a(counter_a),
        .counter_b(counter_b),
        .subtract_result(subtract_result),
        .borrow_out(borrow_out)
    );
endmodule

// 移位寄存器子模块
module shift_register #(parameter LENGTH = 6) (
    input wire neg_clk,
    input wire d_in,
    input wire rstn,
    output wire [LENGTH-1:0] q_out
);
    reg [LENGTH-1:0] shift_reg;

    always @(negedge neg_clk or negedge rstn) begin
        if (!rstn) begin
            shift_reg <= {LENGTH{1'b0}};
        end else begin
            // 移位寄存器功能
            shift_reg <= {d_in, shift_reg[LENGTH-1:1]};
        end
    end

    assign q_out = shift_reg;
endmodule

// 计数器子模块
module counter_unit (
    input wire neg_clk,
    input wire d_in,
    input wire rstn,
    input wire [7:0] subtract_result,
    output reg [7:0] counter_a,
    output reg [7:0] counter_b
);
    always @(negedge neg_clk or negedge rstn) begin
        if (!rstn) begin
            counter_a <= 8'b0;
            counter_b <= 8'b0;
        end else if (d_in) begin
            // 更新计数器状态
            counter_a <= counter_a + 1'b1;
            if (subtract_result[0])
                counter_b <= counter_b + 2'b10;
            else
                counter_b <= counter_b + 1'b1;
        end
    end
endmodule

// 减法器子模块
module subtractor (
    input wire [7:0] counter_a,
    input wire [7:0] counter_b,
    output wire [7:0] subtract_result,
    output wire borrow_out
);
    // 条件反相减法器实现
    wire [7:0] not_b;
    wire [8:0] temp_sum;

    assign not_b = ~counter_b;
    assign temp_sum = {1'b0, counter_a} + {1'b0, not_b} + 9'b000000001;
    assign {borrow_out, subtract_result} = {~temp_sum[8], temp_sum[7:0]};
endmodule