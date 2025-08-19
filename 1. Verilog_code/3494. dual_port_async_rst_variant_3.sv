//SystemVerilog
module dual_port_async_rst #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     wr_en,
    input  wire [ADDR_WIDTH-1:0]    addr_wr, 
    input  wire [ADDR_WIDTH-1:0]    addr_rd,
    input  wire [DATA_WIDTH-1:0]    din,
    output reg  [DATA_WIDTH-1:0]    dout,
    // 减法器的输入和输出端口
    input  wire [3:0]               minuend, 
    input  wire [3:0]               subtrahend,
    output wire [3:0]               difference,
    output wire                     borrow_out
);

    // 存储器定义
    reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
    
    // 减法器中间信号
    wire [3:0] not_subtrahend;
    wire [4:0] carry;
    wire [3:0] generate_bits;
    wire [3:0] propagate_bits;

    //--------------------------------------------------
    // 减法器实现部分
    //--------------------------------------------------
    
    // 步骤1: 对被减数进行反相
    assign not_subtrahend = ~subtrahend;
    
    // 步骤2: 初始进位设为1
    assign carry[0] = 1'b1;

    // 生成生成位和传播位
    assign generate_bits = minuend & not_subtrahend;
    assign propagate_bits = minuend | not_subtrahend;

    // 曼彻斯特进位链实现
    assign carry[1] = generate_bits[0] | (propagate_bits[0] & carry[0]);
    
    assign carry[2] = generate_bits[1] | 
                     (propagate_bits[1] & generate_bits[0]) | 
                     (propagate_bits[1] & propagate_bits[0] & carry[0]);
    
    assign carry[3] = generate_bits[2] | 
                     (propagate_bits[2] & generate_bits[1]) | 
                     (propagate_bits[2] & propagate_bits[1] & generate_bits[0]) |
                     (propagate_bits[2] & propagate_bits[1] & propagate_bits[0] & carry[0]);
    
    assign carry[4] = generate_bits[3] | 
                     (propagate_bits[3] & generate_bits[2]) | 
                     (propagate_bits[3] & propagate_bits[2] & generate_bits[1]) |
                     (propagate_bits[3] & propagate_bits[2] & propagate_bits[1] & generate_bits[0]) |
                     (propagate_bits[3] & propagate_bits[2] & propagate_bits[1] & propagate_bits[0] & carry[0]);

    // 计算差值和借位
    assign difference = minuend ^ not_subtrahend ^ {carry[3:0]};
    assign borrow_out = ~carry[4];

    //--------------------------------------------------
    // 存储器写入控制
    //--------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 不需要在复位时清空存储器
        end
        else if (wr_en) begin
            mem[addr_wr] <= din;
        end
    end

    //--------------------------------------------------
    // 存储器读取控制
    //--------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= {DATA_WIDTH{1'b0}};
        end
        else begin
            dout <= mem[addr_rd];
        end
    end

endmodule