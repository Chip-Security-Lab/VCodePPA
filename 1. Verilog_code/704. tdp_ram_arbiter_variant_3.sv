//SystemVerilog
// 先行借位减法器子模块
module carry_lookahead_subtractor #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input valid_in,
    output reg valid_out,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output reg [WIDTH-1:0] result
);

    reg [WIDTH-1:0] borrow_propagate_stage1;
    reg [WIDTH-1:0] borrow_generate_stage1;
    reg [WIDTH:0] carry_stage1;
    reg [WIDTH-1:0] a_stage1, b_stage1;
    reg valid_stage1;

    // Stage 1: 计算借位传播和生成信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 0;
            borrow_propagate_stage1 <= 0;
            borrow_generate_stage1 <= 0;
            a_stage1 <= 0;
            b_stage1 <= 0;
        end else begin
            valid_stage1 <= valid_in;
            a_stage1 <= a;
            b_stage1 <= b;
            for (int i = 0; i < WIDTH; i++) begin
                borrow_propagate_stage1[i] <= ~(a[i] ^ b[i]);
                borrow_generate_stage1[i] <= ~a[i] & b[i];
            end
        end
    end

    // Stage 2: 计算借位
    reg [WIDTH:0] carry_stage2;
    reg [WIDTH-1:0] a_stage2, b_stage2;
    reg valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 0;
            carry_stage2 <= 0;
            a_stage2 <= 0;
            b_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            carry_stage2[0] <= 1'b0;
            for (int i = 0; i < WIDTH; i++) begin
                carry_stage2[i+1] <= borrow_generate_stage1[i] | (borrow_propagate_stage1[i] & carry_stage2[i]);
            end
        end
    end

    // Stage 3: 计算最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 0;
            result <= 0;
        end else begin
            valid_out <= valid_stage2;
            for (int i = 0; i < WIDTH; i++) begin
                result[i] <= a_stage2[i] ^ b_stage2[i] ^ carry_stage2[i];
            end
        end
    end

endmodule

// 仲裁器子模块
module arbiter #(
    parameter DW = 28,
    parameter AW = 7
)(
    input clk,
    input rst_n,
    input valid_in,
    output reg valid_out,
    input arb_mode,
    input arb_flag,
    input [AW-1:0] a_addr,
    input [AW-1:0] b_addr,
    input [DW-1:0] a_din,
    input [DW-1:0] b_din,
    input a_we,
    input b_we,
    input a_re,
    input b_re,
    output reg [DW-1:0] a_dout,
    output reg [DW-1:0] b_dout,
    output reg next_arb_flag
);

    reg [DW-1:0] mem [0:(1<<AW)-1];
    reg valid_stage1;
    reg [AW-1:0] a_addr_stage1, b_addr_stage1;
    reg [DW-1:0] a_din_stage1, b_din_stage1;
    reg a_we_stage1, b_we_stage1, a_re_stage1, b_re_stage1;
    reg arb_mode_stage1, arb_flag_stage1;

    // Stage 1: 地址和数据锁存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 0;
            a_addr_stage1 <= 0;
            b_addr_stage1 <= 0;
            a_din_stage1 <= 0;
            b_din_stage1 <= 0;
            a_we_stage1 <= 0;
            b_we_stage1 <= 0;
            a_re_stage1 <= 0;
            b_re_stage1 <= 0;
            arb_mode_stage1 <= 0;
            arb_flag_stage1 <= 0;
        end else begin
            valid_stage1 <= valid_in;
            a_addr_stage1 <= a_addr;
            b_addr_stage1 <= b_addr;
            a_din_stage1 <= a_din;
            b_din_stage1 <= b_din;
            a_we_stage1 <= a_we;
            b_we_stage1 <= b_we;
            a_re_stage1 <= a_re;
            b_re_stage1 <= b_re;
            arb_mode_stage1 <= arb_mode;
            arb_flag_stage1 <= arb_flag;
        end
    end

    // Stage 2: 写操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 0;
            a_dout <= 'hz;
            b_dout <= 'hz;
            next_arb_flag <= 0;
        end else begin
            valid_out <= valid_stage1;
            if (a_we_stage1 & b_we_stage1) begin
                case(arb_mode_stage1)
                    0: begin
                        mem[a_addr_stage1] <= a_din_stage1;
                        mem[b_addr_stage1] <= a_din_stage1;
                    end
                    1: begin
                        if (arb_flag_stage1) begin
                            mem[a_addr_stage1] <= a_din_stage1;
                            next_arb_flag <= 0;
                        end else begin
                            mem[b_addr_stage1] <= b_din_stage1;
                            next_arb_flag <= 1;
                        end
                    end
                endcase
            end else begin
                if (a_we_stage1) mem[a_addr_stage1] <= a_din_stage1;
                if (b_we_stage1) mem[b_addr_stage1] <= b_din_stage1;
            end

            if (a_re_stage1 && b_re_stage1) begin
                if (arb_mode_stage1 == 0) begin
                    a_dout <= mem[a_addr_stage1];
                    b_dout <= 'hz;
                end else begin
                    if (arb_flag_stage1) begin
                        a_dout <= mem[a_addr_stage1];
                        b_dout <= 'hz;
                    end else begin
                        a_dout <= 'hz;
                        b_dout <= mem[b_addr_stage1];
                    end
                end
            end else begin
                a_dout <= a_re_stage1 ? mem[a_addr_stage1] : 'hz;
                b_dout <= b_re_stage1 ? mem[b_addr_stage1] : 'hz;
            end
        end
    end
endmodule

// 顶层模块
module tdp_ram_arbiter #(
    parameter DW = 28,
    parameter AW = 7
)(
    input clk,
    input rst_n,
    input valid_in,
    output valid_out,
    input arb_mode,
    input [AW-1:0] a_addr,
    input [DW-1:0] a_din,
    output [DW-1:0] a_dout,
    input a_we, a_re,
    input [AW-1:0] b_addr,
    input [DW-1:0] b_din,
    output [DW-1:0] b_dout,
    input b_we, b_re
);

    reg arb_flag;
    wire [7:0] sub_result;
    wire valid_sub_out;
    wire valid_arb_out;

    carry_lookahead_subtractor #(
        .WIDTH(8)
    ) subtractor (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .valid_out(valid_sub_out),
        .a(a_addr[7:0]),
        .b(b_addr[7:0]),
        .result(sub_result)
    );

    arbiter #(
        .DW(DW),
        .AW(AW)
    ) arbiter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_sub_out),
        .valid_out(valid_arb_out),
        .arb_mode(arb_mode),
        .arb_flag(arb_flag),
        .a_addr(a_addr),
        .b_addr(b_addr),
        .a_din(a_din),
        .b_din(b_din),
        .a_we(a_we),
        .b_we(b_we),
        .a_re(a_re),
        .b_re(b_re),
        .a_dout(a_dout),
        .b_dout(b_dout),
        .next_arb_flag(arb_flag)
    );

    assign valid_out = valid_arb_out;

endmodule