//SystemVerilog
module sync_dual_port_ram_with_reset_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // 流水线寄存器 - 地址阶段
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg we_a_stage1, we_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg en_stage1;
    
    // 流水线寄存器 - 地址译码阶段
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg we_a_stage2, we_b_stage2;
    reg [DATA_WIDTH-1:0] din_a_stage2, din_b_stage2;
    reg en_stage2;
    
    // 流水线寄存器 - 读数据阶段
    reg [ADDR_WIDTH-1:0] addr_a_stage3, addr_b_stage3;
    reg we_a_stage3, we_b_stage3;
    reg [DATA_WIDTH-1:0] din_a_stage3, din_b_stage3;
    reg en_stage3;
    reg [DATA_WIDTH-1:0] read_data_a_stage3, read_data_b_stage3;
    
    // 流水线寄存器 - 写数据阶段
    reg [ADDR_WIDTH-1:0] addr_a_stage4, addr_b_stage4;
    reg we_a_stage4, we_b_stage4;
    reg [DATA_WIDTH-1:0] din_a_stage4, din_b_stage4;
    reg en_stage4;
    reg [DATA_WIDTH-1:0] read_data_a_stage4, read_data_b_stage4;
    
    // 第一阶段: 输入锁存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
            en_stage1 <= 0;
        end else begin
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
            en_stage1 <= en;
        end
    end
    
    // 第二阶段: 地址译码
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage2 <= 0;
            addr_b_stage2 <= 0;
            we_a_stage2 <= 0;
            we_b_stage2 <= 0;
            din_a_stage2 <= 0;
            din_b_stage2 <= 0;
            en_stage2 <= 0;
        end else begin
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            we_a_stage2 <= we_a_stage1;
            we_b_stage2 <= we_b_stage1;
            din_a_stage2 <= din_a_stage1;
            din_b_stage2 <= din_b_stage1;
            en_stage2 <= en_stage1;
        end
    end
    
    // 第三阶段: 读数据获取
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage3 <= 0;
            addr_b_stage3 <= 0;
            we_a_stage3 <= 0;
            we_b_stage3 <= 0;
            din_a_stage3 <= 0;
            din_b_stage3 <= 0;
            en_stage3 <= 0;
            read_data_a_stage3 <= 0;
            read_data_b_stage3 <= 0;
        end else begin
            addr_a_stage3 <= addr_a_stage2;
            addr_b_stage3 <= addr_b_stage2;
            we_a_stage3 <= we_a_stage2;
            we_b_stage3 <= we_b_stage2;
            din_a_stage3 <= din_a_stage2;
            din_b_stage3 <= din_b_stage2;
            en_stage3 <= en_stage2;
            
            read_data_a_stage3 <= ram[addr_a_stage2];
            read_data_b_stage3 <= ram[addr_b_stage2];
        end
    end
    
    // 第四阶段: 写操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage4 <= 0;
            addr_b_stage4 <= 0;
            we_a_stage4 <= 0;
            we_b_stage4 <= 0;
            din_a_stage4 <= 0;
            din_b_stage4 <= 0;
            en_stage4 <= 0;
            read_data_a_stage4 <= 0;
            read_data_b_stage4 <= 0;
        end else begin
            addr_a_stage4 <= addr_a_stage3;
            addr_b_stage4 <= addr_b_stage3;
            we_a_stage4 <= we_a_stage3;
            we_b_stage4 <= we_b_stage3;
            din_a_stage4 <= din_a_stage3;
            din_b_stage4 <= din_b_stage3;
            en_stage4 <= en_stage3;
            read_data_a_stage4 <= read_data_a_stage3;
            read_data_b_stage4 <= read_data_b_stage3;
            
            if (en_stage3) begin
                if (we_a_stage3) ram[addr_a_stage3] <= din_a_stage3;
                if (we_b_stage3) ram[addr_b_stage3] <= din_b_stage3;
            end
        end
    end
    
    // 第五阶段: 输出数据锁存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else if (en_stage4) begin
            dout_a <= read_data_a_stage4;
            dout_b <= read_data_b_stage4;
        end
    end
endmodule