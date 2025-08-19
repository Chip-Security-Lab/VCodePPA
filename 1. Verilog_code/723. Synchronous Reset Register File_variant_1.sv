//SystemVerilog
module sync_reset_regfile #(
    parameter WIDTH = 32,
    parameter DEPTH = 32,
    parameter ADDR_BITS = $clog2(DEPTH)
)(
    input  wire                   clk,
    input  wire                   sync_reset,   // Synchronous reset
    input  wire                   write_enable,
    input  wire [ADDR_BITS-1:0]   write_addr,
    input  wire [WIDTH-1:0]       write_data,
    input  wire [ADDR_BITS-1:0]   read_addr,
    output wire [WIDTH-1:0]       read_data
);
    // Memory storage
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    
    // 寄存器复位状态控制信号
    reg reset_in_progress;
    reg [ADDR_BITS-1:0] reset_counter;
    
    // 读操作（组合逻辑）
    assign read_data = memory[read_addr];
    
    // 合并后的控制逻辑 - 包含复位控制、渐进式复位和写操作
    always @(posedge clk) begin
        if (sync_reset) begin
            // 复位初始化
            reset_in_progress <= 1'b1;
            reset_counter <= {ADDR_BITS{1'b0}};
            memory[{ADDR_BITS{1'b0}}] <= {WIDTH{1'b0}};
        end
        else if (reset_in_progress) begin
            // 渐进式复位过程
            memory[reset_counter] <= {WIDTH{1'b0}};
            
            if (reset_counter == DEPTH-1) begin
                reset_in_progress <= 1'b0;
            end
            else begin
                reset_counter <= reset_counter + 1'b1;
            end
        end
        else if (write_enable) begin
            // 正常写操作
            memory[write_addr] <= write_data;
        end
    end
endmodule