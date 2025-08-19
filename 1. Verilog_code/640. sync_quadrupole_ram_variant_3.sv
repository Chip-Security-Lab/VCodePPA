//SystemVerilog
module sync_quadrupole_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b, we_c, we_d,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, addr_c, addr_d,
    input wire [DATA_WIDTH-1:0] din_a, din_b, din_c, din_d,
    input wire sub_en,
    input wire [ADDR_WIDTH-1:0] sub_addr_a, sub_addr_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b, dout_c, dout_d,
    output reg [DATA_WIDTH-1:0] sub_result
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_buf_a, ram_buf_b;
    reg [DATA_WIDTH-1:0] sub_a, sub_b;
    reg [DATA_WIDTH-1:0] sub_diff;
    reg sub_carry;
    reg [DATA_WIDTH-1:0] sub_result_next;
    reg [DATA_WIDTH-1:0] sub_diff_buf;
    reg sub_carry_buf;

    // RAM读取缓冲
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_buf_a <= 0;
            ram_buf_b <= 0;
        end else begin
            ram_buf_a <= ram[sub_addr_a];
            ram_buf_b <= ram[sub_addr_b];
        end
    end

    // 减法操作数缓冲
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sub_a <= 0;
            sub_b <= 0;
        end else begin
            sub_a <= ram_buf_a;
            sub_b <= ram_buf_b;
        end
    end

    // 优化的条件求和减法算法实现
    always @(*) begin
        // 初始化
        sub_diff = 0;
        sub_carry = 0;
        
        // 优化的条件求和减法算法
        for (integer i = 0; i < DATA_WIDTH; i = i + 1) begin
            // 使用位运算优化比较逻辑
            case ({sub_a[i], sub_b[i], sub_carry})
                3'b100: begin // 1-0-0
                    sub_diff[i] = 1'b1;
                end
                3'b010: begin // 0-1-0
                    sub_diff[i] = 1'b1;
                    sub_carry = 1'b1;
                end
                3'b011: begin // 0-1-1
                    sub_diff[i] = 1'b0;
                end
                3'b110: begin // 1-1-0
                    sub_diff[i] = 1'b0;
                end
                3'b111: begin // 1-1-1
                    sub_diff[i] = 1'b1;
                end
                3'b000: begin // 0-0-0
                    sub_diff[i] = 1'b0;
                end
                3'b001: begin // 0-0-1
                    sub_diff[i] = 1'b1;
                    sub_carry = 1'b0;
                end
                default: begin
                    sub_diff[i] = 1'b0;
                end
            endcase
        end
        
        sub_result_next = sub_diff;
    end

    // 减法结果缓冲
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sub_diff_buf <= 0;
            sub_carry_buf <= 0;
        end else begin
            sub_diff_buf <= sub_diff;
            sub_carry_buf <= sub_carry;
        end
    end

    // 主时序逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
            dout_c <= 0;
            dout_d <= 0;
            sub_result <= 0;
        end else begin
            if (we_a) ram[addr_a] <= din_a;
            if (we_b) ram[addr_b] <= din_b;
            if (we_c) ram[addr_c] <= din_c;
            if (we_d) ram[addr_d] <= din_d;

            dout_a <= ram[addr_a];
            dout_b <= ram[addr_b];
            dout_c <= ram[addr_c];
            dout_d <= ram[addr_d];
            
            if (sub_en) begin
                sub_result <= sub_diff_buf;
            end
        end
    end
endmodule