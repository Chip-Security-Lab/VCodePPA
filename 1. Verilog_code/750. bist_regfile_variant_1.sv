//SystemVerilog
module bist_regfile #(
    parameter DW = 16,
    parameter AW = 4
)(
    input clk,
    input rst_n,
    input start_test,      // 启动自检
    input normal_wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg test_done,
    output reg [7:0] error_count,
    output reg bist_active
);
    // BIST状态机定义
    localparam IDLE = 2'b00;
    localparam WRITE_PATTERN = 2'b01;
    localparam READ_VERIFY = 2'b10;
    localparam REPAIR = 2'b11;

    // March C- 算法模式
    localparam PATTERN0 = 16'hAAAA;
    localparam PATTERN1 = 16'h5555;

    reg [DW-1:0] mem [0:(1<<AW)-1];
    reg [AW:0] test_addr;
    reg [DW-1:0] expected;
    reg [1:0] state;
    integer i;
    
    wire [DW-1:0] pattern_data;
    wire addr_max_reached;

    // 提取的可复用计算逻辑
    pattern_generator #(
        .DW(DW)
    ) pattern_gen (
        .addr(test_addr),
        .pattern0(PATTERN0),
        .pattern1(PATTERN1),
        .pattern_out(pattern_data)
    );
    
    // 地址边界检测逻辑
    addr_boundary_check #(
        .AW(AW)
    ) addr_check (
        .addr(test_addr),
        .max_reached(addr_max_reached)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_addr <= 0;
            error_count <= 0;
            test_done <= 1'b1;
            bist_active <= 1'b0;
            dout <= {DW{1'b0}};
            
            i = 0;
            while (i < (1<<AW)) begin
                mem[i] <= {DW{1'b0}};
                i = i + 1;
            end
        end else begin
            case(state)
                IDLE: begin
                    test_done <= 1'b1;
                    bist_active <= 1'b0;
                    
                    if (normal_wr_en) begin
                        mem[addr] <= din;
                    end
                    
                    dout <= mem[addr];
                    
                    if (start_test) begin
                        state <= WRITE_PATTERN;
                        test_addr <= 0;
                        test_done <= 1'b0;
                        bist_active <= 1'b1;
                    end
                end
                
                WRITE_PATTERN: begin
                    mem[test_addr] <= pattern_data;
                    expected <= pattern_data;
                    
                    if (addr_max_reached) begin
                        state <= READ_VERIFY;
                        test_addr <= 0;
                    end else begin
                        test_addr <= test_addr + 1;
                    end
                end
                
                READ_VERIFY: begin
                    if (mem[test_addr] != pattern_data) begin
                        error_count <= error_count + 1;
                    end
                    
                    if (addr_max_reached) begin
                        state <= REPAIR;
                        test_addr <= 0;
                    end else begin
                        test_addr <= test_addr + 1;
                    end
                end
                
                REPAIR: begin
                    mem[test_addr] <= pattern_data; // 修复错误
                    
                    if (addr_max_reached) begin
                        state <= IDLE;
                    end else begin
                        test_addr <= test_addr + 1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule

// 根据地址生成测试模式的模块
module pattern_generator #(
    parameter DW = 16
)(
    input [AW:0] addr,
    input [DW-1:0] pattern0,
    input [DW-1:0] pattern1,
    output [DW-1:0] pattern_out
);
    parameter AW = $clog2(DW);
    
    assign pattern_out = (addr[0]) ? pattern1 : pattern0;
endmodule

// 地址边界检测模块
module addr_boundary_check #(
    parameter AW = 4
)(
    input [AW:0] addr,
    output max_reached
);
    assign max_reached = (addr == (1<<AW)-1);
endmodule