//SystemVerilog
module sparse_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8,     // Full address width
    parameter IMPLEMENTED_REGS = 16  // Only some addresses are implemented
)(
    input  wire                   clk,
    input  wire                   rst_n,
    
    // Write port
    input  wire                   write_en,
    input  wire [ADDR_WIDTH-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]  write_data,
    
    // Read port
    input  wire [ADDR_WIDTH-1:0]  read_addr,
    output reg  [DATA_WIDTH-1:0]  read_data,
    output reg                    addr_valid    // Indicates if the address is implemented
);
    // Sparse storage - only implemented registers are stored
    reg [DATA_WIDTH-1:0] sparse_regs [0:IMPLEMENTED_REGS-1];
    
    // 读地址验证逻辑
    wire [3:0] addr_low;
    wire [3:0] target_value;
    wire [4:0] borrow; // 先行借位信号
    wire low_addr_valid;
    wire high_addr_valid;
    wire [3:0] read_index;
    
    // 写地址验证逻辑
    wire [3:0] write_addr_low;
    wire [4:0] write_borrow; // 先行借位信号
    wire write_low_addr_valid;
    wire write_high_addr_valid;
    wire write_addr_valid;
    
    // 读地址验证计算 - 使用先行借位减法器
    assign addr_low = read_addr[3:0];
    assign target_value = 4'b0000; // 我们要检查是否等于0
    
    // 生成借位信号 - 先行借位减法器
    assign borrow[0] = 1'b0; // 初始无借位
    assign borrow[1] = (addr_low[0] < target_value[0]) ? 1'b1 : 1'b0;
    assign borrow[2] = (addr_low[1] < target_value[1]) ? 1'b1 : 
                       (addr_low[1] == target_value[1] && borrow[1]) ? 1'b1 : 1'b0;
    assign borrow[3] = (addr_low[2] < target_value[2]) ? 1'b1 : 
                       (addr_low[2] == target_value[2] && borrow[2]) ? 1'b1 : 1'b0;
    assign borrow[4] = (addr_low[3] < target_value[3]) ? 1'b1 : 
                       (addr_low[3] == target_value[3] && borrow[3]) ? 1'b1 : 1'b0;
    
    // 地址有效性检查 - 如果最终无借位且差值为0则地址低位有效
    wire [3:0] diff;
    assign diff[0] = addr_low[0] ^ target_value[0] ^ borrow[0];
    assign diff[1] = addr_low[1] ^ target_value[1] ^ borrow[1];
    assign diff[2] = addr_low[2] ^ target_value[2] ^ borrow[2];
    assign diff[3] = addr_low[3] ^ target_value[3] ^ borrow[3];
    
    assign low_addr_valid = (diff == 4'b0000) && (borrow[4] == 1'b0);
    assign high_addr_valid = (read_addr[ADDR_WIDTH-1:4] < IMPLEMENTED_REGS);
    assign read_index = read_addr[7:4];
    
    // 写地址验证计算 - 使用先行借位减法器
    assign write_addr_low = write_addr[3:0];
    
    // 生成写地址借位信号
    assign write_borrow[0] = 1'b0; // 初始无借位
    assign write_borrow[1] = (write_addr_low[0] < target_value[0]) ? 1'b1 : 1'b0;
    assign write_borrow[2] = (write_addr_low[1] < target_value[1]) ? 1'b1 : 
                             (write_addr_low[1] == target_value[1] && write_borrow[1]) ? 1'b1 : 1'b0;
    assign write_borrow[3] = (write_addr_low[2] < target_value[2]) ? 1'b1 : 
                             (write_addr_low[2] == target_value[2] && write_borrow[2]) ? 1'b1 : 1'b0;
    assign write_borrow[4] = (write_addr_low[3] < target_value[3]) ? 1'b1 : 
                             (write_addr_low[3] == target_value[3] && write_borrow[3]) ? 1'b1 : 1'b0;
    
    // 写地址差值计算
    wire [3:0] write_diff;
    assign write_diff[0] = write_addr_low[0] ^ target_value[0] ^ write_borrow[0];
    assign write_diff[1] = write_addr_low[1] ^ target_value[1] ^ write_borrow[1];
    assign write_diff[2] = write_addr_low[2] ^ target_value[2] ^ write_borrow[2];
    assign write_diff[3] = write_addr_low[3] ^ target_value[3] ^ write_borrow[3];
    
    // 写地址有效性检查
    assign write_low_addr_valid = (write_diff == 4'b0000) && (write_borrow[4] == 1'b0);
    assign write_high_addr_valid = (write_addr[ADDR_WIDTH-1:4] < IMPLEMENTED_REGS);
    assign write_addr_valid = write_low_addr_valid & write_high_addr_valid;
    
    // 地址有效性输出
    always @(*) begin
        addr_valid = low_addr_valid & high_addr_valid;
    end
    
    // 读数据输出
    always @(*) begin
        if (addr_valid) begin
            read_data = sparse_regs[read_index];
        end
        else begin
            read_data = {DATA_WIDTH{1'b0}};
        end
    end
    
    // 寄存器复位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integer i;
            for (i = 0; i < IMPLEMENTED_REGS; i = i + 1) begin
                sparse_regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end
    end
    
    // 寄存器写入
    always @(posedge clk) begin
        if (rst_n && write_en && write_addr_valid) begin
            sparse_regs[write_addr[7:4]] <= write_data;
        end
    end
endmodule