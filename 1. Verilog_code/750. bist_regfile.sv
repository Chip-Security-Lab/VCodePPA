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
parameter IDLE = 2'b00;
parameter WRITE_PATTERN = 2'b01;
parameter READ_VERIFY = 2'b10;
parameter REPAIR = 2'b11;

reg [DW-1:0] mem [0:(1<<AW)-1];
reg [AW:0] test_addr;
reg [DW-1:0] expected;
reg [1:0] state;
integer i;

// March C- 算法模式
localparam PATTERN0 = 16'hAAAA;
localparam PATTERN1 = 16'h5555;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        test_addr <= 0;
        error_count <= 0;
        test_done <= 1'b1;
        bist_active <= 1'b0;
        dout <= {DW{1'b0}};
        
        for (i = 0; i < (1<<AW); i = i + 1) begin
            mem[i] <= {DW{1'b0}};
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
                mem[test_addr] <= (test_addr[0]) ? PATTERN1 : PATTERN0;
                expected <= (test_addr[0]) ? PATTERN1 : PATTERN0;
                if (test_addr == (1<<AW)-1) begin
                    state <= READ_VERIFY;
                    test_addr <= 0;
                end else begin
                    test_addr <= test_addr + 1;
                end
            end
            
            READ_VERIFY: begin
                if (mem[test_addr] != ((test_addr[0]) ? PATTERN1 : PATTERN0)) begin
                    error_count <= error_count + 1;
                end
                if (test_addr == (1<<AW)-1) begin
                    state <= REPAIR;
                    test_addr <= 0;
                end else begin
                    test_addr <= test_addr + 1;
                end
            end
            
            REPAIR: begin
                mem[test_addr] <= (test_addr[0]) ? PATTERN1 : PATTERN0; // 修复错误
                if (test_addr == (1<<AW)-1) begin
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