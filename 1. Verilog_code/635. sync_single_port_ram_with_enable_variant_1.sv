//SystemVerilog
module sync_single_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    // RAM存储单元
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // 流水线寄存器
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] din_stage1;
    reg we_stage1;
    reg en_stage1;
    
    reg [ADDR_WIDTH-1:0] addr_stage2;
    reg [DATA_WIDTH-1:0] din_stage2;
    reg we_stage2;
    reg en_stage2;
    
    // 并行前缀减法器相关信号
    wire [DATA_WIDTH-1:0] addr_comp_stage1;
    wire [DATA_WIDTH-1:0] addr_comp_plus_one_stage1;
    wire [DATA_WIDTH-1:0] addr_comp_plus_two_stage1;
    wire [DATA_WIDTH-1:0] addr_comp_plus_three_stage1;
    wire [DATA_WIDTH-1:0] addr_comp_plus_four_stage1;
    wire [DATA_WIDTH-1:0] addr_comp_plus_five_stage1;
    wire [DATA_WIDTH-1:0] addr_comp_plus_six_stage1;
    wire [DATA_WIDTH-1:0] addr_comp_plus_seven_stage1;
    
    // 并行前缀减法器实现 - Stage 1
    assign addr_comp_stage1 = ~addr_stage1 + 1'b1;
    assign addr_comp_plus_one_stage1 = addr_comp_stage1 + 1'b1;
    assign addr_comp_plus_two_stage1 = addr_comp_stage1 + 2'b10;
    assign addr_comp_plus_three_stage1 = addr_comp_stage1 + 2'b11;
    assign addr_comp_plus_four_stage1 = addr_comp_stage1 + 3'b100;
    assign addr_comp_plus_five_stage1 = addr_comp_stage1 + 3'b101;
    assign addr_comp_plus_six_stage1 = addr_comp_stage1 + 3'b110;
    assign addr_comp_plus_seven_stage1 = addr_comp_stage1 + 3'b111;
    
    // 并行前缀减法器结果选择逻辑 - Stage 2
    wire [DATA_WIDTH-1:0] parallel_result_stage2;
    assign parallel_result_stage2 = (addr_comp_stage1[0]) ? ram[addr_stage1] :
                                  (addr_comp_plus_one_stage1[0]) ? ram[addr_comp_plus_one_stage1] :
                                  (addr_comp_plus_two_stage1[0]) ? ram[addr_comp_plus_two_stage1] :
                                  (addr_comp_plus_three_stage1[0]) ? ram[addr_comp_plus_three_stage1] :
                                  (addr_comp_plus_four_stage1[0]) ? ram[addr_comp_plus_four_stage1] :
                                  (addr_comp_plus_five_stage1[0]) ? ram[addr_comp_plus_five_stage1] :
                                  (addr_comp_plus_six_stage1[0]) ? ram[addr_comp_plus_six_stage1] :
                                  ram[addr_comp_plus_seven_stage1];
    
    // Stage 1: 输入寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_stage1 <= 0;
            din_stage1 <= 0;
            we_stage1 <= 0;
            en_stage1 <= 0;
        end else begin
            addr_stage1 <= addr;
            din_stage1 <= din;
            we_stage1 <= we;
            en_stage1 <= en;
        end
    end
    
    // Stage 2: 写操作和输出寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (en_stage1) begin
            if (we_stage1) begin
                ram[addr_stage1] <= din_stage1;
            end
            dout <= parallel_result_stage2;
        end
    end
endmodule