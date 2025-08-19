//SystemVerilog
module dram_ctrl_ecc #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH = 8
)(
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] data_in,
    input data_valid,
    output [DATA_WIDTH-1:0] data_out,
    output [ECC_WIDTH-1:0] ecc_syndrome,
    output data_ready
);

    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    wire ready_stage1, ready_stage2, ready_stage3;
    
    // 流水线寄存器
    reg [DATA_WIDTH-1:0] data_stage1, data_stage2, data_stage3;
    reg [ECC_WIDTH-1:0] ecc_stage1, ecc_stage2, ecc_stage3;
    
    // ECC生成逻辑
    function [ECC_WIDTH-1:0] calculate_ecc;
        input [DATA_WIDTH-1:0] data;
        reg [ECC_WIDTH-1:0] ecc_temp;
        begin
            ecc_temp = ^(data & 64'hFF00FF00FF00FF00);
            calculate_ecc = ecc_temp;
        end
    endfunction
    
    // 流水线控制逻辑
    assign ready_stage1 = ~valid_stage2 || ready_stage2;
    assign ready_stage2 = ~valid_stage3 || ready_stage3;
    assign ready_stage3 = 1'b1;
    assign data_ready = ready_stage1;
    
    // 流水线级1: 数据输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            data_stage1 <= {DATA_WIDTH{1'b0}};
        end else if (ready_stage1) begin
            valid_stage1 <= data_valid;
            data_stage1 <= data_in;
        end
    end
    
    // 流水线级2: ECC计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            data_stage2 <= {DATA_WIDTH{1'b0}};
            ecc_stage2 <= {ECC_WIDTH{1'b0}};
        end else if (ready_stage2) begin
            valid_stage2 <= valid_stage1;
            data_stage2 <= data_stage1;
            ecc_stage2 <= calculate_ecc(data_stage1);
        end
    end
    
    // 流水线级3: 错误检测和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
            data_stage3 <= {DATA_WIDTH{1'b0}};
            ecc_stage3 <= {ECC_WIDTH{1'b0}};
        end else if (ready_stage3) begin
            valid_stage3 <= valid_stage2;
            data_stage3 <= data_stage2;
            ecc_stage3 <= ecc_stage2;
        end
    end
    
    // 输出逻辑
    assign data_out = data_stage3;
    assign ecc_syndrome = ecc_stage3 ^ calculate_ecc(data_stage3);
    
endmodule