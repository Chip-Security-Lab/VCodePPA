//SystemVerilog
module Demux_Parity #(parameter DW=9) (
    input [DW-2:0] data_in,
    input [2:0] addr,
    output reg [7:0][DW-1:0] data_out
);
    wire parity;
    wire [7:0] decoded_addr;
    
    // Calculate parity
    assign parity = ^data_in;
    
    // Use address decoder with borrow subtractor
    Addr_Decoder addr_decoder (
        .addr(addr),
        .decoded_addr(decoded_addr)
    );
    
    // 将大的always块分解为8个小的always块，每个处理一个输出
    always @(*) begin
        data_out[0] = decoded_addr[0] ? {parity, data_in} : {DW{1'b0}};
    end
    
    always @(*) begin
        data_out[1] = decoded_addr[1] ? {parity, data_in} : {DW{1'b0}};
    end
    
    always @(*) begin
        data_out[2] = decoded_addr[2] ? {parity, data_in} : {DW{1'b0}};
    end
    
    always @(*) begin
        data_out[3] = decoded_addr[3] ? {parity, data_in} : {DW{1'b0}};
    end
    
    always @(*) begin
        data_out[4] = decoded_addr[4] ? {parity, data_in} : {DW{1'b0}};
    end
    
    always @(*) begin
        data_out[5] = decoded_addr[5] ? {parity, data_in} : {DW{1'b0}};
    end
    
    always @(*) begin
        data_out[6] = decoded_addr[6] ? {parity, data_in} : {DW{1'b0}};
    end
    
    always @(*) begin
        data_out[7] = decoded_addr[7] ? {parity, data_in} : {DW{1'b0}};
    end
endmodule

module Addr_Decoder (
    input [2:0] addr,
    output [7:0] decoded_addr
);
    wire [2:0] addr_complement;
    wire [7:0] borrow;
    wire [7:0][2:0] result;
    
    // 计算补码用于借位算法
    assign addr_complement = ~addr;
    
    // 将减法器实例化拆分为独立单元，提高并行性
    BorrowSubtractor sub0(
        .a(3'b000),
        .b(addr),
        .bin(1'b0),
        .diff(result[0]),
        .bout(borrow[0])
    );
    
    BorrowSubtractor sub1(
        .a(3'b001),
        .b(addr),
        .bin(1'b0),
        .diff(result[1]),
        .bout(borrow[1])
    );
    
    BorrowSubtractor sub2(
        .a(3'b010),
        .b(addr),
        .bin(1'b0),
        .diff(result[2]),
        .bout(borrow[2])
    );
    
    BorrowSubtractor sub3(
        .a(3'b011),
        .b(addr),
        .bin(1'b0),
        .diff(result[3]),
        .bout(borrow[3])
    );
    
    BorrowSubtractor sub4(
        .a(3'b100),
        .b(addr),
        .bin(1'b0),
        .diff(result[4]),
        .bout(borrow[4])
    );
    
    BorrowSubtractor sub5(
        .a(3'b101),
        .b(addr),
        .bin(1'b0),
        .diff(result[5]),
        .bout(borrow[5])
    );
    
    BorrowSubtractor sub6(
        .a(3'b110),
        .b(addr),
        .bin(1'b0),
        .diff(result[6]),
        .bout(borrow[6])
    );
    
    BorrowSubtractor sub7(
        .a(3'b111),
        .b(addr),
        .bin(1'b0),
        .diff(result[7]),
        .bout(borrow[7])
    );
    
    // 将比较逻辑分解为多个小的assign语句，提高可读性
    assign decoded_addr[0] = (result[0] == 3'b000) && (borrow[0] == 1'b0);
    assign decoded_addr[1] = (result[1] == 3'b000) && (borrow[1] == 1'b0);
    assign decoded_addr[2] = (result[2] == 3'b000) && (borrow[2] == 1'b0);
    assign decoded_addr[3] = (result[3] == 3'b000) && (borrow[3] == 1'b0);
    assign decoded_addr[4] = (result[4] == 3'b000) && (borrow[4] == 1'b0);
    assign decoded_addr[5] = (result[5] == 3'b000) && (borrow[5] == 1'b0);
    assign decoded_addr[6] = (result[6] == 3'b000) && (borrow[6] == 1'b0);
    assign decoded_addr[7] = (result[7] == 3'b000) && (borrow[7] == 1'b0);
endmodule

module BorrowSubtractor (
    input [2:0] a,
    input [2:0] b,
    input bin,        // 借位输入
    output [2:0] diff, // 差值
    output bout        // 借位输出
);
    wire [3:0] borrow; // 内部借位信号
    
    // 初始借位
    assign borrow[0] = bin;
    
    // 分解位级别的借位减法，提高可读性和可维护性
    // 位0借位减法
    assign diff[0] = a[0] ^ b[0] ^ borrow[0];
    assign borrow[1] = (~a[0] & b[0]) | (borrow[0] & ~(a[0] ^ b[0]));
    
    // 位1借位减法
    assign diff[1] = a[1] ^ b[1] ^ borrow[1];
    assign borrow[2] = (~a[1] & b[1]) | (borrow[1] & ~(a[1] ^ b[1]));
    
    // 位2借位减法
    assign diff[2] = a[2] ^ b[2] ^ borrow[2];
    assign borrow[3] = (~a[2] & b[2]) | (borrow[2] & ~(a[2] ^ b[2]));
    
    // 最终借位输出
    assign bout = borrow[3];
endmodule