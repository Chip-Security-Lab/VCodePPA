//SystemVerilog
module sbox_substitution #(parameter ADDR_WIDTH = 4, DATA_WIDTH = 8) (
    input wire clk, rst,
    input wire enable,
    input wire [ADDR_WIDTH-1:0] addr_in,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    reg [DATA_WIDTH-1:0] sbox [0:(1<<ADDR_WIDTH)-1];
    wire [3:0] borrow_out;
    wire [3:0] diff;
    reg [ADDR_WIDTH-1:0] addr_in_reg;
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg enable_reg;
    reg [DATA_WIDTH-1:0] sbox_value;
    
    // 借位减法器实例
    borrow_subtractor bsub_inst (
        .a(addr_in_reg),
        .b(data_in_reg[3:0]),
        .bin(1'b0),
        .diff(diff),
        .bout(borrow_out[3])
    );
    
    // 寄存输入信号
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_in_reg <= 0;
            data_in_reg <= 0;
            enable_reg <= 0;
        end
        else begin
            addr_in_reg <= addr_in;
            data_in_reg <= data_in;
            enable_reg <= enable;
        end
    end
    
    // 寄存SBOX输出
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sbox_value <= 0;
        end
        else if (enable_reg) begin
            sbox_value <= sbox[addr_in_reg];
        end
    end
    
    // 输出逻辑 - 最终XOR计算
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 0;
        end
        else begin
            data_out <= {data_in_reg[DATA_WIDTH-1:4], diff} ^ sbox_value;
        end
    end
endmodule

// 借位减法器模块实现
module borrow_subtractor (
    input [3:0] a,        // 被减数
    input [3:0] b,        // 减数
    input bin,            // 输入借位
    output reg [3:0] diff, // 差
    output reg bout       // 输出借位
);
    wire [4:0] borrow;    // 内部借位信号
    wire [3:0] temp_diff;
    
    assign borrow[0] = bin;
    
    // 实现4位借位减法器
    assign temp_diff[0] = a[0] ^ b[0] ^ borrow[0];
    assign borrow[1] = (~a[0] & b[0]) | (~(a[0] ^ b[0]) & borrow[0]);
    
    assign temp_diff[1] = a[1] ^ b[1] ^ borrow[1];
    assign borrow[2] = (~a[1] & b[1]) | (~(a[1] ^ b[1]) & borrow[1]);
    
    assign temp_diff[2] = a[2] ^ b[2] ^ borrow[2];
    assign borrow[3] = (~a[2] & b[2]) | (~(a[2] ^ b[2]) & borrow[2]);
    
    assign temp_diff[3] = a[3] ^ b[3] ^ borrow[3];
    assign borrow[4] = (~a[3] & b[3]) | (~(a[3] ^ b[3]) & borrow[3]);
    
    // 寄存输出结果
    always @(*) begin
        diff = temp_diff;
        bout = borrow[4];
    end
endmodule