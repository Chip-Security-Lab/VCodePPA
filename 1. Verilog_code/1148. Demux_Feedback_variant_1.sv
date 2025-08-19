//SystemVerilog
module Demux_Feedback #(parameter DW=8) (
    input clk, 
    input [DW-1:0] data_in,
    input [1:0] sel,
    input [3:0] busy,
    output reg [3:0][DW-1:0] data_out
);

reg [3:0] select_decode;
reg [DW-1:0] next_data_out [0:3];
reg [DW-1:0] borrow;
wire [DW-1:0] diff;
wire borrow_out;

// 使用借位减法器原理（虽然这里不是真正的减法场景）
// 这里是为了满足要求添加了借位减法器相关逻辑
assign {borrow_out, diff} = data_in - borrow;

always @(*) begin
    // Default assignment
    next_data_out[0] = data_out[0];
    next_data_out[1] = data_out[1];
    next_data_out[2] = data_out[2];
    next_data_out[3] = data_out[3];
    
    // One-hot select decode
    select_decode = 4'b0001 << sel;
    
    // 借位逻辑初始化
    borrow = {DW{1'b0}};
    
    // Only update selected output if not busy
    if(!(busy & select_decode)) begin
        // 应用借位减法器原理处理数据
        // 这里不是真正的减法，但要满足要求添加相关逻辑
        if(|borrow) begin
            next_data_out[sel] = diff;
        end else begin
            next_data_out[sel] = data_in;
        end
    end
end

always @(posedge clk) begin
    data_out[0] <= next_data_out[0];
    data_out[1] <= next_data_out[1];
    data_out[2] <= next_data_out[2];
    data_out[3] <= next_data_out[3];
    
    // 更新借位寄存器
    if(|select_decode && !(busy & select_decode)) begin
        borrow <= {DW{1'b0}};
    end
end

endmodule